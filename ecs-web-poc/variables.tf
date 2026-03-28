// Variables for ECS web-poc nginx module

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "mytflab-ecs-web-poc"
}

variable "origin_repo" {
  description = "Origin repository for the project"
  type        = string
  default     = "my-terraform-lab"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tfe_organization" {
  description = "TFE organization for HCP Terraform remote state."
  type        = string
}

variable "tfe_token" {
  description = "TFE API token for remote state access."
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_domain" {
  description = "Cloudflare base domain"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare domain zone id"
  type        = string
}

variable "cloudflare_tunnel_dnsname" {
  description = "DNS name for the app in Cloudflare"
  type        = string
}

variable "cloudflare_access_idp_id" {
  description = "Cloudflare Access Identity Provider ID"
  type        = string
}

variable "cloudflare_access_allowed_group" {
  description = "Cloudflare group for accessing app"
  type        = string
}

variable "network_core_workspace_base_name" {
  description = "Name of the HCP Terraform workspace for the network core (e.g. mytflab-network-core)"
  type        = string
  default     = "mytflab-network-core"
}
variable "ecs_cluster_workspace_base_name" {
  description = "Name of the HCP Terraform workspace for the ECS cluster (e.g. mytflab-ecs-cluster)"
  type        = string
  default     = "mytflab-ecs-cluster"
}

variable "cloudflared_tunnel_workspace_base_name" {
  description = "Name of the HCP Terraform workspace for the cloudflared tunnel (e.g. ecs-cloudflared-tunnel)"
  type        = string
  default     = "mytflab-ecs-cloudflared-tunnel"
}

variable "ecs_service_name" {
  description = "Name of the ECS service that will use the cloudflared tunnel"
  type        = string
  default     = "web-poc"
}

variable "ecs_service_desired_count" {
  description = "Desired count of the ECS service instances"
  type        = number
  default     = 1
}