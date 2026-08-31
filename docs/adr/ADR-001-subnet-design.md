# ADR-001: Three-Tier Subnet Architecture

## Status
Accepted

## Date
30-08-2026

## Author
Levan Kakabadze 

## Context
The SIR (Site Incident Reporting) application requires network 
infrastructure on AWS to support plant workers submitting incident 
reports across 25+ global manufactuing sites. 

The application has three distinct components with different 
exposure requirements:

- **Application Load Balance** - must be reachable from the 
  public internet to allow plant workers to access the application
  from any site globally. 
- **EC2 Application Server** - processes incident reports and
  communicates with the database. Requires outbound internet access
  for OS patching and AWS API calls, but must not be directly 
  reachable from the internet. 
- **RDS PostgreSQL Database** - stores all incident records and
  photo metadata. Requires no internet connectivity in any 
  direction - it only needs to receive queries from the 
  application server. 

Placing all three components in a single subnet would mean that
any component inheriting an internet route would expose all
components to the same network path. A compromised or 
misconfigured load balance in a flat network could provide
a path to the database - an unacceptable risk for sensitive
plant safety data. 

## Decision

We implement a three-tier subnet architecture across two 
Availability Zones (eu-central-1a and eu-central-1b) within 
a dedicated VPC.

**Tier 1 — Public Subnets**
- Houses the Application Load Balancer only
- Has a route to the Internet Gateway (inbound and outbound)
- Plant workers reach the application through this tier
- No application logic or data storage in this tier

**Tier 2 — Private Subnets**
- Houses the EC2 application server
- No inbound route from the internet
- Outbound internet access via NAT Gateway for OS patching 
  and AWS API calls only
- Receives traffic exclusively from the ALB via security group rules

**Tier 3 — Isolated Subnets**
- Houses the RDS PostgreSQL database
- No internet route in any direction — no inbound, no outbound
- Completely air-gapped from the internet
- Receives traffic exclusively from the EC2 application server 
  via security group rules
- No NAT Gateway association

Two Availability Zones are used for each tier to provide 
resilience against a single AZ failure, following AWS 
Well-Architected Framework recommendations.

## Consequences

### Benefits
- **Defence in depth** — a compromised ALB cannot directly reach 
  the database. An attacker must traverse multiple network tiers 
  and security group rules, significantly increasing attack 
  complexity
- **Blast radius reduction** — a security incident in the public 
  tier does not automatically expose application logic or plant 
  safety data
- **Compliance alignment** — isolating sensitive incident data in 
  a subnet with no internet route supports data protection 
  requirements relevant to manufacturing environments
- **Clear operational boundaries** — each tier has a single 
  responsibility, making troubleshooting and auditing straightforward

### Trade-offs
- **NAT Gateway cost** — providing outbound internet access to 
  the private tier requires a NAT Gateway (~$0.045/hr). This is 
  a recurring cost that must be accounted for in production budgets
- **Increased complexity** — three subnet tiers with separate 
  route tables require more configuration than a flat network. 
  This is justified by the security requirements but adds 
  operational overhead
- **No direct database access** — developers cannot connect 
  directly to RDS from their workstations. Access requires 
  tunnelling through the EC2 instance (bastion pattern) or 
  AWS Systems Manager Session Manager

## CIDR Block Allocation

| Subnet | AZ | CIDR | Tier |
|---|---|---|---|
| public-1a | eu-central-1a | 10.0.1.0/24 | Public |
| public-1b | eu-central-1b | 10.0.2.0/24 | Public |
| private-1a | eu-central-1a | 10.0.11.0/24 | Private |
| private-1b | eu-central-1b | 10.0.12.0/24 | Private |
| isolated-1a | eu-central-1a | 10.0.21.0/24 | Isolated |
| isolated-1b | eu-central-1b | 10.0.22.0/24 | Isolated |

**VPC CIDR:** `10.0.0.0/16`