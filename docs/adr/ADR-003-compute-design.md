# ADR-003: Compute Architecture — ALB and EC2 Design

## Status
Accepted

## Date
2026-09-06

## Author
Levan Kakabadze

## Context

The SIR application requires compute infrastructure to serve the
web interface to plant workers. Two architectural decisions needed
to be made:

**Decision 1 —  Where to place the EC2 instance:**
The EC2 application server could be placed in a public subnet with
a public IP address, allowing direct internet access. However, this
approach increases the attack surface — any port on the EC2 instance
becomes directly reachable from the internet, including SSH (port 22)
and any misconfigured application ports. A compromised or 
misconfigured EC2 instance in a public subnet is directly exposed
whith no network-level barrier between it and the internet. 

**Decision 2 — Whether to use an Application Load Balancer:**
Traffic could be routed directly to an EC2 instance with a public
IP, avoiding the cost of an ALB. However, this approach creates a 
single point of failure with no health checking, no horizontal
scaling capability, and no controlled entry point for traffic 
management. As the SIR applicaiton grows to support more plant
sites and users, direct EC2 routing cannot scale without DNS or
client configuration changes. 

## Decision
We deploy the EC2 application server in a private subnet with no
public IP address, fronted by an Application Load Balancer in the
public subnet. 

**EC2 placement — private subnet:**
- No public IP assigned — the instance is not reachble from the 
  internet directly under any circumstances
- The only inbound path is port 80 from the ALB security group
- SSH access requires tunelling through AWS System Manager
  Session Manage — no public SSH exposure
- Outbound internet access for OS patching is provided via the 
  NAT Gateway in the public subnet


**Application Load Balancer — in public subnet**
- Receives all inbound traffic from the internet on port 80
- Forwards traffic to the EC2 instance via the target group
- Performs health checks every 30 seconds on port 80 path '/'
- Automatically stops routing to unhealthy instances
- Provides a stable DNS endpoint that does not change when
  EC2 instances are replaced or scaled. 

**User data script:**
- Installs nginx on first launch via Amazon Linux 2023 `dnf`
- Serves a static SIR applicaiton landing page
- Environment and region values injected via Terraform
  `templatefile()` function at deploy time

## Consequences

### Benefits
- **Reduced attach surface** - EC2 has no public IP and no direct
  internet exposure. An attacker cannot reach the application server
  without going through the ALB and its security group rules
- **Single controlled entry point** - all traffic enters through 
  the ALB. Security rules, logging, and access control are managed 
  in one place. 
- **Health checking** - the ALB automatically detects unhealthy
  instances and stops routing traffic to them, improving
  application resilience without manual intervention
- **Horizontal scalability** - additional EC2 instances can be
  registered to the target group without changing the DNS endpoint
  or client configuration
- **Stable endpoint** - the ALB DNS name remains constant even 
  when EC2 instances are replaced, updated, or scaled


### Trade-offs
- **ALB as single entry point** - If the ALB becomse unavailable
  the application is unreachable regardless of EC2 health. In dev
  this is acceptable. Prodution should implement Route 53 health
  checks with DNS failover to a secondary region for critical 
  availability requirements. 
- **ALB cost** - the ALB incurs an hourly charge (~$0.008/hr)
  plus LCU charges based on traffic. This is justified by the
  security and scalability benefits but must be accounted for
  in production budgets
- **Increased complexity** - the tjree-component stack (ALB + 
  target group + listener) requires more onfiguration than a
  EC2 instance with a Public IP
- **No Direct SSH access** - developers cannot SSH directly to
  the EC2 instance. Access requires AWS Systems Manager Session
  Manager or a bstion host pattern
- **Single EC2 instance in dev** - the current dev configuration
  runs one EC2 instance with no Auto Scaling. A single instance
  failure would cause downtime until manually resolved. Production
  should implement Auto Scaling Groups across multiple AZs. 