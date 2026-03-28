# Architecture Documentation (arc42)

**About arc42**: This document follows the arc42 template for architecture documentation, created by Dr. Gernot Starke and Dr. Peter Hruschka. Arc42 is widely recognized as a pragmatic, practical, and proven approach to documenting software and system architectures.

---

## Table of Contents

1. [Introduction and Goals](#1-introduction-and-goals)
2. [Architecture Constraints](#2-architecture-constraints)
3. [System Scope and Context](#3-system-scope-and-context)
4. [Solution Strategy](#4-solution-strategy)
5. [Building Block View](#5-building-block-view)
6. [Runtime View](#6-runtime-view)
7. [Deployment View](#7-deployment-view)
8. [Cross-cutting Concepts](#8-cross-cutting-concepts)
9. [Architecture Decisions](#9-architecture-decisions)
10. [Quality Requirements](#10-quality-requirements)
11. [Risks and Technical Debt](#11-risks-and-technical-debt)
12. [Glossary](#12-glossary)

---

## 1. Introduction and Goals

### 1.1 Requirements Overview

**My Terraform Lab** is a AWS infrastructure platform designed to:

- Demonstrate modern cloud-native architecture patterns and Infrastructure as Code best practices
- Provide a secure, cost-optimized platform for running containerized workloads
- Showcase Zero Trust networking principles using Cloudflare Tunnel and Access
- Enable multi-environment deployments (dev/test/prod) with minimal configuration drift
- Serve as a reference implementation for Terraform-managed AWS infrastructure

### 1.2 Quality Goals

| Priority | Quality Goal | Motivation |
|----------|-------------|------------|
| 1 | **Security** | Zero Trust architecture, encryption at rest, least privilege IAM, security scanning |
| 2 | **Cost Efficiency** | Scale-to-zero capabilities, no NAT Gateway, no load balancers, IPv6 egress |
| 3 | **Maintainability** | Modular design, clear dependencies, comprehensive documentation |
| 4 | **Reliability** | Multi-AZ deployment, automated backups, health checks, auto-recovery |
| 5 | **Observability** | Container Insights, CloudWatch Logs, metrics and monitoring |

### 1.3 Stakeholders

| Role | Expectations | Concerns |
|------|-------------|----------|
| **Platform Engineers** | Reliable infrastructure, easy to operate and troubleshoot | Complexity, operational overhead |
| **Security Team** | Zero Trust access, encryption, compliance, audit trails | Security vulnerabilities, unauthorized access |
| **Finance/FinOps** | Cost optimization, resource efficiency | Unnecessary costs, idle resources |
| **Developers** | Easy service deployment, observability, development environments | Deployment complexity, debugging difficulty |
| **DevOps/SRE** | Automated deployments, CI/CD integration, infrastructure testing | Manual processes, state drift |

---

## 2. Architecture Constraints

### 2.1 Technical Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **TC-1: AWS Platform** | Infrastructure must run on AWS | Limits multi-cloud portability |
| **TC-2: Terraform** | IaC tool is Terraform >= 1.11.0 | Team must maintain Terraform expertise |
| **TC-3: HCP Terraform Cloud** | Remote state backend | Requires HCP Terraform Cloud subscription |
| **TC-4: ECS Fargate** | Serverless containers only, no EC2-based ECS | Limited control over underlying infrastructure |
| **TC-5: IPv6 Requirement** | Dual-stack networking mandatory | Adds complexity to network design |

### 2.2 Organizational Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **OC-1: Multi-Environment** | Support dev/test/prod environments | Workspace-based separation required |
| **OC-2: Cost Limits** | Minimize AWS costs | Aggressive auto-scaling, no NAT Gateway |
| **OC-3: Security Policies** | Zero Trust architecture required | Cloudflare integration mandatory |
| **OC-4: GitOps Workflow** | Infrastructure changes via Git | CI/CD pipeline enforcement |

### 2.3 Conventions

| Convention | Description |
|------------|-------------|
| **Code Style** | Terraform standard formatting (terraform fmt) |
| **Naming** | Resource names: `{project}-{component}-{environment}` |
| **Tagging** | Mandatory tags: Environment, Terraform_Workspace, Origin_Repo |
| **Documentation** | README in every module, inline comments for complex logic |

---

## 3. System Scope and Context

### 3.1 Business Context

```
┌─────────────┐
│   Internet  │
│    Users    │
└──────┬──────┘
       │
       ↓
┌──────────────────────────────────────────┐
│      Cloudflare Edge Network             │
│  ┌────────────────────────────────────┐  │
│  │   Zero Trust Access Policies       │  │
│  │   - Identity verification          │  │
│  │   - MFA enforcement                │  │
│  │   - Device posture checks          │  │
│  └────────────────────────────────────┘  │
└──────────────┬───────────────────────────┘
               │
               ↓
┌──────────────────────────────────────────┐
│      My Terraform Lab (AWS)              │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Cloudflare Tunnel (ECS)           │ │
│  └────────────┬───────────────────────┘ │
│               │                          │
│               ↓                          │
│  ┌────────────────────────────────────┐ │
│  │  Application Services (ECS)        │ │
│  │  - ecs-web-poc                     │ │
│  │  - ecs-mgt                         │ │
│  └────────────────────────────────────┘ │
│                                          │
└──────────────────────────────────────────┘
```

**External Entities:**

1. **End Users**: Access web applications through Cloudflare's edge network
2. **Administrators**: Manage infrastructure via Terraform and AWS CLI
3. **Cloudflare Platform**: Provides Zero Trust access and tunnel connectivity
4. **HCP Terraform Cloud**: Stores remote state and manages workspaces
5. **GitHub**: Source control and CI/CD trigger

### 3.2 Technical Context

**Interfaces and Protocols:**

| Interface | Protocol/Technology | Purpose |
|-----------|-------------------|---------|
| **User → Cloudflare** | HTTPS (TCP/443) | Secure web access |
| **Cloudflare Tunnel → ECS** | QUIC/HTTP/2 | Tunnel protocol |
| **ECS Services** | Service Discovery (AWS Cloud Map) | Inter-service communication |
| **Terraform → AWS** | AWS API (HTTPS) | Infrastructure provisioning |
| **Terraform → HCP TFC** | Terraform Cloud API | State management |
| **ECS → CloudWatch** | CloudWatch Agent | Logs and metrics |
| **ECS → Parameter Store** | AWS API | Secrets retrieval |

---

## 4. Solution Strategy

### 4.1 Technology Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| **ECS Fargate** | Serverless, no cluster management, pay-per-use | EKS (too complex), EC2-based ECS (maintenance overhead) |
| **Cloudflare Tunnel** | Zero Trust, no load balancer costs, built-in DDoS protection | ALB/NLB (higher cost), API Gateway (limited features) |
| **IPv6 for Egress** | No NAT Gateway costs, AWS best practice | NAT Gateway (expensive), NAT Instance (maintenance) |
| **HCP Terraform Cloud** | Remote state, team collaboration, workspace management | S3 backend (manual locking), Terraform Enterprise (cost) |
| **AWS Cloud Map** | Native service discovery, DNS-based | Consul (external dependency), custom DNS |

### 4.2 Top-level Decomposition

The system is decomposed into layers following a foundation-first approach:

1. **Network Layer** (`network-core`): VPC, subnets, gateways, service discovery
2. **Platform Layer** (`ecs-cluster`, `storage-persistent`): Shared resources
3. **Ingress Layer** (`ecs-cloudflared-tunnel`): Zero Trust access gateway
4. **Application Layer** (`ecs-mgt`, `ecs-web-poc`): Business workloads
5. **Supporting Layer** (`mgt-services`): Traditional infrastructure for management

### 4.3 Approach to Quality Goals

| Quality Goal | Approach |
|--------------|----------|
| **Security** | Zero Trust networking, encryption at rest, least privilege IAM, security scanning in CI/CD |
| **Cost Efficiency** | Scale-to-zero, no NAT/LB, IPv6 egress, lifecycle policies, aggressive auto-scaling |
| **Maintainability** | Modular Terraform, clear dependencies, comprehensive docs, testing |
| **Reliability** | Multi-AZ, health checks, auto-recovery, automated backups |
| **Observability** | Container Insights, structured logging, CloudWatch metrics |

---

## 5. Building Block View

### 5.1 Level 0: System Context

See [Section 3.1 Business Context](#31-business-context)

### 5.2 Level 1: Infrastructure Modules

```
┌────────────────────────────────────────────────────────────┐
│                    My Terraform Lab                        │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Foundation Layer                          │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │  network-core                                  │  │  │
│  │  │  - VPC (dual-stack IPv4/IPv6)                  │  │  │
│  │  │  - Public/Private Subnets (multi-AZ)           │  │  │
│  │  │  - Internet/Egress-Only Gateways               │  │  │
│  │  │  - AWS Cloud Map (Service Discovery)           │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                      │
│  ┌──────────────────┴───────────────────────────────────┐  │
│  │            Platform Layer                            │  │
│  │  ┌─────────────────────┐  ┌─────────────────────┐    │  │
│  │  │  ecs-cluster        │  │ storage-persistent  │    │  │
│  │  │  - ECS Fargate      │  │ - AWS EFS           │    │  │
│  │  │  - Capacity Provider│  │ - Encryption        │    │  │
│  │  │  - IAM Roles        │  │ - Lifecycle Policies│    │  │
│  │  └─────────────────────┘  └─────────────────────┘    │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                      │
│  ┌──────────────────┴───────────────────────────────────┐  │
│  │            Ingress Layer                             │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │  ecs-cloudflared-tunnel                        │  │  │
│  │  │  - Cloudflare Tunnel Container                 │  │  │
│  │  │  - Auto-scaling (0-2)                          │  │  │
│  │  │  - Ingress Security Group                      │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                      │
│  ┌──────────────────┴───────────────────────────────────┐  │
│  │            Application Layer                         │  │
│  │  ┌─────────────────────┐  ┌─────────────────────┐    │  │
│  │  │  ecs-mgt            │  │  ecs-web-poc        │    │  │
│  │  │  - Alpine Container │  │  - Nginx Container  │    │  │
│  │  │  - ECS Exec Enabled │  │  - CF Access Policy │    │  │
│  │  │  - On-demand (0)    │  │  - Auto-scale (0-1) │    │  │
│  │  └─────────────────────┘  └─────────────────────┘    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Supporting Layer                          │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │  mgt-services (EC2)                            │  │  │
│  │  │  - Bastion Host (public)                       │  │  │
│  │  │  - Management Instance (private)               │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

### 5.3 Level 2: Module Details

#### 5.3.1 network-core Module

**Responsibility**: Provides foundational networking infrastructure for all services.

**Contained Building Blocks**:
- VPC with dual-stack CIDR blocks
- Public subnets (2+ across AZs) with IPv4 + IPv6 routing
- Private subnets (2+ across AZs) with IPv6-only egress
- Internet Gateway (public IPv4/IPv6 egress)
- Egress-Only Internet Gateway (private IPv6 egress)
- Route tables (public and private)
- AWS Cloud Map private DNS namespace

**Interfaces**:
- Outputs: VPC ID, subnet IDs, Cloud Map namespace ID
- Consumed by: All other modules via HCP Terraform remote state

**Quality Attributes**:
- High Availability: Multi-AZ subnet distribution
- Cost Efficiency: No NAT Gateway, IPv6 for egress
- Security: Network isolation via subnet types

#### 5.3.2 ecs-cluster Module

**Responsibility**: Provides shared ECS cluster for containerized workloads.

**Contained Building Blocks**:
- ECS Cluster with Fargate capacity providers
- Container Insights configuration
- IAM Task Execution Role with policies for:
  - SSM Parameter Store (secrets)
  - CloudWatch Logs
  - ECS Exec (interactive sessions)

**Interfaces**:
- Inputs: VPC ID (from network-core)
- Outputs: Cluster ARN/ID, Task Execution Role ARN
- Consumed by: All ECS service modules

**Quality Attributes**:
- Observability: Container Insights enabled
- Security: Separate task execution and task roles
- Scalability: Fargate capacity on-demand

#### 5.3.3 ecs-cloudflared-tunnel Module

**Responsibility**: Provides Zero Trust ingress to private ECS services.

**Contained Building Blocks**:
- ECS Task Definition (Cloudflared container)
- ECS Service (0-2 instances, auto-scaling)
- Security Group (tunnel ingress control)
- CloudWatch Log Group
- Cloudflare Tunnel configuration (via Terraform)
- SSM Parameter (tunnel credentials)

**Interfaces**:
- Inputs: Cluster ARN, subnets, service discovery namespace
- Outputs: Tunnel ID, Security Group ID
- Consumed by: Application services (ecs-web-poc, ecs-mgt)

**Quality Attributes**:
- Security: Zero Trust access, no public IPs on apps
- Cost Efficiency: Scales to 0 when idle
- Reliability: Auto-scaling based on CPU

#### 5.3.4 ecs-web-poc Module

**Responsibility**: Demonstrates complete application deployment pattern.

**Contained Building Blocks**:
- ECS Task Definition (Nginx container)
- ECS Service (0-1 instances, auto-scaling)
- Security Group (ingress from tunnel only)
- Service Discovery registration
- CloudWatch Log Group
- Cloudflare Access Application
- Cloudflare Access Policy (identity-based)
- Cloudflare DNS record (CNAME to tunnel)
- Auto-scaling policies (scale-down on idle)

**Interfaces**:
- Inputs: Cluster, subnets, tunnel SG, service discovery
- Outputs: Service name, CloudWatch log group
- Accessed by: End users via Cloudflare

**Quality Attributes**:
- Security: Private subnet, identity-aware access
- Cost Efficiency: Scales to 0 after 2 hours idle
- Observability: CloudWatch Logs integration

#### 5.3.5 ecs-mgt Module

**Responsibility**: On-demand management container for operational tasks.

**Contained Building Blocks**:
- ECS Task Definition (Alpine + sleep)
- ECS Service (desired count: 0)
- Security Group (SSH from tunnel)
- Service Discovery registration
- CloudWatch Log Group
- ECS Exec enabled

**Interfaces**:
- Inputs: Cluster, subnets, tunnel SG
- Outputs: Service name
- Accessed by: Administrators via ECS Exec

**Quality Attributes**:
- Cost Efficiency: Default 0 instances (on-demand)
- Security: No public IP, ECS Exec for access
- Flexibility: Can be scaled up on-demand

---

## 6. Runtime View

### 6.1 Scenario 1: User Accesses Web Application

**Preconditions**: ecs-web-poc service is running (count > 0)

```
┌──────┐                ┌───────────┐              ┌──────────┐              ┌────────────┐
│ User │                │ Cloudflare│              │ CF Tunnel│              │ ecs-web-poc│
└──┬───┘                │   Edge    │              │  (ECS)   │              │   (ECS)    │
   │                    └─────┬─────┘              └────┬─────┘              └──────┬─────┘
   │                          │                         │                           │
   │  1. HTTPS Request        │                         │                           │
   │─────────────────────────>│                         │                           │
   │                          │                         │                           │
   │  2. Identity Check       │                         │                           │
   │  (Access Policy)         │                         │                           │
   │<─────────────────────────│                         │                           │
   │                          │                         │                           │
   │  3. Forward via Tunnel   │                         │                           │
   │                          │────────────────────────>│                           │
   │                          │                         │                           │
   │                          │                         │  4. HTTP Request          │
   │                          │                         │──────────────────────────>│
   │                          │                         │                           │
   │                          │                         │  5. Response              │
   │                          │                         │<──────────────────────────│
   │                          │                         │                           │
   │  6. Response via Tunnel  │                         │                           │
   │                          │<────────────────────────│                           │
   │                          │                         │                           │
   │  7. HTTPS Response       │                         │                           │
   │<─────────────────────────│                         │                           │
   │                          │                         │                           │
```

**Steps**:
1. User sends HTTPS request to application domain
2. Cloudflare validates user identity against Access Policy (MFA, device posture)
3. If authorized, request forwarded through secure tunnel
4. Tunnel forwards to ecs-web-poc via Service Discovery DNS
5. Nginx serves response
6. Response returned through tunnel
7. Cloudflare delivers response to user

### 6.2 Scenario 2: Administrator Accesses Management Container

**Preconditions**: ecs-mgt service scaled to 0 (default state)

```
┌───────┐            ┌─────────┐             ┌───────────┐            ┌─────────┐
│ Admin │            │ AWS CLI │             │ ECS Agent │            │ ecs-mgt │
└───┬───┘            └────┬────┘             └─────┬─────┘            └────┬────┘
    │                     │                        │                       │
    │  1. Scale Up        │                        │                       │
    │────────────────────>│                        │                       │
    │                     │                        │                       │
    │                     │  2. Update Service     │                       │
    │                     │───────────────────────>│                       │
    │                     │                        │                       │
    │                     │                        │  3. Start Task        │
    │                     │                        │──────────────────────>│
    │                     │                        │                       │
    │                     │                        │  4. Running           │
    │                     │                        │<──────────────────────│
    │                     │                        │                       │
    │  5. ECS Exec        │                        │                       │
    │────────────────────>│                        │                       │
    │                     │                        │                       │
    │                     │  6. Start Session      │                       │
    │                     │───────────────────────>│                       │
    │                     │                        │                       │
    │                     │                        │  7. SSM Session       │
    │                     │                        │──────────────────────>│
    │                     │                        │                       │
    │  8. Interactive Shell                        │                       │
    │<────────────────────────────────────────────────────────────────────>│
    │                     │                        │                       │
```

**Steps**:
1. Admin runs: `./scripts/ecssvc.sh scale-up mytflab-ecs-mgt 1`
2. AWS ECS updates service desired count
3. ECS schedules and starts Fargate task
4. Task enters RUNNING state
5. Admin runs: `./scripts/enter-ecsshell.sh`
6. Script initiates ECS Exec session via SSM Session Manager
7. SSM agent connects to container
8. Admin has interactive shell access

### 6.3 Scenario 3: Auto-scaling Scale-Down

**Preconditions**: ecs-web-poc has been idle (CPU ≤ 0.6%) for 2 hours

```
┌──────────────┐        ┌───────────────┐        ┌──────────────┐
│  CloudWatch  │        │  Auto Scaling │        │  ECS Service │
│   Alarms     │        │    Policy     │        │ ecs-web-poc  │
└──────┬───────┘        └───────┬───────┘        └──────┬───────┘
       │                        │                       │
       │  1. CPU ≤ 0.6%         │                       │
       │    for 2 hours         │                       │
       │────────────────────────>│                       │
       │                        │                       │
       │                        │  2. Scale Down        │
       │                        │──────────────────────>│
       │                        │                       │
       │                        │                       │  3. Stop Task
       │                        │                       │────────┐
       │                        │                       │        │
       │                        │                       │<───────┘
       │                        │                       │
       │                        │  4. Confirm           │
       │                        │<──────────────────────│
       │                        │                       │
```

**Steps**:
1. CloudWatch monitors CPU metrics, detects sustained low usage (≤0.6% for 2 hours)
2. CloudWatch triggers scale-down policy
3. ECS updates service desired count to 0
4. Running tasks gracefully stopped
5. No charges for idle service

---

## 7. Deployment View

### 7.1 AWS Region Deployment

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         AWS Region (us-east-1)                          │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                    VPC (10.0.0.0/16 + IPv6)                        │ │
│  │                                                                    │ │
│  │  ┌──────────────────────────────┐  ┌──────────────────────────┐    │ │
│  │  │     Availability Zone A      │  │  Availability Zone B     │    │ │
│  │  │                              │  │                          │    │ │
│  │  │  ┌──────────────────────┐    │  │  ┌──────────────────┐    │    │ │
│  │  │  │  Public Subnet A     │    │  │  │  Public Subnet B │    │    │ │
│  │  │  │  10.0.1.0/24         │    │  │  │  10.0.2.0/24     │    │    │ │
│  │  │  │  ┌────────────────┐  │    │  │  │  ┌────────────┐  │    │    │ │
│  │  │  │  │ Bastion Host   │  │    │  │  │  │            │  │    │    │ │
│  │  │  │  │ (EC2)          │  │    │  │  │  │            │  │    │    │ │
│  │  │  │  └────────────────┘  │    │  │  │  └────────────┘  │    │    │ │
│  │  │  │  ┌────────────────┐  │    │  │  │  ┌────────────┐  │    │    │ │
│  │  │  │  │ CF Tunnel      │  │    │  │  │  │ CF Tunnel  │  │    │    │ │
│  │  │  │  │ (ECS Fargate)  │  │    │  │  │  │ (Fargate)  │  │    │    │ │
│  │  │  │  └────────────────┘  │    │  │  │  └────────────┘  │    │    │ │
│  │  │  └──────────────────────┘    │  │  └──────────────────┘    │    │ │
│  │  │                              │  │                          │    │ │
│  │  │  ┌──────────────────────┐    │  │  ┌──────────────────┐    │    │ │
│  │  │  │  Private Subnet A    │    │  │  │  Private Subnet B│    │    │ │
│  │  │  │  10.0.11.0/24        │    │  │  │  10.0.12.0/24    │    │    │ │
│  │  │  │  ┌────────────────┐  │    │  │  │  ┌────────────┐  │    │    │ │
│  │  │  │  │ ecs-web-poc    │  │    │  │  │  │ ecs-web-poc│  │    │    │ │
│  │  │  │  │ (ECS Fargate)  │  │    │  │  │  │ (Fargate)  │  │    │    │ │
│  │  │  │  └────────────────┘  │    │  │  │  └────────────┘  │    │    │ │
│  │  │  │  ┌────────────────┐  │    │  │  │  ┌────────────┐  │    │    │ │
│  │  │  │  │ ecs-mgt        │  │    │  │  │  │ ecs-mgt    │  │    │    │ │
│  │  │  │  │ (ECS Fargate)  │  │    │  │  │  │ (Fargate)  │  │    │    │ │
│  │  │  │  └────────────────┘  │    │  │  │  └────────────┘  │    │    │ │
│  │  │  │  ┌────────────────┐  │    │  │  │  ┌────────────┐  │    │    │ │
│  │  │  │  │ Mgt Instance   │  │    │  │  │  │            │  │    │    │ │
│  │  │  │  │ (EC2)          │  │    │  │  │  │            │  │    │    │ │
│  │  │  │  └────────────────┘  │    │  │  │  └────────────┘  │    │    │ │
│  │  │  └──────────────────────┘    │  │  └──────────────────┘    │    │ │
│  │  │                              │  │                          │    │ │
│  │  │  ┌──────────────────────┐    │  │  ┌──────────────────┐    │    │ │
│  │  │  │  Storage Subnet A    │    │  │  │  Storage Subnet B│    │    │ │
│  │  │  │  (EFS Mount Target)  │    │  │  │ (EFS Mount)      │    │    │ │
│  │  │  └──────────────────────┘    │  │  └──────────────────┘    │    │ │
│  │  └──────────────────────────────┘  └──────────────────────────┘    │ │
│  │                                                                    │ │
│  │  ┌──────────────────────────────────────────────────────────────┐  │ │
│  │  │               AWS Cloud Map (Service Discovery)              │  │ │
│  │  │               Namespace: {env}.mytflab.local                 │  │ │
│  │  └──────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                      Managed Services                              │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │ │
│  │  │ CloudWatch   │  │  Parameter   │  │  ECS (Control Plane)     │  │ │
│  │  │ Logs/Metrics │  │  Store (SSM) │  │  - Fargate Scheduler     │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘

External Services:
┌────────────────┐     ┌──────────────────┐     ┌────────────────────┐
│ Cloudflare     │     │ HCP Terraform    │     │ GitHub             │
│ - Tunnel       │     │ Cloud            │     │ - Source Control   │
│ - Access       │     │ - Remote State   │     │ - CI/CD Triggers   │
│ - DNS          │     │ - Workspaces     │     │                    │
└────────────────┘     └──────────────────┘     └────────────────────┘
```

### 7.2 Infrastructure as Code Deployment

**Deployment Process:**

1. **Code Change**: Developer pushes to Git branch
2. **CI Validation**: GitHub Actions runs terraform fmt, tfsec, checkov
3. **Manual Review**: Pull request reviewed and approved
4. **HCP Terraform Trigger**: Merge to main triggers workspace run
5. **Terraform Plan**: HCP TFC generates and displays plan
6. **Manual Approval**: Operator reviews and approves plan
7. **Terraform Apply**: HCP TFC applies changes to AWS
8. **State Update**: Remote state updated in HCP Terraform Cloud

### 7.3 Deployment Dependencies

**Module Deployment Order:**

```
1. network-core       (no dependencies)
   ↓
2. ecs-cluster        (depends on: network-core)
   ↓
3. storage-persistent (depends on: network-core)
   ↓
4. ecs-cloudflared-tunnel (depends on: network-core, ecs-cluster)
   ↓
5. ecs-mgt           (depends on: network-core, ecs-cluster, ecs-cloudflared-tunnel)
6. ecs-web-poc       (depends on: network-core, ecs-cluster, ecs-cloudflared-tunnel)
7. mgt-services      (depends on: network-core, storage-persistent)
```

---

## 8. Cross-cutting Concepts

### 8.1 Security Concepts

#### 8.1.1 Zero Trust Architecture

**Principle**: Never trust, always verify

**Implementation**:
- No public IPs on application services
- All ingress through Cloudflare Tunnel
- Identity verification at edge (Cloudflare Access)
- MFA enforcement
- Device posture checks
- Session duration limits

#### 8.1.2 Encryption

**At Rest**:
- EFS: AES-256 encryption
- EBS: AWS-managed keys
- SSM Parameter Store: KMS encryption
- CloudWatch Logs: Server-side encryption

**In Transit**:
- HTTPS/TLS 1.3 for all external communication
- Cloudflare Tunnel: QUIC protocol (encrypted)
- AWS API calls: TLS

#### 8.1.3 Least Privilege IAM

**Pattern**: Grant minimum permissions required

**Implementation**:
- Separate task execution role and task role
- Resource-based policies (not *:*)
- Condition keys for additional restrictions
- Regular policy review and refinement

#### 8.1.4 Security Scanning

**CI/CD Integration**:
- `tfsec`: Terraform-specific security checks
- `checkov`: IaC security and compliance scanning
- `detect-secrets`: Pre-commit hook for secret detection
- GitHub Actions: Automated on every PR

### 8.2 Operational Concepts

#### 8.2.1 Observability

**Three Pillars**:

1. **Logs**: CloudWatch Logs
   - Structured logging per service: `/ecs/{service-name}`
   - Retention: 30 days default
   - Query via CloudWatch Insights

2. **Metrics**: CloudWatch Metrics
   - Container Insights: CPU, memory, network
   - Custom metrics: Application-specific
   - Auto-scaling triggers

3. **Traces**: (Future enhancement)
   - X-Ray integration potential
   - Distributed tracing across services

#### 8.2.2 High Availability

**Patterns**:
- Multi-AZ subnet distribution
- ECS service spread across AZs
- Health checks and auto-recovery
- Cloudflare global edge network (DDoS protection)

#### 8.2.3 Disaster Recovery

**Backup Strategy**:
- EFS: Automated backups enabled (AWS Backup)
- Terraform State: HCP Terraform Cloud versioning
- Infrastructure: Reproducible via Terraform

**Recovery**:
- RTO (Recovery Time Objective): < 1 hour
- RPO (Recovery Point Objective): 24 hours (EFS backup frequency)

### 8.3 Development Concepts

#### 8.3.1 Infrastructure Testing

**Approaches**:
1. **Terraform Native Tests**: Located in `network-core/tests/`
2. **CI/CD Validation**: Format, security, syntax checks
3. **Manual Testing**: Deploy to dev environment first

#### 8.3.2 Multi-Environment Strategy

**Workspace Pattern**:
- Naming: `{base_name}-{environment}`
- Environment extraction: Regex `(prd|tst|dev)$`
- Separate workspaces per environment
- Consistent tagging across environments

#### 8.3.3 Module Reusability

**Standards**:
- Self-contained modules with clear interfaces
- Variables for customization
- Outputs for downstream consumption
- Documentation in each module

### 8.4 Cost Management

#### 8.4.1 Cost Optimization Patterns

**Scale-to-Zero**:
- ecs-mgt: Default desired count 0
- ecs-web-poc: Auto-scales to 0 after idle period
- ecs-cloudflared-tunnel: Minimum 0 instances

**Infrastructure Savings**:
- No NAT Gateway (IPv6 egress)
- No Load Balancers (Cloudflare Tunnel)
- ECS Fargate (pay-per-use, no idle instances)
- EFS lifecycle policies (IA transition)

#### 8.4.2 Cost Monitoring

**Tagging Strategy**:
- Environment: dev/tst/prd
- Terraform_Workspace: Workspace name
- Origin_Repo: my-terraform-lab
- Enables cost allocation and tracking

---

## 9. Architecture Decisions

### ADR-001: Use Cloudflare Tunnel Instead of AWS Load Balancers

**Status**: Accepted

**Context**: Need secure ingress to private ECS services with identity-aware access control.

**Decision**: Use Cloudflare Tunnel + Access instead of ALB/NLB.

**Rationale**:
- Cost: ALB costs ~$16/month per service vs Cloudflare free tier
- Zero Trust: Built-in identity verification, MFA, device posture
- DDoS Protection: Cloudflare global edge network
- No public IPs: Services remain fully private
- Simplified architecture: No need for certificate management

**Consequences**:
- (+) Significant cost savings
- (+) Enhanced security posture
- (+) Built-in DDoS protection
- (-) Dependency on external service (Cloudflare)
- (-) Latency: Additional hop through Cloudflare edge

---

### ADR-002: Use IPv6 for Private Subnet Egress

**Status**: Accepted

**Context**: Private subnets need outbound internet access for updates, API calls.

**Decision**: Use IPv6 + Egress-Only Internet Gateway instead of NAT Gateway.

**Rationale**:
- Cost: NAT Gateway costs ~$32/month vs EIGW free
- AWS best practice: Encourage IPv6 adoption
- Performance: Direct IPv6 routing, no NAT overhead
- Simplicity: No need for NAT instance management

**Consequences**:
- (+) ~$32/month savings per AZ
- (+) Better performance (no NAT)
- (+) Aligns with AWS modern networking
- (-) Requires IPv6 support in downstream services
- (-) IPv6 complexity for operators unfamiliar with dual-stack

---

### ADR-003: Use HCP Terraform Cloud for State Management

**Status**: Accepted

**Context**: Need remote state backend with locking and team collaboration.

**Decision**: Use HCP Terraform Cloud instead of S3 backend.

**Rationale**:
- Team collaboration: Multiple operators, shared state
- Workspace management: Easy environment separation
- State locking: Built-in, no DynamoDB required
- Audit trail: State version history
- Remote execution: Optional remote runs
- Cost: Free tier sufficient for small teams

**Consequences**:
- (+) Better team collaboration
- (+) Built-in locking and versioning
- (+) Workspace-based environments
- (-) Dependency on external service
- (-) Requires HCP TFC account

---

### ADR-004: Use ECS Fargate for All Container Workloads

**Status**: Accepted

**Context**: Need to run containerized workloads on AWS.

**Decision**: Use ECS Fargate exclusively, no EC2-based ECS or EKS.

**Rationale**:
- Serverless: No cluster management overhead
- Pay-per-use: No idle EC2 instance costs
- Simplicity: Less complex than EKS
- Security: AWS-managed infrastructure patching
- Scale-to-zero: Full cost optimization

**Consequences**:
- (+) Reduced operational overhead
- (+) Pay-per-use pricing model
- (+) No EC2 instance management
- (-) Higher per-vCPU/GB cost than EC2
- (-) Less control over underlying infrastructure
- (-) Not suitable for GPU or specialized hardware workloads

---

### ADR-005: Use Aggressive Auto-scaling Policies

**Status**: Accepted

**Context**: Minimize costs for infrequently accessed services.

**Decision**: Scale services to 0 after extended idle periods (2+ hours).

**Rationale**:
- Cost optimization: Primary goal of lab environment
- Dev/test workload: Not production-critical
- Fast startup: ECS Fargate tasks start in ~30 seconds
- Minimal user impact: Dev/demo environment

**Consequences**:
- (+) Significant cost savings (60-80% reduction)
- (+) Zero cost for idle services
- (-) Cold start latency for first request
- (-) Not suitable for production workloads
- (-) Requires scale-up for on-demand access

---

## 10. Quality Requirements

### 10.1 Quality Tree

```
Quality
├── Security (Priority 1)
│   ├── Zero Trust Access
│   ├── Encryption at Rest
│   ├── Least Privilege IAM
│   └── Security Scanning (CI/CD)
├── Cost Efficiency (Priority 2)
│   ├── Scale-to-Zero Capability
│   ├── No NAT/LB Costs
│   └── Resource Lifecycle Management
├── Maintainability (Priority 3)
│   ├── Modular Design
│   ├── Clear Documentation
│   └── Automated Testing
├── Reliability (Priority 4)
│   ├── Multi-AZ Deployment
│   ├── Auto-recovery
│   └── Automated Backups
└── Observability (Priority 5)
    ├── Centralized Logging
    ├── Metrics Collection
    └── Service Discovery
```

### 10.2 Quality Scenarios

#### Scenario 1: Security - Unauthorized Access Attempt

**Scenario**: Attacker attempts to access ecs-web-poc without authentication

**Environment**: Production environment, service running

**Stimulus**: HTTP request to application endpoint

**Response**:
1. Request reaches Cloudflare Edge
2. Cloudflare Access evaluates policy
3. No valid identity token found
4. Request redirected to identity provider login
5. Attack attempt logged in Cloudflare

**Measure**: 100% of unauthorized requests blocked at edge

---

#### Scenario 2: Cost Efficiency - Idle Service

**Scenario**: ecs-web-poc has zero traffic for 2+ hours

**Environment**: Development environment

**Stimulus**: CPU ≤ 0.6% for 2 hours

**Response**:
1. CloudWatch alarm triggers
2. Auto-scaling policy executes
3. ECS service scales to 0 tasks
4. No compute charges incurred

**Measure**: Service scales to 0 within 5 minutes of alarm

---

#### Scenario 3: Maintainability - New Service Deployment

**Scenario**: Developer needs to deploy new ECS service

**Environment**: Development environment

**Stimulus**: Copy ecs-web-poc module, customize variables

**Response**:
1. Create new Terraform module based on template
2. Update variables (service name, container image)
3. Reference existing cluster/network outputs
4. Terraform apply

**Measure**: New service deployable in < 30 minutes

---

#### Scenario 4: Reliability - AZ Failure

**Scenario**: AWS Availability Zone becomes unavailable

**Environment**: Production environment, multi-AZ deployment

**Stimulus**: AZ-A network failure

**Response**:
1. ECS detects unhealthy tasks in AZ-A
2. ECS launches replacement tasks in AZ-B
3. Service continues operating
4. CloudWatch alarm notifies operators

**Measure**: Service remains available, <2 minutes of degraded capacity

---

## 11. Risks and Technical Debt

### 11.1 Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **Cloudflare Dependency** | Low | High | Cloudflare has 99.99% uptime SLA; consider implementing direct ALB as backup |
| **IPv6 Compatibility** | Medium | Medium | Test all services for IPv6 support; maintain IPv4 fallback for external APIs |
| **Cold Start Latency** | High | Low | Expected behavior for scale-to-zero; pre-warm services for demos |
| **ECS Exec Failure** | Low | Medium | Maintain bastion host as backup access method |
| **State Lock Contention** | Low | Low | Use HCP TFC runs queue; communicate during deployments |

### 11.2 Technical Debt

| Item | Impact | Effort | Priority |
|------|--------|--------|----------|
| **No Distributed Tracing** | Medium | Medium | Low - Implement X-Ray integration |
| **Manual Secrets Rotation** | Medium | High | Medium - Implement AWS Secrets Manager rotation |
| **Limited Terraform Tests** | Low | Medium | Medium - Expand test coverage beyond network-core |
| **No Cost Alerting** | Low | Low | High - Implement AWS Budgets with SNS notifications |
| **Single Region** | Medium | High | Low - Multi-region adds significant complexity |
| **No Container Vulnerability Scanning** | Medium | Medium | High - Integrate ECR image scanning |

### 11.3 Improvement Opportunities

1. **Observability Enhancements**
   - Add AWS X-Ray for distributed tracing
   - Implement custom CloudWatch dashboards
   - Integrate with Prometheus/Grafana

2. **Automation**
   - Implement GitOps workflow (Atlantis or Terraform Cloud VCS integration)
   - Automated drift detection
   - Scheduled security scanning

3. **Cost Management**
   - AWS Cost Explorer integration
   - Budget alerts via SNS
   - Automated cost reporting

4. **Testing**
   - Expand Terraform test coverage
   - Integration tests for service-to-service communication
   - Chaos engineering experiments

---

## 12. Glossary

| Term | Definition |
|------|------------|
| **AZ (Availability Zone)** | Isolated location within an AWS region with independent infrastructure |
| **Cloudflare Tunnel** | Secure tunnel from Cloudflare edge to private infrastructure without public IPs |
| **ECS (Elastic Container Service)** | AWS container orchestration service |
| **ECS Exec** | Feature enabling interactive shell access to running ECS tasks via SSM |
| **EFS (Elastic File System)** | AWS managed NFS file system with elastic scaling |
| **EIGW (Egress-Only Internet Gateway)** | AWS networking component for IPv6-only outbound internet access |
| **Fargate** | Serverless compute engine for ECS, no cluster management required |
| **HCP Terraform Cloud** | HashiCorp Cloud Platform service for Terraform state management and collaboration |
| **Service Discovery** | AWS Cloud Map integration enabling DNS-based service discovery for ECS |
| **SSM (Systems Manager)** | AWS service providing parameter store, session manager, and other operational tools |
| **Zero Trust** | Security model requiring verification for every access request, regardless of source |
| **Scale-to-Zero** | Auto-scaling pattern where services scale down to 0 instances when idle |
| **Task Definition** | ECS blueprint defining container configuration (image, CPU, memory, etc.) |
| **Task Execution Role** | IAM role used by ECS agent to pull images and retrieve secrets |
| **Task Role** | IAM role assumed by container application for AWS API calls |

---

## Document Information

**Version**: 1.0
**Last Updated**: 2026-02-07
**Authors**: csedm
**Template**: arc42 Version 8.2
**Related Documents**:
- [README.md](../README.md) - Project overview and quick start
- [C4 Model Diagrams](../architecture.c4.dsl) - Visual architecture representations
