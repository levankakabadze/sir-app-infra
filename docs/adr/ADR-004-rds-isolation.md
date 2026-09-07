# ADR-004: RDS Database Isolation in Dedicated Subnet Tier

## Status
Accepted

## Date
2026-09-07

## Author
Levan Kakabadze

## Context

The SIR application requires a PostgreSQL database to store plant 
incident records, photo metadata, and application data. The database 
must be accessible to the application server but must not be 
reachable from the internet under any circumstances.

Two placement options were evaluated:

**Option 1 — RDS in the private subnet (alongside EC2):**
The private subnet already exists and hosts the EC2 application 
server. Placing RDS here would simplify the architecture — both 
application and database in the same subnet tier. However, the 
private subnet has a route to the NAT Gateway, which provides 
outbound internet access. This means any resource in the private 
subnet has a network path to the internet — even if security 
groups block it today, that path exists at the network level.

**Option 2 — RDS in a dedicated isolated subnet:**
A third subnet tier with no route table entries beyond local VPC 
traffic. No NAT Gateway route. No Internet Gateway route. The 
network path to the internet does not exist — it is not blocked 
by software rules, it simply does not exist at the network level.

The key distinction is defence in depth:
- Private subnet: internet access blocked by security group (software)
- Isolated subnet: internet access impossible at network level (topology)

A database storing sensitive plant safety incident data should not 
rely solely on software-level controls when network-level isolation 
is available at no additional cost.

## Decision

We deploy RDS PostgreSQL in the isolated subnet tier — a dedicated 
subnet with no internet route in any direction.

**RDS placement — isolated subnets:**
- Deployed across two isolated subnets (`10.0.21.0/24` and 
  `10.0.22.0/24`) via a DB subnet group
- No route to NAT Gateway — cannot initiate outbound internet 
  connections
- No route to Internet Gateway — cannot receive inbound internet 
  connections
- The only permitted inbound connection is port 5432 from the 
  App security group — enforced by the DB security group we 
  defined in ADR-002
- `publicly_accessible = false` — RDS will not receive a public 
  endpoint regardless of subnet configuration

**DB subnet group:**
- AWS requires a DB subnet group spanning at least two AZs for 
  RDS deployment
- We use both isolated subnets (`eu-central-1a` and `eu-central-1b`)
- RDS will be placed in one AZ by AWS — the subnet group provides 
  the AZ options

**Instance configuration for dev:**
- Engine: PostgreSQL 16
- Instance class: `db.t3.micro` (free tier eligible)
- Storage: 20GB gp2
- `skip_final_snapshot = true` — lab environment, no real data
- `multi_az = false` — single AZ for dev cost control

**Database credentials:**
- Password marked as `sensitive = true` — hidden from plan output 
  and terminal logs
- Password stored in `terraform.tfvars` locally — never committed 
  to Git

## Consequences

### Benefits
- **Network-level isolation** — RDS has no internet route at the 
  network topology level. A misconfigured security group cannot 
  expose the database to the internet because the network path 
  does not exist
- **Defence in depth** — two independent layers of protection: 
  network topology (isolated subnet) and identity-based access 
  control (security group referencing). Both must fail for the 
  database to be exposed
- **Least privilege at network level** — RDS only has the network 
  access it needs: receive queries from EC2 on port 5432. Nothing 
  more exists at the network level
- **Compliance alignment** — storing sensitive incident data in a 
  network-isolated tier with no internet route supports data 
  protection requirements in manufacturing and industrial 
  environments
- **No additional cost** — isolated subnets cost nothing. The 
  security benefit is free compared to placing RDS in the private 
  subnet

### Trade-offs
- **No direct developer access** — developers cannot connect to 
  RDS directly from their workstations. Access requires tunnelling 
  through the EC2 instance via AWS Systems Manager Session Manager
- **No RDS patch automation via internet** — RDS managed patches 
  from AWS are applied through AWS internal networks, not via the 
  NAT Gateway. This is actually correct behavior — but worth 
  documenting to avoid confusion
- **Additional subnet tier complexity** — three subnet tiers 
  require more route table configuration than two tiers. This 
  complexity was accepted in ADR-001 and is not additional cost 
  here — the isolated subnets already exist
- **Single AZ in dev** — `multi_az = false` means a single AZ 
  failure causes database downtime in dev. This is acceptable for 
  a non-production environment. Production must enable Multi-AZ 
  for incident data availability