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

# www to non-www redirect
# https://developers.cloudflare.com/pages/how-to/www-redirect/

# note that since only 1 record of this can exist concurrently, we cant use this with a subdomain for testing
# to test this one redirect, had to buy another domain for testing 
resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  value   = "100::"
  type    = "AAAA"

  proxied = true
}


# requires edit permissions account.bulk url redirects? account.filter lists
# cloudflare likes to add a "/" to the end of the source_url even if we don't put it there
# so we add a "/" to the end. if not, we keep getting errors where terraform will keep trying to update this resource in place.
# reworking www redirect portion to just be zone level because account level redirect cant be tested without collision


resource "cloudflare_list" "www" {
  account_id  = var.cloudflare_account_id
  name        = "wwwredirect_${var.environment}"
  description = "redirects www to non-www"
  kind        = "redirect"

  item {
    value {
      redirect {
        source_url            = "www.${var.cloudflare_domain}/"
        target_url            = "https://${var.cloudflare_domain}"
        include_subdomains    = "disabled"
        subpath_matching      = "enabled"
        status_code           = 301
        preserve_query_string = "enabled"
        preserve_path_suffix  = "enabled"
      }
    }
  }
}

resource "cloudflare_ruleset" "www" {
  # account_id  = var.cloudflare_account_id
  account_id  = var.cloudflare_zone_id
  name        = "redirects_${var.environment}"
  description = "Redirect ruleset"
  kind        = "root"
  phase       = "http_request_redirect"

  rules {
    action = "redirect"
    action_parameters {
      from_list {
        name = cloudflare_list.www.name
        key  = "http.request.full_uri"
      }
    }

    # expression below is interpreted. we want a literal "$name_of_cloudflare_list"
    # but double $'s is a special escape sequence in HCL
    # so we opt for this redundant way to preserve the $ in front
    # and the interpolated cloudflare_list.www_name after that
    expression  = "http.request.full_uri in ${"$"}${cloudflare_list.www.name}"
    description = "Apply redirects from redirect list"
    enabled     = true
  }
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

# currently, there is no terraform support for different environments
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

# edit bucket to allow for cloudflare access
# refactor this so we add it on to the existing bucket permissions rather than defining the entire thing

# resource "aws_s3_bucket_policy" "allow_access_from_cloudflare" {
#   bucket = var.website_bucket_id
#   policy = data.aws_iam_policy_document.allow_access_from_cloudflare.json
# }

# data "aws_iam_policy_document" "allow_access_from_cloudflare" {
#   statement {
#     sid    = "PublicReadGetObject"
#     effect = "Allow"
#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }
#     actions = [
#       "s3:GetObject"
#     ]
#     resources = [
#       "${var.website_bucket_arn}/*"
#       # aws_s3_bucket.application.arn,
#     ]
#     condition {
#       test     = "IpAddress"
#       variable = "aws:SourceIp"

#       values = local.cloudflare_ip_range
#     }
#   }
# }
