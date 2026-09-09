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
- [x] terraform apply — RDS available, endpoint confirmed

### Key Learnings
- RDS forbidden password characters: / @ " and space
- @ symbol in password causes `InvalidParameterValue` error
- State lock not released on failed apply - use `force-unlock`
- RDS service linked role requires `iam:CreateServiceLinkedRole`
  permission on first RDS instance in account
- RDS provisioning takes ~10-15 minutes - normal behavior

### Cost This Session
~$0.20 - NAT GW + EC2 + ALB + RDS ~ 1.5 hours at Frankfurt rates

---

## Phase 6 — Storage Module
**Status:** ✅ Complete
**Date Completed:** 2026-09-08

### Completed
- [x] ADR-005 written — S3 access control design
- [x] modules/storage/variables.tf
- [x] modules/storage/main.tf — S3 bucket, versioning, encryption,
      public access block, bucket policy
- [x] modules/storage/outputs.tf — bucket_name, bucket_arn
- [x] Connected to root module via module.iam.ec2_role_arn
- [x] Verified — sir-app-dev-assets bucket created in AWS

### Cost
$0.00 — S3 storage only, negligible for lab

---

## Phase 7 — IAM Module
**Status:** ✅ Complete
**Date Completed:** 2026-09-08

### Completed
- [x] ADR-006 written — IAM least privilege design
- [x] modules/iam/variables.tf
- [x] modules/iam/main.tf — EC2 role, instance profile,
      developer user, CI/CD user
- [x] modules/iam/outputs.tf — role ARN, profile name, user ARNs
- [x] Resolved circular dependency — removed S3 policy from IAM
      module, bucket policy in storage module handles access
- [x] EC2 instance profile connected to compute module
- [x] Verified — IAM resources created successfully

---

## Phase 8 — VPC Endpoint
**Status:** ✅ Complete
**Date Completed:** 2026-09-08

### To Do
- [x] ADR-007 written — S3 Gateway VPC endpoint decision
- [x] Added data "aws_region" "current" to networking module
- [x] Added aws_vpc_endpoint.s3 to networking module
- [x] Associated with private and isolated route tables
- [x] terraform plan — 23 resources verified
- [x] Verified — VPC endpoint active, S3 traffic routed internally

### Key Learnings
- S3 Gateway endpoint is free — eliminates NAT Gateway 
  data transfer charges for S3 traffic
- Gateway endpoints work at route table level — no app 
  code changes needed
- Only S3 and DynamoDB support Gateway endpoints — 
  all other services need Interface endpoints (cost money)

---

## Full Stack Apply — All Modules
**Status:** ✅ Complete
**Date Completed:** 2026-09-08

### Verified
- [x] ALB DNS name — SIR landing page live in browser
- [x] EC2 — nginx running, IAM instance profile attached
- [x] RDS — available, endpoint confirmed
- [x] S3 — sir-app-dev-assets bucket created
- [x] IAM — EC2 role, developer user, CI/CD user created
- [x] VPC endpoint — S3 traffic routed internally
- [x] All security groups — chained correctly
- [x] Destroyed — RDS, EC2, ALB, NAT Gateway after session

### What is still running (free)
- VPC, subnets, IGW, route tables
- Security groups + rules
- S3 bucket (sir-app-dev-assets)
- IAM roles and users
- VPC endpoint

### Total Project Cost To Date
~$0.45 across all sessions


## Refactor — Multi-AZ NAT Gateway Support
**Status:** ✅ Complete
**Date Completed:** 2026-09-08

### Completed
- [x] Added nat_gateway_azs variable to networking module
- [x] Refactored aws_eip to use for_each
- [x] Refactored aws_nat_gateway to use for_each
- [x] Refactored aws_route_table.private to use for_each
- [x] Refactored aws_route_table_association.private fallback logic
- [x] Added moved blocks — zero destroys during refactor
- [x] Added nat_gateway_azs to dev and prod environments
- [x] terraform apply — verified moved blocks, browser confirmed working

---

## Prod Environment
**Status:** ✅ Complete
**Date Completed:** 2026-09-08

### Completed
- [x] environments/prod/backend.tf — prod state isolated
- [x] environments/prod/providers.tf — prod tags
- [x] environments/prod/variables.tf — all variables declared
- [x] environments/prod/terraform.tfvars — prod values
- [x] environments/prod/main.tf — all 6 modules connected
- [x] modules/database — multi_az and deletion_protection variables added
- [x] terraform init — prod backend initialized
- [x] terraform validate — configuration valid
- [x] terraform plan — 51 resources, multi_az=true, deletion_protection=true confirmed

### Key Differences from Dev
- nat_gateway_azs = ["a", "b"] — two NAT Gateways for AZ resilience
- multi_az = true — RDS Multi-AZ standby in isolated-1b
- deletion_protection = true — RDS protected from accidental destroy
- instance_type = t3.small — slightly larger for prod workload
- Environment tag = "prod" on all resources

### Cost if Applied (not applied — plan only)
~$0.20+/hr — 2x NAT GW + EC2 + ALB + RDS Multi-AZ

---

## Project Status: ✅ COMPLETE

### What Was Built
- 7 Architecture Decision Records
- 6 Terraform modules (networking, security, compute, database, storage, iam)
- 2 environments (dev deployed and verified, prod planned and verified)
- Production architecture diagram
- README.md portfolio documentation
- Total project cost: ~$0.65