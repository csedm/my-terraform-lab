output "mgt_private_ipv4_address" {
  value = aws_instance.mgt.private_ip
}
output "mgt_private_ipv6_address" {
  value = aws_instance.mgt.ipv6_addresses[0]
}
output "mgt_security_group_id" {
  value = aws_security_group.mgt-sg.id
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