variable "project_name" {
  description = "Project name for tagging resources"
  type        = string
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

variable "network_core_workspace_base_name" {
  description = "The base name of the HCP Terraform workspace for the network core. The environment will be appended."
  type        = string
}

variable "ecs_cluster_workspace_base_name" {
  description = "The base name of the HCP Terraform workspace for the ECS cluster. The environment will be appended."
  type        = string
}

variable "ecs_cloudflared_tunnel_workspace_base_name" {
  description = "The base name of the HCP Terraform workspace for the ECS Cloudflare tunnel. The environment will be appended."
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service to create"
  type        = string
  default     = "ecs-mgt"
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
  default     = "alpine:latest"
}

variable "ecs_service_desired_count" {
  description = "Desired count of the ECS service instances"
  type        = number
  default     = 2
}

variable "ssh_public_key" {
  description = "SSH public key for the container"
  type        = string
}