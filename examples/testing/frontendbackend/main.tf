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


resource "random_pet" "lambda_bucket_name" {
  prefix = var.lambda_bucket_name
  length = 4
}

module "backend" {
  source = "../../../backend"
  # source = "${path.module}/../backend"

  scope_permissions_arn       = var.scope_permissions_arn
  update_visitor_counter_path = var.update_visitor_counter_path
  lambda_bucket_name          = random_pet.lambda_bucket_name.id
  database_name               = var.database_name
  cloudflare_domain           = var.cloudflare_domain
  function_name               = var.function_name
  lambda_iam_role_name        = var.lambda_iam_role_name
  lambda_iam_policy_name      = var.lambda_iam_policy_name
  api_gateway_name            = var.api_gateway_name
  api_gateway_stage_name      = var.api_gateway_stage_name
  lambda_permission_name      = var.lambda_permission_name

}

resource "random_pet" "website_bucket_name" {
  prefix = var.website_bucket_name
  length = 4
}

module "frontend" {
  source = "../../../frontend"
  # source = "${path.module}/../frontend"

  website_bucket_name = random_pet.website_bucket_name.id
  api_url             = module.backend.api_url
  allowed_ip_range    = var.allowed_ip_range
  #   api_url     = module.backend.api_url
  #   bucket_name = random_pet.website_bucket_name.id
  # environment = var.environment
}
