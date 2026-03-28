// Outputs for ECS web-poc nginx module

output "web_poc_service_name" {
  value = aws_ecs_service.web_poc.name
}

output "web_poc_dns_record" {
  value = cloudflare_dns_record.web_poc_record.name
}
