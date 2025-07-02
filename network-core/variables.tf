variable "origin_repo" {
  description = "The origin repository for the module"
  type        = string
  default     = "my-terraform-lab"
}
variable "region" {
  default = "us-east-1"
}
variable "availability_zone" {
  default = "us-east-1a"
}
variable "number_availability_zones" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.2.0.0/16"
}
/*
variable "vpc_ipv6_cidr_block" {
  description = "IPv6 CIDR block for the VPC"
  type        = string
  default     = "fd00::/56"
}*/
variable "service_discovery_namespace" {
  description = "Service discovery namespace for ECS services"
  type        = string
  default = "mytflab.local"
}