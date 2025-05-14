output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.mytf.id
}
output "aws_vpc_ipv4_cidr_block" {
  description = "AWS VPC IPv4 CIDR Block"
  value       = aws_vpc.mytf.cidr_block
}
output "aws_vpc_ipv6_cidr_block" {
  description = "AWS VPC IPv6 CIDR Block"
  value = aws_vpc.mytf.ipv6_cidr_block
}
output "aws_vpc_ipv6_cidr_block_network_border_group" {
  description = "Network Border Group for IPv6 CIDR Block"
  value = aws_vpc.mytf.ipv6_cidr_block_network_border_group
}
output "aws_subnets_public" {
  description = "Public subnets information"
  value = [
    for subnet in aws_subnet.public :
    {
      id                   = subnet.id
      cidr_block           = subnet.cidr_block
      ipv6_cidr_block      = subnet.ipv6_cidr_block
      availability_zone    = subnet.availability_zone
      availability_zone_id = subnet.availability_zone_id
    }
  ]
}
output "aws_subnet_private" {
  description = "Private subnets information"
  value = [
    for subnet in aws_subnet.private :
    {
      id                   = subnet.id
      cidr_block           = subnet.cidr_block
      ipv6_cidr_block      = subnet.ipv6_cidr_block
      availability_zone    = subnet.availability_zone
      availability_zone_id = subnet.availability_zone_id
    }
  ]
}
