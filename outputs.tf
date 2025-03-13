output "aws_vpc_ipv6_cidr_block" {
  value = aws_vpc.mytf.ipv6_cidr_block
}
output "aws_vpc_ipv6_cidr_block_network_border_group" {
  value = aws_vpc.mytf.ipv6_cidr_block_network_border_group
}
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
output "mgt_private_ip" {
  value = aws_instance.mgt.private_ip
}
output "efs_file_system_id" {
  value = aws_efs_file_system.mgt-efs.id
}
