provider "aws" {
  region = var.region
  default_tags {
    tags = {
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
  network_core_workspace_name = "${var.network_core_workspace_base_name}-${local.environment}"
}

data "tfe_outputs" "network_core" {
  organization = var.tfe_organization
  workspace    = local.network_core_workspace_name
}

data "aws_caller_identity" "current" {}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster-${local.environment}"

  configuration {
    managed_storage_configuration {
      kms_key_id = "arn:aws:kms:us-east-1:209332137817:alias/aws/ebs"
    }
  }
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs-cluster-providers" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}


# IAM Role definition
#import {
#  to = aws_iam_role.ecs_task_execution
#  id = "ecsTaskExecutionRole"
#}
data "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"
}
# manage this pre-existing resource 
# by the ecs-cluster config?
# resource "aws_iam_role" "ecs_task_execution" {
#   name = "ecsTaskExecutionRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "ecs-tasks.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

#resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
#  role       = data.aws_iam_role.ecs_task_execution.name
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
#}

resource "aws_iam_role_policy" "ecs_ssm_access" {
  name = "ecs-ssm-access-policy"
  role = data.aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        # Least privilege: restrict to all SSM parameters in this account/region
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        # Use the AWS managed KMS key for SSM Parameter Store
        Resource = [
          "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_logs" {
  name = "ecs-logs-policy"
  role = data.aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/*"
      }
    ]
  })
}
