variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
variable "origin_repo" {
  description = "Originating repository"
  type        = string
  default     = "my-terraform-lab"
}
variable "tfe_organization" {
  description = "TFE organization to use for querying HCP Terraform remote state data."
  nullable    = false
}
variable "tfe_token" {
  description = "Token to provide to TFE provider needed to query remote state resources."
  nullable    = false
  sensitive   = true
}

variable "network_core_workspace_base_name" {
  description = "The base name of the HCP Terraform workspace for the network core. The environment will be appended."
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  sensitive   = true
}
variable "cloudflare_api_token" {
  description = "Cloudflare API token to use with cloudflare provider"
  type        = string
  sensitive   = true
}
variable "cloudflare_domain" {
  description = "cloudflare base domain"
  type        = string
}
variable "cloudflare_zone_id" {
  description = "cloudflare domain zone id"
  type        = string
}