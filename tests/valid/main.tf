# stub program used in github actions. allows us to use terraform validate on modules without "missing required provider" 
# or using empty provider blocks and triggering warnings
# why test like this: https://github.com/hashicorp/terraform/issues/28490
# official terraform hacky way of running terraform validate on modules since they need to work on a native way


terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.52"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

# A placeholder provider configuration
provider "aws" {
  region = "us-east-1"
}

module "frontend" {
  source = "../../frontend"
  

  bucket_name = "testing_placeholder"
  # (valid placeholder values for any required arguments)

  providers = {
    aws = aws
    # cloudflare = cloudflare
  }
}

module "dns" {
  source = "../../dns"
  
  cloudflare_zone_id = "testing_placeholder"
  cloudflare_domain = "testing_placeholder"
  cloudflare_account_id = "testing_placeholder"
}

