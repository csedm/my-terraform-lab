// Outputs for ECS cloudflared tunnel module

output "cloudflared_tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

output "cloudflared_tunnel_name" {
  value = cloudflare_zero_trust_tunnel_cloudflared.tunnel.name
}

output "cloudflared_tunnel_token" {
  value     = data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel.token
  sensitive = true
}

output "ecs_service_name" {
  value = aws_ecs_service.cloudflared_tunnel.name
}

output "cloudflared_tunnel_sg_id" {
  value = aws_security_group.cloudflared_tunnel_sg.id
}

output "cloudflared_tunnel_config" {
  value = cloudflare_zero_trust_tunnel_cloudflared_config.shared.config
}