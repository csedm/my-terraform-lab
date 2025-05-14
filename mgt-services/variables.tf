variable "origin_repo" {
  description = "The origin repository for the module"
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
variable "region" {
  default = "us-east-2"
}
variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
variable "ssh_public_key_file" {
  description = "SSH public key file"
  type        = string
}