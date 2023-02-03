# stub program used in github actions. allows us to use terraform validate on modules without "missing required provider" 
# or using empty provider blocks and triggering warnings
# why test like this: https://github.com/hashicorp/terraform/issues/28490
# official terraform hacky way of running terraform validate on modules since they need to work on a native way


terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.52"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
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


  bucket_name = ""
  api_url     = ""
  # (valid placeholder values for any required arguments)

  providers = {
    aws = aws
    # cloudflare = cloudflare
  }
}

module "dns" {
  source = "../../dns"

  environment           = ""
  cloudflare_zone_id    = ""
  cloudflare_domain     = ""
  cloudflare_account_id = ""
  website_endpoint      = ""
  website_bucket_arn    = ""
  website_bucket_id     = ""
}

module "backend" {
  source = "../../backend"

  scope_permissions_arn       = ""
  update_visitor_counter_path = ""
  lambda_bucket_name          = ""
  database_name               = ""
  cloudflare_domain           = ""
}

