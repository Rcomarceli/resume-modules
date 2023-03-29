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

# in this example, AWS credentials are fetched from environment variables
# AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
provider "aws" {
  default_tags {
    tags = {
      Terraform   = true
      Environment = var.environment
    }
  }
  region = "us-east-1"
}

terraform {

  cloud {
    organization = "rcomarceli-tutorial"

    workspaces {
      name = "terratest-resume-frontend"
    }
  }
}


resource "random_pet" "website_bucket_name" {
  prefix = var.website_bucket_name
  length = 3
}

module "frontend" {
  source = "../../frontend"

  website_bucket_name = random_pet.website_bucket_name.id
  api_url             = var.api_url
  allowed_ip_range    = var.allowed_ip_range
}