output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.mytf.id
}
output "aws_vpc_ipv4_cidr_block" {
  description = "AWS VPC IPv4 CIDR Block"
  value       = aws_vpc.mytf.cidr_block
}
output "aws_vpc_ipv6_cidr_block" {
  value = aws_vpc.mytf.ipv6_cidr_block
}
output "aws_vpc_ipv6_cidr_block_network_border_group" {
  value = aws_vpc.mytf.ipv6_cidr_block_network_border_group
}
output "aws_subnet_public" {
  description = "Public subnet information"
  value = {
    id                   = aws_subnet.public.id
    cidr_block           = aws_subnet.public.cidr_block
    ipv6_cidr_block      = aws_subnet.public.ipv6_cidr_block
    availability_zone    = aws_subnet.public.availability_zone
    availability_zone_id = aws_subnet.public.availability_zone_id
  }
}
output "aws_subnet_private" {
  description = "Private subnet information"
  value = {
    id                   = aws_subnet.private.id
    cidr_block           = aws_subnet.private.cidr_block
    ipv6_cidr_block      = aws_subnet.private.ipv6_cidr_block
    availability_zone    = aws_subnet.private.availability_zone
    availability_zone_id = aws_subnet.private.availability_zone_id
  }
}
output "bastion_public_ipv4_address" {
  value = aws_instance.bastion.public_ip
}
output "bastion_public_ipv6_address" {
  value = aws_instance.bastion.ipv6_addresses[0]
}
output "bastion_security_group_id" {
  value = aws_security_group.bastion-sg.id
}
/*
output "mgt_private_ip" {
  value = aws_instance.mgt.private_ip
}
*/
/*
output "efs_file_system_id" {
  value = aws_efs_file_system.mgt-efs.id
}
*/