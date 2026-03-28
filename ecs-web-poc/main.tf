// Main resources for ECS web-poc nginx module

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
  environment                       = regex("(prd|tst|dev)$", "${terraform.workspace}")[0]
  network_core_workspace_name       = "${var.network_core_workspace_base_name}-${local.environment}"
  ecs_cluster_workspace_name        = "${var.ecs_cluster_workspace_base_name}-${local.environment}"
  cloudflared_tunnel_workspace_name = "${var.cloudflared_tunnel_workspace_base_name}-${local.environment}"
}

data "tfe_outputs" "network_core" {
  organization = var.tfe_organization
  workspace    = local.network_core_workspace_name
}

data "tfe_outputs" "ecs_cluster" {
  organization = var.tfe_organization
  workspace    = local.ecs_cluster_workspace_name
}

data "tfe_outputs" "cloudflared_tunnel" {
  organization = var.tfe_organization
  workspace    = local.cloudflared_tunnel_workspace_name
}

data "cloudflare_zero_trust_access_identity_provider" "idp" {
  account_id = var.cloudflare_account_id
  #name       = "Cloudflare Access"
}

resource "aws_cloudwatch_log_group" "web_poc" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 14
}

# IAM Role for ECS Task Execution (assume pre-existing, fetched from cluster workspace)
data "aws_iam_role" "ecs_task_execution" {
  name = data.tfe_outputs.ecs_cluster.values.ecs_task_execution_role_name
}

resource "aws_security_group" "web_poc_sg" {
  name        = "${var.project_name}-${local.environment}-sg"
  description = "Security group for web-poc ECS service"
  vpc_id      = data.tfe_outputs.network_core.values.aws_vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_poc_sg_ingress" {
  security_group_id        = aws_security_group.web_poc_sg.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = data.tfe_outputs.cloudflared_tunnel.values.cloudflared_tunnel_sg_id
}

resource "aws_security_group_rule" "web_poc_sg_egress" {
  security_group_id = aws_security_group.web_poc_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_ecs_task_definition" "web_poc" {
  family                   = var.ecs_service_name
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  task_role_arn            = data.aws_iam_role.ecs_task_execution.arn
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = var.ecs_service_name
      image     = "nginx:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "web_poc" {
  name            = var.ecs_service_name
  cluster         = data.tfe_outputs.ecs_cluster.values.ecs_cluster_id
  task_definition = aws_ecs_task_definition.web_poc.arn
  desired_count   = var.ecs_service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    #assign_public_ip = true
    subnets         = data.tfe_outputs.network_core.values.aws_subnets_private.*.id
    security_groups = [aws_security_group.web_poc_sg.id]
  }

  availability_zone_rebalancing = "ENABLED"

  service_registries {
    registry_arn = aws_service_discovery_service.web_poc.arn
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_service_discovery_service" "web_poc" {
  name = var.ecs_service_name
  dns_config {
    namespace_id = data.tfe_outputs.ecs_cluster.values.cloudmap_namespace_id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }
}

# Cloudflare app-specific config
resource "cloudflare_zero_trust_access_application" "web_poc" {
  account_id           = var.cloudflare_account_id
  name                 = var.cloudflare_tunnel_dnsname
  domain               = "${var.cloudflare_tunnel_dnsname}.${var.cloudflare_domain}"
  type                 = "self_hosted"
  session_duration     = "24h"
  app_launcher_visible = true
  allowed_idps         = [var.cloudflare_access_idp_id]
  policies = [{
    id         = cloudflare_zero_trust_access_policy.web_poc.id
    precedence = 0
  }]
}

resource "cloudflare_zero_trust_access_policy" "web_poc" {
  account_id = var.cloudflare_account_id
  name       = "Access policy for ${var.cloudflare_tunnel_dnsname}"
  decision   = "allow"
  include = [{
    group = {
      id = var.cloudflare_access_allowed_group
    }
  }]
}

resource "cloudflare_dns_record" "web_poc_record" {
  zone_id = var.cloudflare_zone_id
  name    = var.cloudflare_tunnel_dnsname
  content = "${data.tfe_outputs.cloudflared_tunnel.values.cloudflared_tunnel_id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "aws_appautoscaling_target" "ecs_web_poc_target" {
  max_capacity       = 1
  min_capacity       = 0
  resource_id        = "service/${data.tfe_outputs.ecs_cluster.values.ecs_cluster_name}/${aws_ecs_service.web_poc.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_web_poc_scale_down" {
  name               = "${var.ecs_service_name}-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_web_poc_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_web_poc_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_web_poc_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 3600
    metric_aggregation_type = "Average"

    # >0.6: no change
    step_adjustment {
      metric_interval_lower_bound = 0.6
      scaling_adjustment          = 0
    }
    # <=0.6: scale down
    step_adjustment {
      metric_interval_upper_bound = 0.6
      scaling_adjustment          = -1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_web_poc_idle" {
  alarm_name          = "${var.project_name}_cpu_usage_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 24
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0.6

  dimensions = {
    ClusterName = data.tfe_outputs.ecs_cluster.values.ecs_cluster_name
    ServiceName = aws_ecs_service.web_poc.name
  }

  alarm_description = "ECS web-poc service CPU utilization is idle"
  alarm_actions     = [aws_appautoscaling_policy.ecs_web_poc_scale_down.arn]
}

