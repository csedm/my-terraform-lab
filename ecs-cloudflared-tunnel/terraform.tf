terraform {
  required_version = ">= 1.11.0"
  cloud {
    organization = "my-terraform-lab-csedm"
    workspaces {
      tags = ["mytflab", "ecs-cloudflared-tunnel"]
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 3.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.42"
    }
  }
}
