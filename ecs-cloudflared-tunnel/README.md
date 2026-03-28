# ecs-cloudflared-tunnel

Terraform module to deploy a dedicated ECS Fargate service running Cloudflare Tunnel (cloudflared) as a scalable, shared ingress point for your AWS VPC. This module:

- Creates an ECS task definition and service for cloudflared
- Provisions a Cloudflare Tunnel
- Uses HCP Terraform outputs to join the same ECS cluster as your app workloads
- Supports environment selection via workspace naming
- Conservative auto-scaling: desired count 2, scales down to 0 when idle

**Note:** This module does not create DNS records, Zero Trust applications, or app-specific policies. Use this for shared ingress only.
