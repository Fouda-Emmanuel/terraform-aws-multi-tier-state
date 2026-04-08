# terraform-aws-multi-tier-state

## Cloud State with Terraform

This project provisions a complete multi-tier infrastructure on AWS using Terraform, with a focus on maintaining centralized state management.

## Problem

Manual infrastructure management leads to:
- Non-repeatable setups across dev, QA, staging, and production
- No change tracking (who made what, when)
- Human errors causing broken infrastructure or security exposure
- Time-consuming documentation
- Configuration drift

## Solution

Infrastructure as Code with Terraform + centralized state management in S3.

## 🏗️ Architecture

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
- Bastion host for private subnet access
- RDS (MySQL) in private subnets
- Elastic Cache in private subnets
- Amazon MQ (ActiveMQ) in private subnets
- Elastic Beanstalk (load balancer in public subnets, instances in private subnets)
- Security groups and key pairs

## What Gets Deployed

| Component | Location |
|-----------|----------|
| VPC | Custom CIDR |
| Public Subnets (3 AZs) | Connected to Internet Gateway |
| Private Subnets (3 AZs) | Connected to NAT Gateway |
| Bastion Host | Public subnet for SSH access |
| RDS | Private subnets |
| Elastic Cache | Private subnets |
| Amazon MQ | Private subnets |
| Elastic Beanstalk | LB in public, instances in private |

## Prerequisites

- Terraform >= 1.10.2
- AWS CLI configured
- AWS account

## Setup

```bash
# Initialize Terraform
terraform init

# Review and apply
terraform plan
terraform apply
```

## Cleanup

```bash
terraform destroy
```

## Technologies

- Terraform
- AWS (VPC, EC2, S3, DynamoDB, RDS, ElastiCache, MQ, Elastic Beanstalk)
