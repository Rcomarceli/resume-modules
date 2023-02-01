terraform {
  required_providers {
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

terraform {
  backend "s3" {
    bucket         = "resume-frontend-state-bucket-finally-cuddly-worm"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"

    shared_credentials_file  = "C:/Users/bboym/.aws/credentials"
    profile                  = "terraform"

    dynamodb_table = "resume-frontend-state-locks-highly-saving-opossum"
    encrypt        = true
  }
}