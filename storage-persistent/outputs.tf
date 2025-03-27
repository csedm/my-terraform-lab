output "aws_efs_vpc_id" {
  value     = data.tfe_outputs.network_core_outputs.values.aws_vpc_id
  sensitive = true
}
output "efs_file_system_id" {
  value = aws_efs_file_system.mgt-efs.id
}
output "efs_file_system_mount_target" {
  value = aws_efs_mount_target.mgt-efs-mt
}
output "aws_efs_security_group_id" {
  value = aws_security_group.efs-sg.id
}
output "aws_subnet_efs" {
  description = "subnet-efs subnet information"
  value = {
    id                   = aws_subnet.subnet-efs.id
    cidr_block           = aws_subnet.subnet-efs.cidr_block
    ipv6_cidr_block      = aws_subnet.subnet-efs.ipv6_cidr_block
    availability_zone    = aws_subnet.subnet-efs.availability_zone
    availability_zone_id = aws_subnet.subnet-efs.availability_zone_id
  }
}