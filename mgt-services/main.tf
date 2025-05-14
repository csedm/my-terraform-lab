# my-terraform-lab
# author: @csedm

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Origin_Repo               = var.origin_repo
      Environment               = local.environment
      Terraform_Workspace       = terraform.workspace
    }
  }
}

provider "random" {}

provider "tfe" {
  organization = var.tfe_organization
  token        = var.tfe_token
}

locals {
  environment = regex("(prd|tst|dev)$", "${terraform.workspace}")[0]
}

# Data blocks
data "tfe_outputs" "network_core_outputs" {
  organization = var.tfe_organization
  workspace    = "mytflab-network-core-${local.environment}"
}

data "tfe_outputs" "storage_persistent" {
  organization = var.tfe_organization
  workspace    = "mytflab-storage-persistent-${local.environment}"
}

resource "aws_key_pair" "terraform_ec2_key" {
  key_name   = "${terraform.workspace}-ssh-key"
  public_key = file(var.ssh_public_key_file)
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
  instance_type               = var.ec2_instance_type
  availability_zone           = data.tfe_outputs.network_core_outputs.values.aws_subnets_private[0].availability_zone
  key_name                    = aws_key_pair.terraform_ec2_key.key_name
  subnet_id                   = data.tfe_outputs.network_core_outputs.values.aws_subnets_private[0].id
  vpc_security_group_ids      = [aws_security_group.mgt-sg.id]
  user_data_replace_on_change = true

  user_data = templatefile("mount-efs.tftpl", {
    efs_id = data.tfe_outputs.storage_persistent.values.efs_file_system_id
  })

  tags = {
    Name = random_pet.mgt_name.id
    ansible_roles = "mgmt"
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
  referenced_security_group_id = aws_security_group.bastion-sg.id
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

# Bastion Host

resource "random_pet" "bastion_name" {}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = var.ec2_instance_type
  availability_zone           = data.tfe_outputs.network_core_outputs.values.aws_subnets_private[0].availability_zone
  key_name                    = aws_key_pair.terraform_ec2_key.key_name
  subnet_id                   = data.tfe_outputs.network_core_outputs.values.aws_subnets_public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion-sg.id]
  associate_public_ip_address = true

  tags = {
    name = random_pet.bastion_name.id
    ansible_roles = "bastion"
  }
}

# Security Groups - bastion
resource "aws_security_group" "bastion-sg" {
  name        = "bastion-sg"
  description = "allow inbound ssh traffic"
  vpc_id      = data.tfe_outputs.network_core_outputs.values.aws_vpc_id
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_ingress_ssh_ipv4" {
  security_group_id = aws_security_group.bastion-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_ssh_ipv6" {
  security_group_id = aws_security_group.bastion-sg.id
  cidr_ipv6         = "::/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_bastion_traffic_ipv4" {
  security_group_id = aws_security_group.bastion-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
resource "aws_vpc_security_group_egress_rule" "allow_all_bastion_traffic_ipv6" {
  security_group_id = aws_security_group.bastion-sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
  
}
