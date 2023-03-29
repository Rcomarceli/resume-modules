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
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.2.0"

}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
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

terraform {

  cloud {
    organization = "rcomarceli-tutorial"

    workspaces {
      name = "terratest-resume-backend"
    }
  }
}


resource "random_pet" "lambda_bucket_name" {
  prefix = var.lambda_bucket_name
  length = 3
}

module "backend" {
  source = "../../backend"

  environment                 = var.environment
  scope_permissions_arn       = var.scope_permissions_arn
  update_visitor_counter_path = var.update_visitor_counter_path
  lambda_bucket_name          = random_pet.lambda_bucket_name.id
  database_name               = var.database_name
  cloudflare_domain           = var.cloudflare_domain
  cloudflare_zone_id          = var.cloudflare_zone_id
  cloudflare_account_id       = var.cloudflare_account_id
  function_name               = var.function_name
  lambda_iam_role_name        = var.lambda_iam_role_name
  lambda_iam_policy_name      = var.lambda_iam_policy_name
  api_gateway_name            = var.api_gateway_name
  api_gateway_stage_name      = var.api_gateway_stage_name
  lambda_permission_name      = var.lambda_permission_name
}