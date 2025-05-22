terraform {
  required_version = ">= 1.11.0"
  cloud {
    organization = "my-terraform-lab-csedm"
    workspaces {
      #name = "my-terraform-lab"
      tags = ["mytflab", "mgt-services"]
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.64.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}