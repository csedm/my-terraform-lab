output "mgt_private_ipv4_address" {
  value = aws_instance.mgt.private_ip
}
output "mgt_private_ipv6_address" {
  value = aws_instance.mgt.ipv6_addresses[0]
}
output "mgt_security_group_id" {
  value = aws_security_group.mgt-sg.id
}