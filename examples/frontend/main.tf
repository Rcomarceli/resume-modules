module "frontend" {
  # source = "../../modules/frontend"
  source = "../../frontend"

  bucket_name = var.bucket_name
  api_url     = var.api_url
  allowed_ip_range = var.allowed_ip_range
#   api_url     = module.backend.api_url
#   bucket_name = random_pet.website_bucket_name.id
  # environment = var.environment
}

provider "aws" {
  version = "~> 4.16"
  default_tags {
    tags = {
      Terraform = true
      Environment = "sandbox"
    }
  }

  region = "us-east-1"
}