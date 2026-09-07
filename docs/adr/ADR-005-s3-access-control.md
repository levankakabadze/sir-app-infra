# ADR-005: S3 Bucket Access Control Strategy

## Status
Accepted

## Date
2026-09-07

## Author
Levan Kakabadze

## Context

The SIR application requires an S3 bucket to store incident photo
attachments uploaded by plant workers. Access to this bucket must
be tightly controlled - only the EC2 application server should be
able to read and write objects. No other identity, service, or
internet source should have access. 

Two mechanisms exist in AWS for controlling S3 bucket access:

**Option 1 — IAM policy only (attached to EC2 role):**
An IAM role is attached to the EC2 instance. A policy on that role
grants permission to perform S3 operations on the bucket. The rule
lives on the identity — the EC2 role carries its permissions
wherever it goes. However, this approach only controls what the
EC2 instance is allowed to do — it does not restrict who else
can access the bucket. Other identities with S3 permissions in 
the same AWS account could potentially access the bucket if not
explicitly denied. 

**Option 2 — Bucket policy only (attached to S3 bucket):**
A resource-based policy is attached directly to the S3 bucket.
The policy defines which identities are permitted to access the
bucket. The rule lives on the resource — the bucket controls its
own access. However, the EC2 instance still needs an IAM rule to
assume an identity that the bucket policy can reference.

**Option 3 — Both IAM policy and bucket policy (defense in depth):**
The EC2 role has an IAM policy granting S3 access, AND the bucket 
has a policy restricting access to that specific role only. Both 
controls must be satisfied for access to succeed. This creates 
two independent layers of access control — the identity must be 
permitted AND the resource must permit that identity.

For a bucket storing sensitive plant safety incident photos, 
relying on a single control mechanism introduces risk. If the IAM 
policy is misconfigured to be too permissive, the bucket policy 
acts as a safety net. If the bucket policy is misconfigured, the 
IAM policy limits what the identity can do.

## Decision

We implement both an IAM policy on the EC2 role AND a bucket 
policy on the S3 bucket — defense in depth at the access 
control layer.

**S3 Bucket configuration:**
- Versioning enabled — protects against accidental deletion of 
  incident photo attachments
- Server-side encryption (AES256) — encrypts all objects at rest
- Block all public access — four settings enabled, no exceptions
- No public bucket policy or ACLs permitted

**IAM policy on EC2 role:**
- Grants `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` 
  on the specific bucket ARN only
- Grants `s3:ListBucket` on the bucket ARN for directory 
  operations
- Scoped to the exact bucket — not `s3:*` on `*`
- Attached to the EC2 instance profile — the application server 
  assumes this role automatically at launch

**Bucket policy:**
- Explicit `Allow` for the EC2 IAM role ARN only
- Explicit `Deny` for any request where 
  `aws:SecureTransport = false` — enforces HTTPS only, 
  blocks unencrypted connections
- All other identities implicitly denied

**The access control chain:**
```
Plant worker uploads photo via browser
        ↓
EC2 application server receives the upload
        ↓
EC2 assumes IAM role → IAM policy permits S3 access
        ↓
Request reaches S3 bucket → bucket policy validates role ARN
        ↓
Both controls satisfied → object written to bucket
```

## Consequences

### Benefits
- **Defense in depth** — two independent access control layers. 
  A misconfiguration in either the IAM policy or bucket policy 
  alone cannot expose the bucket. Both must fail simultaneously 
  for unauthorized access to occur
- **Least privilege** — the IAM policy grants only the four S3 
  actions the application needs. No wildcard actions, no access 
  to other buckets. The bucket policy permits only one identity — 
  the EC2 role
- **Encryption at rest** — AES256 server-side encryption protects 
  incident photo data stored in S3 without application-level 
  changes
- **HTTPS enforcement** — the bucket policy denies unencrypted 
  connections via `aws:SecureTransport = false` condition. Photo 
  data cannot be transmitted in plaintext between the application 
  and S3
- **Versioning** — accidental deletion or overwrite of incident 
  photos can be recovered from previous versions. Important for 
  plant safety data that may be required for incident 
  investigations
- **Public access blocked** — all four public access block 
  settings are enabled. The bucket cannot be made public 
  accidentally through misconfigured bucket policies or ACLs

### Trade-offs
- **Increased IAM complexity** — maintaining both an IAM policy 
  and a bucket policy means two places to update when access 
  requirements change. Both must be kept in sync
- **EC2 role dependency** — the bucket policy references the 
  specific EC2 IAM role ARN. If the role is recreated by 
  Terraform and gets a new ARN, the bucket policy must be 
  updated. This is handled automatically by Terraform resource 
  references but requires care during manual operations
- **No direct developer access** — developers cannot access 
  incident photos directly from their workstations via AWS CLI 
  or console. Access requires going through the application or 
  assuming the EC2 role explicitly — which requires additional 
  IAM permissions not granted in this design
- **Versioning storage cost** — enabling versioning means deleted 
  or overwritten objects are retained. For a lab environment with 
  minimal objects this cost is negligible. Production must 
  implement lifecycle policies to expire old versions after a 
  defined retention period