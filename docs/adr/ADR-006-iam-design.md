# ADR-006: IAM Design — Least Privilege Identity Architecture

## Status
Accepted

## Date
2026-09-07

## Author
Levan Kakabadze

## Context

The SIR application infrastructure requires three distinct IAM 
identities with different access requirements:

**EC2 Application Server:**
The EC2 instance needs to read and write incident photo attachments 
to S3. Two approaches exist for providing AWS credentials to EC2:

- **Static credentials** — create an IAM user, generate an access 
  key and secret key, store them on the EC2 instance as environment 
  variables or in a credentials file
- **IAM role via instance profile** — attach an IAM role to the 
  EC2 instance. AWS automatically provides temporary credentials 
  that rotate every few hours with no human intervention

Static credentials stored on EC2 are a security risk. If the 
instance is compromised, an attacker obtains long-lived credentials 
that remain valid until manually rotated. They can also be 
accidentally committed to Git, baked into AMIs, or exposed in 
logs. Temporary role credentials expire automatically and are 
never stored in a location accessible outside the instance metadata 
service.

**Developer access:**
A developer needs visibility into the deployed infrastructure — 
read-only access to verify resources exist, check configurations, 
and monitor costs. They do not need the ability to create, modify, 
or destroy resources.

**CI/CD pipeline access:**
An automated pipeline needs to deploy infrastructure changes — 
create, update, and destroy resources within the scope of this 
project. It does not need read access to sensitive data or 
permissions outside the project scope.

Sharing one IAM identity between the developer and CI/CD pipeline 
would require granting both sets of permissions to a single user. 
This violates least privilege — the developer would have deploy 
permissions they do not need, and the pipeline would have data 
access it does not need. A compromise of either credential set 
would expose both capability sets.

## Decision

We create three separate IAM identities, each with the minimum 
permissions required for their specific function.

**Identity 1 — EC2 Instance Role (`sir-app-dev-ec2-role`):**
- IAM role attached to EC2 via instance profile
- Temporary credentials provided automatically by AWS — no 
  static keys
- Permissions scoped to S3 operations on the specific assets 
  bucket only:
  - `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on bucket 
    objects
  - `s3:ListBucket` on the bucket itself
- No other permissions — cannot access RDS, cannot modify 
  infrastructure, cannot access other S3 buckets

**Identity 2 — Developer User (`sir-app-developer`):**
- IAM user with read-only managed policy
- Can describe and list infrastructure resources
- Cannot create, modify, or destroy any resource
- Cannot access S3 bucket contents — read-only on infrastructure 
  metadata only
- Access key rotated manually on a defined schedule

**Identity 3 — CI/CD Pipeline User (`sir-app-cicd`):**
- IAM user with scoped deploy permissions
- Can create, update, and destroy resources within the 
  `sir-app-*` naming scope
- Cannot access S3 bucket contents directly
- Cannot modify IAM policies or roles — prevents privilege 
  escalation
- Access key stored as encrypted secrets in the CI/CD system — 
  never in code or configuration files

**Separation of concerns:**

| Identity | Create/Destroy | Read Infra | Read S3 Data |
|---|---|---|---|
| EC2 role | ❌ | ❌ | ✅ |
| Developer | ❌ | ✅ | ❌ |
| CI/CD | ✅ | ✅ | ❌ |

No single identity has all three capabilities.

## Consequences

### Benefits
- **No static credentials on EC2** — IAM role credentials are 
  temporary, automatically rotated, and never stored on disk. 
  A compromised EC2 instance yields credentials that expire 
  within hours
- **Least privilege per identity** — each identity has exactly 
  the permissions it needs. A compromised developer credential 
  cannot deploy or destroy infrastructure. A compromised CI/CD 
  credential cannot access incident photo data
- **Privilege escalation prevention** — the CI/CD user cannot 
  modify IAM policies. Even if the pipeline is compromised, 
  the attacker cannot grant themselves additional permissions
- **Audit trail** — separate identities produce separate 
  CloudTrail logs. Developer actions, pipeline actions, and 
  application actions are distinguishable in audit logs
- **Blast radius limitation** — a security incident affecting 
  one identity does not expose the capabilities of the other 
  two identities

### Trade-offs
- **Three identities to manage** — separate users, roles, and 
  policies require more initial configuration and ongoing 
  maintenance than a single shared identity
- **Access key rotation** — the developer and CI/CD users have 
  static access keys that must be rotated on a schedule. IAM 
  roles eliminate this problem for EC2 but human and pipeline 
  users still require key management discipline
- **CI/CD permissions scope** — defining the exact permissions 
  the pipeline needs requires careful analysis. Too broad and 
  least privilege is violated. Too narrow and deployments fail 
  with permission errors. This requires iteration as new 
  resources are added to the project
- **No cross-account access in this design** — this IAM design 
  is scoped to a single AWS account. A multi-account architecture 
  (separate dev and prod accounts) would require additional 
  cross-account role assumptions, which are not implemented in 
  this phase