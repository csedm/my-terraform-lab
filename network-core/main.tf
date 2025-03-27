# my-terraform-lab
# author: @csedm

provider "aws" {
  region = var.region
}

provider "random" {}

resource "aws_key_pair" "terraform_ec2_key" {
  key_name   = "terraform_ec2_key"
  public_key = file("id_ed25519_aws.pub")
}

# VPC & networking
resource "aws_vpc" "mytf" {
  cidr_block                       = "10.2.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true
  enable_dns_support               = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.mytf.id
}

resource "aws_egress_only_internet_gateway" "ipv6_egress_igw" {
  vpc_id = aws_vpc.mytf.id
}

resource "aws_route" "route" {
  route_table_id         = aws_vpc.mytf.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

/*
resource "aws_route" "ipv6-egress-route" {
  route_table_id              = aws_vpc.mytf.main_route_table_id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.gw.id
}
*/

# enables egress-only ipv6 connectivity for private subnets
resource "aws_route" "ipv6-private-egress-route" {
  route_table_id              = aws_vpc.mytf.main_route_table_id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.ipv6_egress_igw.id
}

resource "aws_subnet" "public" {
  vpc_id                          = aws_vpc.mytf.id
  availability_zone               = var.availability_zone
  cidr_block                      = "10.2.0.0/24"
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.mytf.ipv6_cidr_block, 8, 0)
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  depends_on                      = [aws_internet_gateway.gw]
}

resource "aws_subnet" "private" {
  vpc_id                          = aws_vpc.mytf.id
  availability_zone               = var.availability_zone
  cidr_block                      = "10.2.1.0/24"
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.mytf.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation = true
  depends_on                      = [aws_internet_gateway.gw]
}

/*
resource "aws_subnet" "subnet-efs" {
   cidr_block = "10.2.2.0/24"
   vpc_id = aws_vpc.mytf.id
   availability_zone = "${var.availability_zone}"
}
*/

data "aws_ami" "amazon-linux-2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

#resource "random_pet" "mgt_name" {}
resource "random_pet" "bastion_name" {}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "t2.micro"
  availability_zone           = var.availability_zone
  key_name                    = "terraform_ec2_key"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion-sg.id]
  associate_public_ip_address = true

  tags = {
    name = random_pet.bastion_name.id
    sla  = "exp"
    role = "bastion"
  }
}

# Security Groups - bastion
resource "aws_security_group" "bastion-sg" {
  name        = "${random_pet.bastion_name.id}-sg"
  description = "allow inbound ssh traffic"
  vpc_id      = aws_vpc.mytf.id
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

resource "aws_vpc_security_group_egress_rule" "allow_all_bastion_traffic_ipv4" {
  security_group_id = aws_security_group.bastion-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
