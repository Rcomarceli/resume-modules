terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.52"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  default_tags {
    tags = {
      Terraform   = true
      Environment = var.environment
    }
  }
  region = "us-east-1"
}

resource "random_pet" "website_bucket_name" {
  prefix = var.website_bucket_name
  length = 4
}

module "frontend" {
  source = "../../frontend"
  # source = "${path.module}/../frontend"

  website_bucket_name      = random_pet.website_bucket_name.id
  api_url          = var.api_url
  allowed_ip_range = var.allowed_ip_range
  #   api_url     = module.backend.api_url
  #   bucket_name = random_pet.website_bucket_name.id
  # environment = var.environment
}