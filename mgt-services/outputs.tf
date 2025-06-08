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

module "ssm_parameters" {
  source = "cloudposse/ssm-parameter-store/aws"
  version = "0.13.0"

  parameter_write = [
    {
      name = "/${var.origin_repo}/${local.environment}/bastion_host"
      value = aws_instance.bastion.public_ip
      type = "String"
    },
    {
      name = "/${var.origin_repo}/${local.environment}/bastion_host_ipv6"
      value = aws_instance.bastion.ipv6_addresses[0]
      type = "String"
    }
  ]
}