# my-terraform-lab
# author: @csedm

provider "aws" {
  region = var.region
}

provider "random" {}

provider "tfe" {
  organization = var.tfe_organization
  token        = var.tfe_token
}

# Data blocks
data "tfe_outputs" "network_core_outputs" {
  organization = var.tfe_organization
  workspace    = "mytflab-network-core-${lookup(var.env_map, terraform.workspace)}"
}

data "tfe_outputs" "storage_persistent" {
  organization = var.tfe_organization
  workspace    = "mytflab-storage-persistent-${lookup(var.env_map, terraform.workspace)}"
}

resource "aws_key_pair" "terraform_ec2_key" {
  key_name   = "terraform_ec2_key"
  public_key = file("id_ed25519_aws.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "amazon-linux-2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "random_pet" "mgt_name" {}

resource "aws_instance" "mgt" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "t2.micro"
  availability_zone           = var.availability_zone
  key_name                    = "terraform_ec2_key"
  subnet_id                   = data.tfe_outputs.network_core_outputs.values.aws_subnet_private.id
  vpc_security_group_ids      = [aws_security_group.mgt-sg.id]
  user_data_replace_on_change = true

  user_data = templatefile("mount-efs.tftpl", {
    efs_id = data.tfe_outputs.storage_persistent.values.efs_file_system_id
  })

  tags = {
    Name = random_pet.mgt_name.id
    sla  = "exp"
  }
}

# Security Groups - mgt
resource "aws_security_group" "mgt-sg" {
  name        = "${random_pet.mgt_name.id}-mgt-sg"
  description = "allow inbound ssh traffic from bastion"
  vpc_id      = data.tfe_outputs.network_core_outputs.values.aws_vpc_id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_mgt_ssh_ipv4" {
  security_group_id            = aws_security_group.mgt-sg.id
  referenced_security_group_id = data.tfe_outputs.network_core_outputs.values.bastion_security_group_id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_egress_mgt_all_ipv4" {
  security_group_id = aws_security_group.mgt-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_egress_mgt_all_ipv6" {
  security_group_id = aws_security_group.mgt-sg.id
  cidr_ipv6        = "::/0"
  ip_protocol       = "-1"

}

/*
# Security Groups - EFS
# Rules to allow mgt hosts to access EFS.
resource "aws_security_group" "efs-sg" {
   name = "efs-sg"
   vpc_id = data.tfe_outputs.network_core_outputs.values.aws_vpc_id
   lifecycle {
    create_before_destroy = true
  }
 }
 */

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_efs" {
  security_group_id            = data.tfe_outputs.storage_persistent.values.aws_efs_security_group_id
  referenced_security_group_id = aws_security_group.mgt-sg.id
  # NFS
  from_port   = 2049
  to_port     = 2049
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_egress_efs" {
  security_group_id            = data.tfe_outputs.storage_persistent.values.aws_efs_security_group_id
  referenced_security_group_id = aws_security_group.mgt-sg.id
  ip_protocol                  = "-1"
}