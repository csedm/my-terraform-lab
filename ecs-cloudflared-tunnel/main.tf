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

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "tfe" {
  organization = var.tfe_organization
  token        = var.tfe_token
}

locals {
  environment                 = regex("(prd|tst|dev)$", "${terraform.workspace}")[0]
  network_core_workspace_name = "${var.network_core_workspace_base_name}-${local.environment}"
  ecs_cluster_workspace_name  = "${var.ecs_cluster_workspace_base_name}-${local.environment}"
}

data "tfe_outputs" "network_core" {
  organization = var.tfe_organization
  workspace    = local.network_core_workspace_name
}

data "tfe_outputs" "ecs_cluster" {
  organization = var.tfe_organization
  workspace    = local.ecs_cluster_workspace_name
}

# Cloudflare Tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = var.cloudflare_account_id
  name       = var.cloudflare_tunnel_name
  config_src = "cloudflare"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "tunnel" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

resource "aws_ssm_parameter" "cloudflared_tunnel_token" {
  name        = "/${var.project_name}/${local.environment}/cloudflared_tunnel_token"
  description = "Cloudflared Tunnel run token for shared ingress tunnel"
  type        = "SecureString"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel.token
}

resource "aws_cloudwatch_log_group" "cloudflared" {
  name              = "/ecs/${var.ecs_service_name}"
  retention_in_days = 14
}

# IAM Role for ECS Task Execution (assume pre-existing, fetched from cluster workspace)
data "aws_iam_role" "ecs_task_execution" {
  name = data.tfe_outputs.ecs_cluster.values.ecs_task_execution_role_name
}

resource "aws_ecs_task_definition" "cloudflared" {
  family                   = var.ecs_service_name
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  task_role_arn            = data.aws_iam_role.ecs_task_execution.arn
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = "cloudflared"
      image     = "cloudflare/cloudflared:${var.cloudflared_version}"
      cpu       = 256
      memory    = 512
      essential = true
      command   = ["tunnel", "--no-autoupdate", "run"]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.cloudflared.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "cloudflared"
        }
      }
      secrets = [
        {
          name      = "TUNNEL_TOKEN"
          valueFrom = aws_ssm_parameter.cloudflared_tunnel_token.name
        }
      ]
    }
  ])
}

resource "aws_security_group" "cloudflared_tunnel_sg" {
  name        = "${var.ecs_service_name}-${local.environment}-sg"
  description = "Security group for ECS cloudflared tunnel"
  vpc_id      = data.tfe_outputs.network_core.values.aws_vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cloudflared_tunnel_sg_egress" {
  security_group_id = aws_security_group.cloudflared_tunnel_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_ecs_service" "cloudflared_tunnel" {
  name            = var.ecs_service_name
  cluster         = data.tfe_outputs.ecs_cluster.values.ecs_cluster_id
  task_definition = aws_ecs_task_definition.cloudflared.arn
  desired_count   = var.ecs_service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = true
    subnets          = data.tfe_outputs.network_core.values.aws_subnets_public.*.id
    security_groups  = [aws_security_group.cloudflared_tunnel_sg.id]
  }

  availability_zone_rebalancing = "ENABLED"

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_appautoscaling_target" "ecs_cloudflared_target" {
  max_capacity       = 2
  min_capacity       = 0
  resource_id        = "service/${data.tfe_outputs.ecs_cluster.values.ecs_cluster_name}/${aws_ecs_service.cloudflared_tunnel.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cloudflared_scale_down" {
  name               = "${var.ecs_service_name}-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_cloudflared_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_cloudflared_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_cloudflared_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 3600
    metric_aggregation_type = "Average"

    # >1.5: no change
    step_adjustment {
      metric_interval_lower_bound = 1.5
      scaling_adjustment          = 0
    }
    # <=1.5: scale down
    step_adjustment {
      metric_interval_upper_bound = 1.5
      scaling_adjustment          = -2
    }
  }
}

# resource "aws_appautoscaling_policy" "ecs_cloudflared_scale_up" {
#   name               = "cloudflared-scale-up"
#   policy_type        = "StepScaling"
#   resource_id        = aws_appautoscaling_target.ecs_cloudflared_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs_cloudflared_target.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.ecs_cloudflared_target.service_namespace

#   step_scaling_policy_configuration {
#     adjustment_type         = "ChangeInCapacity"
#     cooldown                = 60
#     metric_aggregation_type = "Average"

#     step_adjustment {
#       metric_interval_upper_bound = 0
#       scaling_adjustment          = 2
#     }
#   }
# }

resource "aws_cloudwatch_metric_alarm" "alarm_cloudflared_idle" {
  alarm_name          = "${var.project_name}_cpu_usage_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 24
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 1.5

  dimensions = {
    ClusterName = data.tfe_outputs.ecs_cluster.values.ecs_cluster_name
    ServiceName = aws_ecs_service.cloudflared_tunnel.name
  }

  alarm_description = "ECS cloudflared tunnel service CPU utilization is idle"
  alarm_actions     = [aws_appautoscaling_policy.ecs_cloudflared_scale_down.arn]
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "shared" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id

  config = {
    ingress = var.cloudflared_ingress_rules
  }
}
