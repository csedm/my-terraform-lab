// Variables for ECS cloudflared tunnel module
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

variable "cloudflare_tunnel_name" {
  description = "Name for the Cloudflare tunnel"
  type        = string
}

variable "network_core_workspace_base_name" {
  description = "The base name of the HCP Terraform workspace for the network core. The environment will be appended."
  type        = string
}

variable "ecs_cluster_workspace_base_name" {
  description = "The base name of the HCP Terraform workspace for the ECS cluster. The environment will be appended."
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service that will use the cloudflared tunnel"
  type        = string
  default     = "cloudflared-tunnel"
}

variable "ecs_service_desired_count" {
  description = "Desired count of the ECS service instances"
  type        = number
  default     = 2
}

variable "cloudflared_version" {
  description = "Version of the cloudflared binary to use"
  type        = string
  default     = "latest"
}
variable "cloudflared_ingress_rules" {
  description = "List of ingress rules for the shared cloudflared tunnel. Each rule is an object with hostname and service. The last rule should be a catch-all (e.g. http_status:404)."
  type = list(object({
    hostname = optional(string)
    service  = string
  }))
}
