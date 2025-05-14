# my-terraform-lab
# author: @csedm

provider "aws" {
  region = var.region
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
