terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.52"
    }
  }

  required_version = ">= 1.2.0"

}

provider "aws" {
  default_tags {
    tags = {
      Terraform   = true
      Environment = "sandbox"
    }
  }
  region = "us-east-1"
}

module "frontend" {
  # source = "../../modules/frontend"
  source = "../../frontend"

  bucket_name      = var.bucket_name
  api_url          = var.api_url
  allowed_ip_range = var.allowed_ip_range
  #   api_url     = module.backend.api_url
  #   bucket_name = random_pet.website_bucket_name.id
  # environment = var.environment
}