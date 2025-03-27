# my-terraform-lab
# author: @csedm

provider "aws" {
  region = var.region
}

provider "tfe" {
  organization = var.tfe_organization
  token        = var.tfe_token
}

# Data blocks
data "tfe_outputs" "network_core_outputs" {
  organization = var.tfe_organization
  workspace    = "mytflab-network-core-${lookup(var.env_map, terraform.workspace)}"
}

# needs the VPC ID from network-core
resource "aws_subnet" "subnet-efs" {
  cidr_block        = "10.2.2.0/24"
  vpc_id            = data.tfe_outputs.network_core_outputs.values.aws_vpc_id
  availability_zone = var.availability_zone
}

# Create the EFS file system on AWS
resource "aws_efs_file_system" "mgt-efs" {
  creation_token   = "mgt-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "true"

}

# Create the mount point
resource "aws_efs_mount_target" "mgt-efs-mt" {
  file_system_id  = aws_efs_file_system.mgt-efs.id
  subnet_id       = aws_subnet.subnet-efs.id
  security_groups = ["${aws_security_group.efs-sg.id}"]
}


# Needs the VPC ID from network-core
# Security Groups - EFS
resource "aws_security_group" "efs-sg" {
  name   = "efs-sg"
  vpc_id = data.tfe_outputs.network_core_outputs.values.aws_vpc_id
  lifecycle {
    create_before_destroy = true
  }
}


/*
# Needs the MGT security group... this represents a multi-direction dependency
 resource "aws_vpc_security_group_ingress_rule" "allow_ingress_efs" {
  security_group_id = aws_security_group.efs-sg.id
  referenced_security_group_id = aws_security_group.mgt-sg.id
  # NFS
  from_port = 2049
  to_port = 2049
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_egress_efs" {
  security_group_id = aws_security_group.efs-sg.id
  referenced_security_group_id = aws_security_group.mgt-sg.id
  ip_protocol = "-1"
}
*/