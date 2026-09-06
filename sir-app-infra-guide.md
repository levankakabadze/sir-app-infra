# GEKUT-App — Three-Tier AWS Infrastructure Project Guide

> **Goal:** Build a complete, real-world three-tier application infrastructure on 
  AWS using Terraform. Frontend, backend, database — the classic pattern every 
  company runs in production.

---

## Architecture Overview

```
Internet
    ↓
ALB (public subnet)
    ↓
EC2 — App Server (private subnet)
    ↓
RDS PostgreSQL (isolated subnet)
    +
S3 bucket (static assets / uploads)
    +
IAM users + roles + policies
    +
Security Groups (chained: ALB → App → DB)
```

---

## Project Structure

```
gekut-app-infra/
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── storage/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── iam/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── backend.tf
├── PROGRESS.md
└── README.md
```

---

## Module Descriptions

### `modules/networking`
- VPC with CIDR block
- Public subnets (ALB layer) — 2 AZs
- Private subnets (App layer) — 2 AZs
- Isolated subnets (DB layer) — 2 AZs
- Internet Gateway
- NAT Gateway (one per environment — **destroy after each session**)
- Route tables for each subnet tier

### `modules/compute`
- EC2 instance in private subnet
- Application Load Balancer in public subnets
- Target group + listener (port 80)
- User data script installing nginx and serving a basic HTML page
- Security groups (defined in their own module or inline)
- EC2 instance profile (IAM role attachment)

### `modules/database`
- RDS PostgreSQL on `db.t3.micro`
- DB subnet group using isolated subnets
- Parameter group
- No public access
- `sensitive = true` on password variable
- Outputs: endpoint, port, db name

### `modules/storage`
- S3 bucket with versioning enabled
- Server-side encryption
- Bucket policy — access restricted to app EC2 IAM role only
- Block all public access settings

### `modules/iam`
- IAM role for EC2 with S3 read/write policy
- Instance profile (attaches role to EC2)
- IAM user: `gekut-developer` — read-only access
- IAM user: `gekut-cicd` — scoped deploy permissions
- Output access key IDs — never output secret keys

---

## Environments

### `dev`
- Single AZ deployment
- `t3.micro` EC2
- `db.t3.micro` RDS
- Minimal redundancy
- Goal: fast iteration and cost control

### `prod`
- Two AZ deployment
- Slightly larger instance types
- Multi-AZ RDS config scaffolded (can be toggled)
- Goal: demonstrate environment parity through same modules + different tfvars

> **Same modules, different `terraform.tfvars` values. This is the point.**

---

## Build Phases

### Phase 1 — Foundation
- [ ] Create GitHub repo `gekut-app-infra`
- [ ] Set up folder structure
- [ ] Create S3 bucket for remote state
- [ ] Configure `backend.tf` with S3 backend and native locking (`use_lockfile = true`)
- [ ] Configure AWS provider in `dev/main.tf`
- [ ] Run `terraform init` and `terraform validate`
- [ ] Create `PROGRESS.md`

### Phase 2 — Networking Module
- [ ] Build `modules/networking` — VPC, subnets, IGW, NAT Gateway, route tables
- [ ] Call module from `environments/dev/main.tf`
- [ ] Run `terraform apply` in dev
- [ ] Verify outputs: VPC ID, subnet IDs
- [ ] Write ADR: subnet tier design decision
- [ ] **Destroy NAT Gateway after session**

### Phase 3 — Security Groups
- [ ] Add security group resources to `modules/compute` or a dedicated `modules/security` module
- [ ] ALB SG: accepts port 80/443 from `0.0.0.0/0`
- [ ] App SG: accepts port 80 from ALB SG only
- [ ] DB SG: accepts port 5432 from App SG only
- [ ] Verify chaining — no direct internet access to App or DB
- [ ] Write ADR: chained security group design

### Phase 4 — Compute Module
- [ ] Build `modules/compute` — EC2 + ALB + Target Group
- [ ] User data script: install nginx, serve HTML page with environment name
- [ ] Output ALB DNS name from root module
- [ ] Run `terraform apply` — hit the URL in browser
- [ ] Verify: browser shows nginx page
- [ ] **Destroy EC2 and ALB after session**

### Phase 5 — Database Module
- [ ] Build `modules/database` — RDS PostgreSQL
- [ ] DB subnet group in isolated subnets
- [ ] `sensitive = true` on `db_password` variable
- [ ] Output: endpoint, port (never output password)
- [ ] Verify: EC2 can reach RDS endpoint, internet cannot
- [ ] **Destroy RDS after session**

### Phase 6 — Storage Module
- [ ] Build `modules/storage` — S3 bucket
- [ ] Enable versioning and server-side encryption
- [ ] Bucket policy: allow access from EC2 IAM role only
- [ ] Block all public access
- [ ] Verify: EC2 can read/write, public access denied

### Phase 7 — IAM Module
- [ ] Build `modules/iam`
- [ ] EC2 role with S3 policy — attach via instance profile in compute module
- [ ] Developer user with read-only managed policy
- [ ] CI/CD user with scoped inline policy
- [ ] Output: user ARNs, access key IDs (no secrets)
- [ ] Write ADR: least-privilege IAM design

### Phase 8 — Prod Environment
- [ ] Create `environments/prod/terraform.tfvars` with prod values
- [ ] Deploy prod using same modules
- [ ] Verify: prod and dev are identical in structure, different in values
- [ ] Compare outputs between environments

---

## Cost Control Rules

| Resource | Approx Cost | Rule |
|---|---|---|
| NAT Gateway | ~$0.045/hr | **Destroy after every session** |
| RDS db.t3.micro | ~$0.017/hr | **Destroy after every session** |
| EC2 t3.micro | ~$0.010/hr | **Destroy after every session** |
| ALB | ~$0.008/hr | **Destroy after every session** |
| S3 bucket | ~$0.00 for lab | Leave running |
| VPC, subnets, SGs | Free | Leave running |
| IAM resources | Free | Leave running |

> **Estimated cost per 2-hour session: ~$0.16. Ten sessions total: under $2.**

---

## ADRs (Architecture Decision Records)

ADRs are first-class deliverables in this project. Write one for each significant design decision.

### ADR Template
```
# ADR-XXX: [Title]

## Status
Accepted

## Context
[Why did this decision need to be made?]

## Decision
[What was decided?]

## Consequences
[What are the trade-offs?]
```

### ADRs to Write
- [ ] ADR-001: Three-tier subnet design (public / private / isolated)
- [ ] ADR-002: Chained security groups over flat model
- [ ] ADR-003: RDS in isolated subnets with no internet route
- [ ] ADR-004: S3 bucket policy vs IAM policy for access control
- [ ] ADR-005: Separate IAM users for developer vs CI/CD pipeline

---

## Naming Convention

All resources use the `GEKUT-` prefix:

```
GEKUT-dev-vpc
GEKUT-dev-public-subnet-1a
GEKUT-dev-app-sg
GEKUT-dev-alb
GEKUT-dev-ec2-app
GEKUT-dev-rds-postgres
GEKUT-dev-s3-assets
GEKUT-prod-vpc
... etc
```

---

## Key Design Principles

**Custom modules over registry** — every module is written from scratch. No `terraform-aws-modules` shortcuts. The point is learning the internals.

**Remote state from Phase 1** — S3 backend configured before any resources are deployed. Never local state.

**Least privilege IAM** — every role and user has only the permissions needed. No `*` actions, no `*` resources unless explicitly justified in an ADR.

**Destroy after sessions** — NAT Gateway, RDS, EC2, ALB are destroyed after every session to keep costs near zero.

**ADRs as deliverables** — every non-obvious design decision is documented. This is what separates architect portfolios from engineer portfolios.

---

## What This Project Demonstrates

| Skill | How it's shown |
|---|---|
| Module composition | 5 custom modules called from environment root |
| Environment parity | Same modules, different tfvars for dev and prod |
| Remote state | S3 backend with native locking |
| Security design | Chained SGs, isolated DB subnet, no public RDS |
| IAM design | Least-privilege roles, separate users per persona |
| Secrets handling | `sensitive = true` on passwords, no secrets in outputs |
| Cost discipline | Destroy pattern enforced every session |
| Architect thinking | ADRs documenting design decisions with trade-offs |

---

## Prerequisites

- AWS IAM user `admintf` with least-privilege scoped policies (already configured)
- AWS credentials loaded via `source ~/.aws_lab_creds`
- Terraform v1.x installed on `cloud-dev` Ubuntu VM
- VS Code with HashiCorp Terraform extension
- GitHub repo created: `levankakabadze/gekut-app-infra`

---

## PROGRESS.md Tracking

Update `PROGRESS.md` after every session. It is the single source of truth for project state.

```markdown
## Phase X — [Name]
**Status:** Complete / In Progress / Blocked
**Date:** YYYY-MM-DD
**What was built:** ...
**Decisions made:** ...
**Next session:** ...
**Estimated cost this session:** $X.XX
```

---

*Start after exam. Build phase by phase. Document every decision.*
