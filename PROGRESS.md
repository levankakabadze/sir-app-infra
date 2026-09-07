# SIR-App Infrastructure — Progress Log

## Phase 1 — Foundation
**Status:** ✅ Complete
**Date Started:** 2026-08-30

### Completed
- [x] AWS credentials verified — user `admintf`, account `340357940256`
- [x] Region confirmed — `eu-central-1` (Frankfurt)
- [x] GitHub repository created — `levankakabadze/sir-app-infra` (private)
- [x] Project folder structure scaffolded
- [x] ADR-001 written — three-tier subnet architecture
- [x] S3 state bucket created — `sir-app-terraform-state`
  - Versioning enabled
  - AES256 encryption enabled
  - Public access fully blocked

### Next Session
- [ ] Write `environments/dev/backend.tf`
- [ ] Write `environments/dev/providers.tf`
- [ ] Run `terraform init` in dev environment
- [ ] Validate configuration

### Decisions Made
- Region: `eu-central-1` (Frankfurt) — closest to Valencia office,
  aligned with European operations
- State bucket named `sir-app-terraform-state` — matches IAM 
  policy pattern `sir-app-*`
- S3 native locking (`use_lockfile = true`) — no DynamoDB table 
  needed, Terraform v1.10+ feature

### Cost This Session
$0.00 — S3 bucket, IAM policy update, no compute resources created

## Phase 2 — Networking Module
**Status:** ✅ Complete

### Completed
- [x] modules/networking/variables.tf
- [x] modules/networking/main.tf — VPC, subnets, IGW, NAT, route tables
- [x] modules/networking/outputs.tf
- [x] environments/dev/main.tf — root module calling networking
- [x] environments/dev/variables.tf
- [x] environments/dev/terraform.tfvars — CIDR values from ADR-001
- [x] terraform init — networking module downloaded
- [x] terraform plan — 19 resources previewed, all correct
- [x] terraform apply — 19 resources created successfully
- [x] Verified in AWS — VPC, subnets, state file in S3 confirmed
- [x] NAT Gateway destroyed after session — cost stopped

## Key Learnings
- `target` destroy cascades through dependencies - destroying NAT Gateway also destroys private route table and its associations (5 resources total)
- State file confirmed at s3://sir-app-terraform-state/dev/terraform.tfstate

## Cost This Session
- ~$0.01 — NAT Gateway ran approximately 10 minutes at $0.052/hr

---

## Phase 3 - Security Module
**Status:** ✅ Complete

## To Do
- [ ] Write ADR-002 — security group chaining design
- [ ] Build modules/security/ — ALB SG, App SG, DB SG
- [ ] Call security module from environments/dev/main.tf
- [ ] Verify chaining — correct ingress/egress rules

### Completed
- [x] ADR-002 written - chained security group architecture
- [x] modules/security/variables.tf
- [x] modules/security/main.tf - 3 SGs + 7 SG rules
- [x] modules/security/output.tf - alb_sg_id, app_sg_id, db_sg_id
- [x] Fixed circular dependency - separated SG creation from rules
- [x] terraform apply -target=module.security - 10 resources created
- [x] Verified in AWS - all 3 SGs confirmed, rules verified

## Key learnings
- Inline SG rules cause circular dependency when SGs reference
  each other - fix by using separate aws_security_group_rule
  resources
- `terraform apply - target=module.name` targets entire module
  at once - no need to list individual resources
- `security_groups` argument used for SG-to-SG references -
  `cidr_blocks` only for IP ranges
- `source_security_group_id` used in aws_security_gorup_rule
  for SG references

### Cost This Session
$0.00 - security groups are free

---

## Phase 4 - Compute Module
**Status:** ✅ Complete

### Completed
- [x] ADR-003 written - compute architecture decision
- [x] modules/compute/variables.tf
- [x] modules/compute/user_data.sh - nginx + SIR landing page
- [x] modules/compute/main.tf - ALB, target group, listener, EC2
- [x] modules/compute/outputs.tf - ALB DNS name, EC2 instance ID
- [x] environments/dev/main.tf - compute module corrected
- [x] environments/dev/variables.tf - ami_id, instance_type added
- [x] terraform apply - SIR landing page live in browser
- [x] Verified http://sir-app-dev-alb-322921282.eu-central-1.elb.amazonaws.com
- [x] Destroyed - EC2, ALB, NAT Gateway after session

### Key Learnings
- admintf needed `elasticloadbalancing:*` and `iam:CreateServiceLinkedRole`
  permissions - added to sir-app-terraform-compute-policy
- Service linked role for ELB created automatically on first ALB
  in the account - one-time permission requirement
- `templatefile()` injects Terraform variables into bash scripts -
  `${environment}` and `${region}` substituted before EC2 receives script
- data "aws_region" "current" reads region from provider -
  no need to hardcode or declare as variable
- ALB target group health check must pass before traffic routes
- -target destroy o compute cascades: ALB listener, target group
  attachment, private RT associations all destroyed automatically

### Cost This Session
- ~$0.15 - NAT Gateway + EC2 + ALB at Frankfurt rates

## Phase 5 — Database Module
**Status:** In Progress
**Date Started:** 2026-09-07

### Completed
- [x] ADR-004 written — RDS database isolation design
- [x] modules/database/variables.tf
- [x] modules/database/main.tf — RDS PostgreSQL in isolated subnets
- [x] modules/database/outputs.tf — endpoint, name, port
- [x] environments/dev/main.tf — database module connected
- [x] environments/dev/variables.tf — db variables added
- [x] environments/dev/terraform.tfvars — db credentials added locally
- [x] terraform plan — 11 resources verified, password shown as sensitive

### Pending
- [ ] terraform apply — waiting for storage and IAM modules

---

## Phase 6 — Storage Module
**Status:** Not Started

### To Do
- [ ] ADR-005 written ✅
- [ ] Build modules/storage/ — S3 bucket, versioning, encryption
- [ ] Bucket policy — EC2 role only
- [ ] Connect to root module

---

## Phase 7 — IAM Module
**Status:** Not Started

### To Do
- [ ] ADR-006 written ✅
- [ ] Build modules/iam/ — EC2 role, developer user, CI/CD user
- [ ] Instance profile for EC2
- [ ] Connect to root module

---

## Apply Session (After Phase 6 and 7 complete)
- [ ] terraform apply — deploy all modules together
- [ ] Verify RDS endpoint output
- [ ] Verify S3 bucket exists
- [ ] Verify IAM roles and users created
- [ ] Destroy RDS, EC2, ALB, NAT Gateway after session