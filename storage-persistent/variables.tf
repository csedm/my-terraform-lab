variable "tfe_organization" {
  description = "TFE organization to use for querying HCP Terraform remote state data."
  nullable    = false
}
variable "tfe_token" {
  description = "Token to provide to TFE provider needed to query remote state resources."
  nullable    = false
  sensitive   = true
}
variable "region" {
  default = "us-east-1"
}
variable "availability_zone" {
  default = "us-east-1a"
}
variable "env_map" {
  type = map(any)
  default = {
    "mytflab-storage-persistent-dev"  = "dev"
    "mytflab-storage-persistent-prod" = "prod"
  }
}
variable "subnet_cidr_id" {
  description = "CIDR ID for the subnet"
  type        = string
  default     = "31"
}