terraform {
  # require any 1.x version of Terraform
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }

    # aws provider used to allow cloudflare to reach s3 bucket
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

}

# this module depends on a frontend module for testing, since we need to point the domain name to an actual website

resource "cloudflare_record" "site_cname" {
  zone_id = var.cloudflare_zone_id
  name    = var.cloudflare_domain
  value   = var.website_endpoint
  type    = "CNAME"

  ttl     = 1
  proxied = true
}

# ensure API key has edit permissions for: Zone Settings
# Looks like you encounter a bug if you attempt to use this and have an initial failure (such as permissions),
# Once you fix the config issue, you'll run into issues where it'll flag read-only resources being attempted to be written over
# removing this resource via "terraform rm cloudflare_zone_settings_override.application" and applying again is a work around

resource "cloudflare_zone_settings_override" "application" {
  zone_id = var.cloudflare_zone_id
  settings {
    ssl              = "flexible"
    always_use_https = "on"
  }
}

# cloudflare worker
# Without this, requests to the website would result in "bucket does not exist" even though the going directly to the endpoint works fine
# The problem is that aws uses the host header to determine what the bucket should be if being redirected. in our case, it was looking for a bucket called "rcmarceli.com"
# a work around is to rename our bucket to always be rcmarceli.com, or to use cloudflare workers to change how the website is fetched
# source https://advancedweb.hu/how-to-route-to-an-arbitrary-s3-bucket-website-with-cloudflare-workers/
# ensure that your API key has Edit Permissions: Account.Workers KV Storage?, Account.Workers Scripts, Zone.Worker Routes or else youll get Authentication errors (10000)

# currently, there is no terraform support for different environments in cloudflare
# we will need to append our environment variable to the name instead
resource "cloudflare_worker_script" "change_header" {
  account_id = var.cloudflare_account_id
  name       = "terraform-change-resume-host-header-${var.environment}"
  content    = file("${path.module}/cloudflare_worker/change_header.js")

  plain_text_binding {
    name = "website_endpoint"
    text = var.website_endpoint
  }

}

resource "cloudflare_worker_route" "change_header" {
  zone_id     = var.cloudflare_zone_id
  pattern     = "${var.cloudflare_domain}/*"
  script_name = cloudflare_worker_script.change_header.name
}