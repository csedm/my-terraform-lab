workspace "My Terraform Lab" "AWS infrastructure showcasing modern cloud-native patterns, Zero Trust networking, and Infrastructure as Code best practices" {

    model {
        # External Actors
        user = person "End User" "Person accessing web applications through the internet" "User"
        admin = person "Administrator" "DevOps/Platform engineer managing infrastructure" "Admin"
        developer = person "Developer" "Software developer deploying applications" "Developer"

        # External Systems
        cloudflareEdge = softwareSystem "Cloudflare Edge Network" "Global CDN and Zero Trust security platform" "External System" {
            cfAccess = container "Cloudflare Access" "Identity-aware proxy with Zero Trust policies" "SaaS" "External"
            cfTunnelService = container "Cloudflare Tunnel Service" "Manages secure tunnels to private infrastructure" "SaaS" "External"
            cfDNS = container "Cloudflare DNS" "DNS resolution and routing" "SaaS" "External"
        }

        github = softwareSystem "GitHub" "Source control and CI/CD platform" "External System"
        hcpTerraform = softwareSystem "HCP Terraform Cloud" "Remote state management and workspace orchestration" "External System"

        # Main System - My Terraform Lab
        mytflab = softwareSystem "My Terraform Lab" "AWS infrastructure platform for containerized workloads with Zero Trust access" {

            # Network Layer
            vpc = container "VPC (network-core)" "Virtual Private Cloud with dual-stack networking (IPv4/IPv6)" "AWS VPC" "Infrastructure" {
                publicSubnets = component "Public Subnets" "Multi-AZ public subnets with full internet access" "AWS Subnet"
                privateSubnets = component "Private Subnets" "Multi-AZ private subnets with IPv6 egress only" "AWS Subnet"
                internetGateway = component "Internet Gateway" "IPv4 and IPv6 internet access for public subnets" "AWS IGW"
                eigw = component "Egress-Only IGW" "IPv6-only outbound internet access for private subnets" "AWS EIGW"
                cloudMap = component "AWS Cloud Map" "Service discovery namespace for ECS services" "AWS Cloud Map"
            }

            # Container Platform Layer
            ecsCluster = container "ECS Cluster" "Shared Fargate cluster for containerized workloads" "AWS ECS" "Infrastructure" {
                fargateCapacity = component "Fargate Capacity Provider" "Serverless compute for containers" "AWS Fargate"
                containerInsights = component "Container Insights" "Monitoring and observability for containers" "CloudWatch"
                taskExecutionRole = component "Task Execution Role" "IAM role for ECS agent (pull images, secrets)" "AWS IAM"
            }

            # Storage Layer
            efs = container "EFS File System (storage-persistent)" "Shared persistent storage with encryption and backups" "AWS EFS" "Infrastructure"

            # Ingress Layer
            cfTunnel = container "Cloudflare Tunnel (ecs-cloudflared-tunnel)" "Secure tunnel from Cloudflare to private ECS services" "ECS Fargate Service" "Container" {
                tunnelContainer = component "Cloudflared Container" "Tunnel daemon connecting to Cloudflare edge" "Docker Container"
                tunnelSG = component "Tunnel Security Group" "Controls ingress to ECS services" "AWS Security Group"
            }

            # Application Workloads
            ecsWebPoc = container "ecs-web-poc" "Web application demo with Cloudflare Access integration" "ECS Fargate Service" "Container" {
                nginxContainer = component "Nginx Container" "Web server serving application content" "Docker Container"
                webSG = component "Web Security Group" "Allows traffic from tunnel only" "AWS Security Group"
                webAutoScaling = component "Auto-scaling Policy" "Scales to 0 after 2 hours idle (CPU ≤0.6%)" "AWS Auto Scaling"
            }

            ecsMgt = container "ecs-mgt" "On-demand management container for operational tasks" "ECS Fargate Service" "Container" {
                alpineContainer = component "Alpine Container" "Lightweight container with shell access" "Docker Container"
                ecsExec = component "ECS Exec" "Interactive shell access via SSM Session Manager" "AWS ECS Exec"
                mgtSG = component "Management Security Group" "SSH access from tunnel" "AWS Security Group"
            }

            # Traditional Infrastructure
            bastionHost = container "Bastion Host (mgt-services)" "SSH gateway in public subnet" "EC2 Instance" "Infrastructure"
            mgtInstance = container "Management Instance (mgt-services)" "Private EC2 instance with EFS mount" "EC2 Instance" "Infrastructure"

            # Supporting Services
            parameterStore = container "Parameter Store" "Secure storage for secrets and configuration" "AWS SSM" "Infrastructure"
            cloudwatch = container "CloudWatch" "Centralized logging and metrics" "AWS CloudWatch" "Infrastructure"
        }

        # Relationships - External Users to System
        user -> cloudflareEdge "Accesses applications via HTTPS" "HTTPS/443"
        admin -> mytflab "Manages infrastructure" "AWS CLI/Terraform"
        admin -> hcpTerraform "Reviews plans and approves deployments" "HTTPS"
        developer -> github "Commits infrastructure code" "Git/HTTPS"

        # Relationships - External Systems
        github -> hcpTerraform "Triggers workspace runs on merge" "Webhook"
        hcpTerraform -> mytflab "Provisions and updates infrastructure" "AWS API"
        cloudflareEdge -> mytflab "Routes traffic through tunnel" "QUIC/HTTP/2"

        # Relationships - Cloudflare Internal
        user -> cfAccess "Authenticates with identity provider" "HTTPS"
        cfAccess -> cfTunnelService "Routes authorized requests" "Internal"
        cfTunnelService -> cfDNS "Resolves tunnel endpoints" "DNS"

        # Relationships - Network Layer
        vpc -> internetGateway "Routes public subnet traffic" "Network"
        vpc -> eigw "Routes private subnet IPv6 egress" "Network"
        publicSubnets -> internetGateway "Internet access" "IPv4/IPv6"
        privateSubnets -> eigw "IPv6 egress only" "IPv6"

        # Relationships - Platform Layer
        ecsCluster -> vpc "Deploys tasks in subnets" "Network"
        ecsCluster -> fargateCapacity "Provisions serverless compute" "API"
        ecsCluster -> containerInsights "Sends metrics and logs" "CloudWatch Agent"
        ecsCluster -> taskExecutionRole "Assumes role for task operations" "AWS STS"

        # Relationships - Ingress Layer
        cfTunnelService -> cfTunnel "Establishes secure tunnel connection" "QUIC"
        cfTunnel -> publicSubnets "Deployed in public subnets" "Network"
        cfTunnel -> ecsCluster "Runs as ECS service" "ECS API"
        cfTunnel -> parameterStore "Retrieves tunnel credentials" "AWS API"
        cfTunnel -> cloudMap "Discovers backend services" "DNS"
        tunnelContainer -> cloudwatch "Streams logs" "CloudWatch Logs API"

        # Relationships - Application Layer
        ecsWebPoc -> privateSubnets "Deployed in private subnets" "Network"
        ecsWebPoc -> ecsCluster "Runs as ECS service" "ECS API"
        ecsWebPoc -> cloudMap "Registers for service discovery" "Cloud Map API"
        ecsWebPoc -> cloudwatch "Streams logs and metrics" "CloudWatch API"
        cfTunnel -> ecsWebPoc "Forwards user requests" "HTTP"
        nginxContainer -> webAutoScaling "Monitored by auto-scaling" "CloudWatch Alarms"

        ecsMgt -> publicSubnets "Deployed in public subnets" "Network"
        ecsMgt -> ecsCluster "Runs as ECS service" "ECS API"
        ecsMgt -> cloudMap "Registers for service discovery" "Cloud Map API"
        admin -> ecsMgt "Executes commands via ECS Exec" "SSM Session Manager"
        alpineContainer -> cloudwatch "Streams logs" "CloudWatch Logs API"

        # Relationships - Traditional Infrastructure
        bastionHost -> publicSubnets "Deployed in public subnet" "Network"
        mgtInstance -> privateSubnets "Deployed in private subnet" "Network"
        mgtInstance -> efs "Mounts for persistent storage" "NFS"
        admin -> bastionHost "SSH access" "SSH/22"
        bastionHost -> mgtInstance "SSH gateway to management instance" "SSH/22"

        # Relationships - Supporting Services
        taskExecutionRole -> parameterStore "Retrieves secrets and config" "AWS API"
        parameterStore -> cloudwatch "Audit logs" "CloudWatch Logs"
        ecsCluster -> cloudwatch "Logs and metrics" "CloudWatch API"

        # Component Level Relationships
        webSG -> tunnelSG "Allows ingress from tunnel SG" "Security Group Rule"
        mgtSG -> tunnelSG "Allows SSH from tunnel SG" "Security Group Rule"
    }

    views {
        # System Context Diagram (Level 1)
        systemContext mytflab "SystemContext" {
            include *
            autoLayout lr
            description "System context diagram showing My Terraform Lab and its external dependencies"
            properties {
                structurizr.groups false
            }
        }

        # Container Diagram (Level 2) - Full Infrastructure
        container mytflab "InfrastructureContainers" {
            include *
            autoLayout lr
            description "Container diagram showing all infrastructure components and their relationships"
        }

        # Container Diagram (Level 2) - Application Focus
        container mytflab "ApplicationFlow" {
            include user cloudflareEdge cfTunnel ecsWebPoc ecsMgt cloudwatch parameterStore cloudMap
            autoLayout lr
            description "Simplified view focusing on application request flow and core services"
        }

        # Component Diagram (Level 3) - Network Layer
        component vpc "NetworkComponents" {
            include *
            autoLayout lr
            description "Network layer components showing VPC, subnets, gateways, and service discovery"
        }

        # Component Diagram (Level 3) - ECS Cluster
        component ecsCluster "ECSClusterComponents" {
            include *
            autoLayout lr
            description "ECS cluster components showing Fargate capacity, monitoring, and IAM roles"
        }

        # Component Diagram (Level 3) - Web Application
        component ecsWebPoc "WebApplicationComponents" {
            include *
            autoLayout tb
            description "Web application components showing container, security, and auto-scaling"
        }

        # Component Diagram (Level 3) - Management Service
        component ecsMgt "ManagementComponents" {
            include *
            autoLayout tb
            description "Management container components showing ECS Exec and security configuration"
        }

        # Component Diagram (Level 3) - Cloudflare Tunnel
        component cfTunnel "TunnelComponents" {
            include *
            autoLayout tb
            description "Cloudflare Tunnel components showing tunnel daemon and security groups"
        }

        # Deployment Diagram
        deployment mytflab "Production" "AWSDeployment" {
            deploymentNode "AWS Cloud" {
                tags "AWS"

                deploymentNode "us-east-1 Region" {
                    tags "AWS Region"

                    deploymentNode "VPC (10.0.0.0/16)" {
                        tags "Network"

                        deploymentNode "Availability Zone A" {
                            tags "AZ"

                            deploymentNode "Public Subnet A (10.0.1.0/24)" {
                                tags "Public Subnet"

                                deploymentNode "ECS Task (Cloudflare Tunnel)" {
                                    tags "Fargate"
                                    containerInstance cfTunnel
                                }

                                deploymentNode "EC2 Instance (Bastion)" {
                                    tags "EC2"
                                    containerInstance bastionHost
                                }
                            }

                            deploymentNode "Private Subnet A (10.0.11.0/24)" {
                                tags "Private Subnet"

                                deploymentNode "ECS Task (Web POC)" {
                                    tags "Fargate"
                                    containerInstance ecsWebPoc
                                }

                                deploymentNode "ECS Task (Management)" {
                                    tags "Fargate"
                                    containerInstance ecsMgt
                                }

                                deploymentNode "EC2 Instance (Management)" {
                                    tags "EC2"
                                    containerInstance mgtInstance
                                }
                            }
                        }

                        deploymentNode "Availability Zone B" {
                            tags "AZ"

                            deploymentNode "Public Subnet B (10.0.2.0/24)" {
                                tags "Public Subnet"

                                deploymentNode "ECS Task (Cloudflare Tunnel)" {
                                    tags "Fargate"
                                    containerInstance cfTunnel
                                }
                            }

                            deploymentNode "Private Subnet B (10.0.12.0/24)" {
                                tags "Private Subnet"

                                deploymentNode "ECS Task (Web POC)" {
                                    tags "Fargate"
                                    containerInstance ecsWebPoc
                                }

                                deploymentNode "ECS Task (Management)" {
                                    tags "Fargate"
                                    containerInstance ecsMgt
                                }
                            }
                        }
                    }

                    deploymentNode "AWS Managed Services" {
                        tags "Managed Service"

                        containerInstance ecsCluster
                        containerInstance cloudwatch
                        containerInstance parameterStore
                        containerInstance efs
                    }
                }
            }

            deploymentNode "Cloudflare Global Network" {
                tags "External"
                containerInstance cloudflareEdge
            }

            deploymentNode "HashiCorp Cloud Platform" {
                tags "External"
                softwareSystemInstance hcpTerraform
            }
        }

        # Dynamic Diagram - User Request Flow
        dynamic mytflab "UserRequestFlow" "Shows the flow of a user request through the system" {
            user -> cloudflareEdge "1. HTTPS request to application"
            cloudflareEdge -> cfTunnel "2. Identity verified, forward via tunnel"
            cfTunnel -> ecsWebPoc "3. Route to web service via service discovery"
            ecsWebPoc -> cloudwatch "4. Log request"
            ecsWebPoc -> cfTunnel "5. Return response"
            cfTunnel -> cloudflareEdge "6. Send via tunnel"
            cloudflareEdge -> user "7. HTTPS response"
            autoLayout lr
        }

        # Dynamic Diagram - Admin Shell Access
        dynamic mytflab "AdminShellAccess" "Shows how an administrator accesses the management container" {
            admin -> ecsMgt "1. Scale up service to 1 instance (AWS CLI)"
            ecsMgt -> ecsCluster "2. ECS schedules Fargate task"
            ecsCluster -> ecsMgt "3. Task starts and enters RUNNING state"
            admin -> ecsMgt "4. Execute command via ECS Exec (SSM)"
            ecsMgt -> cloudwatch "5. Log session activity"
            admin -> ecsMgt "6. Complete work, exit shell"
            admin -> ecsMgt "7. Scale down service to 0 instances"
            autoLayout tb
        }

        # Dynamic Diagram - Infrastructure Deployment
        dynamic mytflab "InfrastructureDeployment" "Shows the Terraform deployment workflow" {
            developer -> github "1. Push Terraform code"
            github -> hcpTerraform "2. Trigger workspace run"
            hcpTerraform -> mytflab "3. Generate and display plan"
            admin -> hcpTerraform "4. Review and approve plan"
            hcpTerraform -> mytflab "5. Apply changes to AWS"
            mytflab -> hcpTerraform "6. Update remote state"
            autoLayout lr
        }

        # Styles
        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "User" {
                background #1168bd
            }
            element "Admin" {
                background #d35400
            }
            element "Developer" {
                background #27ae60
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External System" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Infrastructure" {
                background #85bbf0
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Fargate" {
                shape hexagon
                background #ff9900
                color #ffffff
            }
            element "EC2" {
                shape box
                background #ec7211
                color #ffffff
            }
            element "Network" {
                background #4a90e2
                color #ffffff
            }
            element "Managed Service" {
                background #50c878
                color #ffffff
            }
            relationship "Relationship" {
                thickness 2
                color #707070
                style solid
            }
        }

        # Themes
        theme default
    }

    configuration {
        scope softwaresystem
    }
}
