# terraform-aws-multi-tier-state

## Cloud State with Terraform

This project provisions a complete multi-tier infrastructure on AWS using Terraform, with a focus on maintaining centralized state management. It includes a Java/Tomcat application deployed on Elastic Beanstalk within a custom VPC, along with fully managed backend services.

## Problem

Manual infrastructure management leads to:
- Non-repeatable setups across dev, QA, staging, and production
- No change tracking (who made what, when)
- Human errors causing broken infrastructure or security exposure
- Time-consuming documentation
- Configuration drift

## Solution

Infrastructure as Code with Terraform + centralized state management in S3.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Local Machine                           │
│                      Terraform CLI + Code                       │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              S3 Bucket (Terraform State)                │    │
│  │           DynamoDB (State Locking)                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                  │
│                              ▼                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │                         VPC                            │     │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │     │
│  │  │ Public Subnet│  │ Public Subnet│  │ Public Subnet│  |     │
│  │  │   (AZ A)     │  │   (AZ B)     │  │   (AZ C)     │  |     │
│  │  │     ↓        │  │     ↓        │  │     ↓        │  |     │
│  │  │ Internet GW  │  │ Internet GW  │  │ Internet GW  │  |     │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │     │
│  │                                                        |     │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │     │
│  │  │Private Subnet│  │Private Subnet│  │Private Subnet│  │     │
│  │  │   (AZ A)     │  │   (AZ B)     │  │   (AZ C)     │  │     │
│  │  │     ↓        │  │     ↓        │  │     ↓        │  │     │
│  │  │  NAT GW      │  │  NAT GW      │  │  NAT GW      │  │     │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │     │
│  └────────────────────────────────────────────────────────┘     │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                      Stack Services                     │    │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌──────────────┐   │    │
│  │  │   RDS   │ │ Elastic │ │ Active  │ │ Elastic      │   │    │
│  │  │ (MySQL) │ │  Cache  │ │   MQ    │ │ Beanstalk    │   │    │
│  │  │         │ │         │ │         │ │ (Java/Tomcat)│   │    │
│  │  └─────────┘ └─────────┘ └─────────┘ └──────────────┘   │    │
│  │                                                         │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │  Bastion Host + Security Groups + Key Pairs     │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

- Terraform backend: S3 (state storage) + DynamoDB (state locking)
- VPC with public and private subnets across multiple AZs
- Internet Gateway and NAT Gateway
- Bastion host for private subnet access and database initialization
- RDS (MySQL) in private subnets
- Elastic Cache (Memcached) in private subnets
- Amazon MQ (RabbitMQ) in private subnets
- Elastic Beanstalk with Java/Tomcat application (instances in private subnets, load balancer in public subnets)
- Security groups and key pairs

## What Gets Deployed

| Component | Location |
|-----------|----------|
| VPC | Custom CIDR |
| Public Subnets (3 AZs) | Connected to Internet Gateway |
| Private Subnets (3 AZs) | Connected to NAT Gateway |
| Bastion Host | Public subnet for SSH access + DB initialization |
| RDS (MySQL) | Private subnets |
| Elastic Cache (Memcached) | Private subnets |
| Amazon MQ (RabbitMQ) | Private subnets |
| Elastic Beanstalk (Java/Tomcat) | LB in public, instances in private |

## Elastic Beanstalk (Java/Tomcat Application)

A Java-based web application running on Tomcat 10, deployed on Elastic Beanstalk within the custom VPC.

### Application Configuration

| Configuration | Value |
|---------------|-------|
| Solution Stack | 64bit Amazon Linux 2023 v5.13.1 running Tomcat 10 Corretto 21 |
| Instance Type | t3.micro |
| Root Volume | gp3 |
| Min/Max Instances | 1 / 2 |
| Deployment Policy | Rolling with health checks |
| Batch Size | 1 instance at a time |
| Public IP | Disabled (instances in private subnets) |
| Load Balancer | Cross-zone enabled |
| Stickiness | Enabled |
| Health Reporting | Enhanced |

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| environment | prod | Environment identifier |
| LOGGING_APPENDER | GRAYLOG | Centralized logging configuration |

### Rolling Update Strategy

The environment is configured for zero-downtime deployments using a rolling update strategy:
- Updates happen one instance at a time (batch size of 1)
- Health checks verify each instance before proceeding
- Deployment policy ensures application availability during updates

## Backend Services

### RDS (MySQL)

A managed MySQL database deployed in private subnets for data persistence.

| Configuration | Value |
|---------------|-------|
| Engine | MySQL 8.4.8 |
| Instance Class | db.t4g.micro |
| Storage | 20 GB gp3 |
| Multi-AZ | Disabled (development) |
| Public Access | False |
| Security Group | Backend SG (port 3306) |

**Key Features:**
- Deployed across all 3 private subnets
- No public internet access
- Credentials managed via Terraform variables

### ElastiCache (Memcached)

An in-memory caching layer deployed in private subnets to reduce database load and improve application performance.

| Configuration | Value |
|---------------|-------|
| Engine | Memcached 1.6.22 |
| Node Type | cache.t4g.micro |
| Cache Nodes | 1 |
| Port | 11211 |
| Security Group | Backend SG (port 11211) |

**Key Features:**
- Reduces database query load
- Improves response times for frequently accessed data
- Deployed in private subnets

### Amazon MQ (RabbitMQ)

A managed message broker service for asynchronous communication between application components.

| Configuration | Value |
|---------------|-------|
| Engine | RabbitMQ 4.2 |
| Instance Type | mq.m7g.medium |
| Deployment | Single subnet (private) |
| Security Group | Backend SG (port 5672) |

**Key Features:**
- Enables decoupled application architecture
- Handles asynchronous message processing
- Deployed in private subnet for security

## Database Initialization via Bastion Host

The Bastion host serves a critical role beyond just SSH access — it automatically initializes the MySQL database with the required schema and seed data during the initial provisioning.

### Why Database Initialization is Needed

When the RDS instance is first created, it contains no tables or data. The Java/Tomcat application expects a specific database schema with initial seed data to function properly. The bastion host bridges this gap by running an initialization script that sets up the database before the application attempts to connect.

### Initialization Process

The bastion host automatically executes the following steps during Terraform provisioning:

1. **Package Installation:** Installs git and mysql-client tools on the bastion host
2. **Repository Clone:** Downloads the vprofile-project repository containing the database dump file
3. **Database Connection:** Connects to the RDS instance using credentials from Terraform variables
4. **Schema Loading:** Executes the SQL dump file to create tables and load initial seed data

### What the Script Does

The initialization script connects to MySQL and loads a pre-configured database dump that contains:
- Database schema (table structures, relationships, indexes)
- Initial seed data (default users, reference data, test records)
- Any stored procedures or functions required by the application

### Security Considerations

- The bastion host only has temporary database access during initialization
- Credentials are passed securely via Terraform variables (not hardcoded)
- The connection uses SSL disabled mode for simplicity in this development setup
- The bastion host sits in a public subnet but is restricted to specific admin IPs for SSH

### Service Communication Matrix

| Source | Destination | Port | Purpose |
|--------|-------------|------|---------|
| Beanstalk (Java App) | RDS (MySQL) | 3306 | Data persistence |
| Beanstalk (Java App) | ElastiCache (Memcached) | 11211 | Caching layer |
| Beanstalk (Java App) | Amazon MQ (RabbitMQ) | 5672 | Message queuing |
| Bastion | RDS (MySQL) | 3306 | Database initialization (during provisioning) |
| Internet → ALB → Beanstalk | Java App | 80/443 → 8080 | Web application access |

## Security Groups Design

The project implements a layered security group architecture following the principle of least privilege.

### Security Groups Overview

| Security Group | Purpose | Inbound Rules | Outbound Rules |
|----------------|---------|---------------|----------------|
| **Bastion SG** | SSH gateway + DB initialization | SSH (22) from admin IP | All traffic (IPv4 + IPv6) |
| **ALB SG** | Application Load Balancer | HTTP (80) + HTTPS (443) from internet (IPv4 + IPv6) | All traffic |
| **Beanstalk SG** | Java/Tomcat application instances | Port 8080 + 80 from ALB, SSH (22) from Bastion | All traffic |
| **Backend SG** | Database and cache services | MySQL (3306) from Beanstalk + Bastion, Memcached (11211) from Beanstalk, RabbitMQ (5672) from Beanstalk, All ports from itself | Default (AWS allows all) |

### Traffic Flow

```
Internet → ALB (80/443) → Beanstalk (8080) → Backend Services
                              (Java/Tomcat)
                                    ↓
                    ┌───────────────┼───────────────┐
                    ↓               ↓               ↓
                  MySQL          Memcached      RabbitMQ
                 (3306)          (11211)         (5672)
                    
Bastion Host ─────→ Beanstalk (SSH:22) [Debug only]
     ↓
  MySQL (3306) ← Database initialization (one-time during provisioning)
```

### Security Highlights

- No direct database exposure to the internet
- Security group referencing instead of CIDR for internal traffic
- Bastion host restricts SSH to specific admin IP
- Java/Tomcat application only accepts traffic from load balancer
- Backend services only accept traffic from application tier and bastion
- RDS, ElastiCache, and Amazon MQ all deployed in private subnets
- Beanstalk instances have no public IP addresses
- Rolling updates with health checks for zero-downtime deployments
- IMDSv1 disabled on Beanstalk instances (security hardening)

## Prerequisites

- Terraform >= 1.10.2
- AWS CLI configured
- AWS account
- SSH key pair for EC2 access

## Setup

```bash
# Load environment variables
source .env

# Initialize Terraform
terraform init

# Format and validate configuration
terraform fmt
terraform validate

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

## Cleanup

```bash
terraform destroy
```

## Technologies

- Terraform
- AWS (VPC, EC2, S3, DynamoDB, RDS, ElastiCache, MQ, Elastic Beanstalk, ALB)
- Java / Tomcat 10
- MySQL 8.4.8
- Memcached 1.6.22
- RabbitMQ 4.2
```

The README now has:
- **No code blocks** for the database initialization (just explanation)
- Clear description of **why** the bastion host initializes the database
- Step-by-step **what the script does** without showing the actual commands
- Security considerations for the initialization process