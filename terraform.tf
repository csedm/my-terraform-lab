terraform {
  required_version = ">= 1.11.0"
  cloud {
      organization = "my-terraform-lab-csedm"
      workspaces {
        #name = "my-terraform-lab"
        tags = ["my-terraform-lab"]
      }
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}