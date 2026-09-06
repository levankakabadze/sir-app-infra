# ADR-002: Chained Security Group Architecture

## Status
Accepted

## Date
2026-09-06

## Author
Levan Kakabadze

## Context
The SIR application  requires network access controls betweent three
infrastructure tiers: the load balancer, the application server, and
the database. Two approaches were evaluated for implementing these
controls:

**Option 1: Subnet-level controls (NACLs + CIDR rules)**
In on-premises environments, traffic between network segments is 
commonly controlled at the subnet level using ACLs tied to IP
ranges. This is the standard pattern in traditional network
environments - VLANs with ACL rules defining which IP ranges
can communicate with each other. 

**Option 2: Security group referencing (chained SGs)**
 AWS Security Groups can reference other security groups as traffic
 sources instead of IP CIDR ranges. This decouples access control
 from network topology - a rule says "allow traffic FROM this 
 security group" rather than "allow traffic from this IP range."

 The key problem with CIDR-based rules in a cloud environment is 
 that they are tied to network topology. When infrastructure scales
 horizontally - new EC2 instance added, new subnets created, IP 
 ranges changed - every CIDR-based rule must be updated manually.
 This creates operational overhead and introduces the risk of
 misconfiguration during scaling events.

 The SIR application must support users across multiple global
 sites. The infrastructure must scale without requiring security
 rule updates on every topology change. 

 ## Decision
 
 We implement chained security groups, three dedicated security
 groups, each referencing the previous tier as its traffic source.

 **ALB Security Group (`sir-app-dev-alb-sg`)**
 - Inbound: port 80 from `0.0.0.0/0` (all internet traffic)
 - Inbound: port 443 from `0.0.0.0/0` (HTTPS - future)
 - Outbound: port 80 to App Security Group only

  **App Security Group (`sir-app-dev-app-sg`)**
 - Inbound: port 80 from ALB Security Group only
 - Inbound: port 5432 to DB Security Group only
 - Outbound: port 443 to`0.0.0.0/0` (for OS patching via NAT)

  **DB Security Group (`sir-app-dev-db-sg`)**
 - Inbound: port 443 from App Security Group Only
 - Outbound: None

The chain is enforced by referencing security group IDs as 
ingress sources rather than CIDR blocks. Only two rules 
reference IP ranges — the ALB inbound from the public internet, 
and the App server outbound to the internet for OS patching 
via NAT Gateway. All inter-tier communication uses security 
group references exclusively.

 This creates a strict unidirectional flow:
 `Internet --> ALB SG --> APP SG --> DB SG`

 No tier can be reached by bypassing the tier above it. 

 
## Consequences

### Benefits
- **Topology independence** — security rules are tied to resource 
  identity, not IP addresses. Adding new EC2 instances, subnets, 
  or AZs requires no security rule changes — simply assign the 
  correct security group to the new resource
- **Least privilege enforcement** — each tier can only communicate 
  with the tier directly above or below it. The database cannot be 
  reached from the internet under any circumstances, even if the 
  ALB or app server is compromised
- **Auditability** — security group rules clearly express intent. 
  "Allow from alb-sg" is more readable and self-documenting than 
  "Allow from 10.0.1.0/24 and 10.0.2.0/24"
- **Scalability** — horizontal scaling does not require firewall 
  rule updates. This is the fundamental difference from 
  CIDR-based controls in traditional network environments

### Trade-offs
- **AWS-specific pattern** — security group referencing is an AWS 
  concept. This pattern does not translate directly to on-premises 
  environments or other cloud providers without equivalent 
  identity-based controls
- **Outbound rules require attention** — default AWS security 
  groups allow all outbound traffic. Explicit outbound rules 
  must be defined and maintained to enforce least privilege 
  in both directions
- **Circular dependency risk** — when security groups reference 
  each other, Terraform must create them in the correct order. 
  Care must be taken to avoid circular references that would 
  prevent deployment