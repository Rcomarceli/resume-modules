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

resource "random_pet" "website_bucket_name" {
  prefix = var.website_bucket_name
  length = 3
}

resource "random_pet" "lambda_bucket_name" {
  prefix = var.lambda_bucket_name
  length = 3
}

terraform {

  cloud {
    organization = "rcomarceli-tutorial"

    workspaces {
      name = "terratest-resume-integration"
    }
  }
}


module "frontend" {
  source = "../../frontend"

  website_bucket_name = random_pet.website_bucket_name.id
  api_url             = module.backend.api_url //change this to output
  allowed_ip_range    = var.allowed_ip_range
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

module "dns" {
  source = "../../dns"

  # in live, these are defined in terraform cloud. for testing, we define them via repo secrets/variables
  environment           = var.environment
  cloudflare_zone_id    = var.cloudflare_zone_id
  cloudflare_domain     = var.cloudflare_domain
  cloudflare_account_id = var.cloudflare_account_id
  website_endpoint      = module.frontend.website_endpoint
}

module "www" {
  source = "../../www"

  cloudflare_zone_id = var.cloudflare_zone_id
  cloudflare_domain  = var.cloudflare_domain
}