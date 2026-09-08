
**NAT Gateway is retained** for EC2 OS patching via `dnf` 
package manager. The user data script runs `dnf update` and 
`dnf install nginx` on first launch — this traffic still 
requires internet access via NAT Gateway. The endpoint 
only handles S3 traffic.

**Implementation:**
Added to `modules/networking/main.tf` alongside a 
`data "aws_region" "current"` data source — same pattern 
used in the compute module — to avoid hardcoding the region 
in the service name string.

## Consequences

### Benefits
- **Zero cost for S3 traffic** — no NAT Gateway data processing 
  charges for S3 reads and writes. At scale this is significant — 
  every incident photo upload and download was previously 
  processed through the NAT Gateway at $0.045/GB
- **Traffic never leaves AWS network** — EC2 to S3 communication 
  stays entirely within AWS infrastructure. No exposure to the 
  public internet for application data, improving security posture
- **Reduced NAT Gateway dependency** — the NAT Gateway now handles 
  only OS patching traffic. This reduces data transfer costs and 
  makes the future elimination of NAT Gateway (via golden AMI 
  pipeline) more feasible
- **No configuration change on EC2** — the endpoint works at the 
  route table level. The application code and AWS SDK configuration 
  on EC2 require no changes — S3 traffic is intercepted and 
  redirected transparently
- **Free** — Gateway endpoints for S3 and DynamoDB have no hourly 
  charge and no data processing charge

### Trade-offs
- **Gateway endpoints are VPC-scoped** — the endpoint is only 
  accessible from within this VPC. Resources in other VPCs cannot 
  use this endpoint. If a multi-VPC architecture is introduced in 
  future, each VPC requires its own Gateway endpoint or an 
  Interface endpoint with PrivateLink sharing
- **S3 and DynamoDB only** — Gateway endpoints are not available 
  for other AWS services. If EC2 needs private access to CloudWatch, 
  SSM, or other services without NAT Gateway, Interface endpoints 
  must be evaluated and their cost justified
- **NAT Gateway still required** — this endpoint eliminates S3 
  data transfer costs but does not eliminate the NAT Gateway 
  entirely. EC2 still requires outbound internet access for OS 
  patching. Full NAT Gateway elimination requires a golden AMI 
  pipeline — documented as a future consideration in ADR-003
- **Route table association** — the endpoint route is added to 
  the private and isolated route tables automatically by AWS. 
  This is invisible in the AWS console route table view unless 
  you know to look for it — operators unfamiliar with VPC 
  endpoints may be confused by S3 traffic not appearing to 
  traverse the NAT Gateway in flow logs