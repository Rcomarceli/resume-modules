terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Terraform   = true
      Environment = var.environment
    }
  }
}

resource "random_pet" "website_bucket_name" {
  prefix = var.website_bucket_name
  length = 4
}

# api token defined in terraform cloud
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "frontend" {
  source = "../../frontend"
  #   source = "${path.module}/../frontend"

  #  api url wont be tested, so it can be a fake URL in this case
  api_url             = var.api_url
  website_bucket_name = random_pet.website_bucket_name.id
}

module "dns" {
  source = "../../dns"
  #   source = "${path.module}/../dns"

  # all defined in the terraform cloud org as environment variables
  environment        = var.environment
  cloudflare_zone_id = var.cloudflare_zone_id
  cloudflare_domain  = var.cloudflare_domain
  # cloudflare_api_token  = var.cloudflare_api_token
  cloudflare_account_id = var.cloudflare_account_id
  website_endpoint      = module.frontend.website_endpoint
  website_bucket_arn    = module.frontend.website_bucket_arn
  website_bucket_id     = module.frontend.website_bucket_id
}