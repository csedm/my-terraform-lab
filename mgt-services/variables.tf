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
variable "ami_base_version" {
  description = "Base version of the Alpine AMI"
  type        = string
  default     = "3.21"
}

variable "ami_architecture" {
  description = "Architecture for the Alpine AMI (e.g., x86_64)"
  type        = string
  default     = "x86_64"
}

variable "aws_ami_owner_id" {
  description = "AWS Account ID of the AMI owner"
  type        = string
}

variable "ssh_public_key_file" {
  description = "SSH public key file"
  type        = string
}
variable "permitted_cidrs_ipv4" {
  description = "CIDR blocks for permitted IPv4 access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
variable "permitted_cidrs_ipv6" {
  description = "CIDR blocks for permitted IPv6 access"
  type        = list(string)
  default     = ["::/0"]
}