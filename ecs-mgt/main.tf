provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment         = local.environment
      Project             = var.project_name
      Origin_Repo         = var.origin_repo
      Environment         = local.environment
      Terraform_Workspace = terraform.workspace
    }
  }
}
provider "tfe" {
  organization = var.tfe_organization
  token        = var.tfe_token
}

locals {
  environment = regex("(prd|tst|dev)$", "${terraform.workspace}")[0]
}

data "tfe_outputs" "network_core" {
  organization = var.tfe_organization
  workspace    = "${var.network_core_workspace_base_name}-${local.environment}"
}

data "tfe_outputs" "ecs_cluster" {
  organization = var.tfe_organization
  workspace    = "${var.ecs_cluster_workspace_base_name}-${local.environment}"
}
data "tfe_outputs" "ecs_cloudflared_tunnel" {
  organization = var.tfe_organization
  workspace    = "${var.ecs_cloudflared_tunnel_workspace_base_name}-${local.environment}"
}

data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = data.tfe_outputs.ecs_cluster.values.ecs_cluster_name
}

data "aws_iam_role" "ecs_task_execution" {
  name = data.tfe_outputs.ecs_cluster.values.ecs_task_execution_role_name
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.12.1"

  name                     = var.ecs_service_name
  cluster_arn              = data.aws_ecs_cluster.ecs_cluster.arn
  desired_count            = 0
  enable_autoscaling = false
  #autoscaling_max_capacity = 1
  #autoscaling_min_capacity = 0

  cpu    = 256
  memory = 512

  # currently public, figure out private
  # public is needed for ECS to get public IPv4 access to 
  subnet_ids = data.tfe_outputs.network_core.values.aws_subnets_public.*.id

  assign_public_ip = true
  #task_definition_arn = aws_ecs_task_definition.ecs_task.arn
  container_definitions = {
    mgt = {
      cpu                       = 256
      memory                    = 512
      image                     = var.container_image
      command = ["sleep", "3600"]
      # port_mappings = [
      #   {
      #     name          = "ssh"
      #     containerPort = 22
      #     hostPort      = 2222
      #     protocol      = "tcp"
      #   }
      # ]
      readonly_root_filesystem  = false
      enable_cloudwatch_logging = true
      create_cloudwatch_log_group = true
      cloudwatch_log_group_name = "/ecs/mgt"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/mgt"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.ecs_service_name
        }
      }
    }
  }
  security_group_rules = {
    ingress = {
      type                     = "ingress"
      from_port                = 2222
      to_port                  = 2222
      protocol                 = "tcp"
      description              = "SSH access from Cloudflare Tunnel"
      source_security_group_id = data.tfe_outputs.ecs_cloudflared_tunnel.values.cloudflared_tunnel_sg_id
    }
    egress = {
      type             = "egress"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  #create_task_definition = false

  enable_execute_command    = true
  create_iam_role           = false
  iam_role_arn              = data.aws_iam_role.ecs_task_execution.arn
  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = data.aws_iam_role.ecs_task_execution.arn
  create_task_exec_policy   = false
  create_tasks_iam_role     = false
  tasks_iam_role_arn        = data.aws_iam_role.ecs_task_execution.arn
}

resource "aws_service_discovery_service" "mgt" {
  name = var.ecs_service_name
  dns_config {
    namespace_id = data.tfe_outputs.network_core.values.cloudmap_namespace_id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }
}
