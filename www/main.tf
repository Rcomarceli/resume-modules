# this module redirects www requests to the non-www version of the site
# It has been split into its own module because this will only be used in production, not development
# during development, we will use the "dev" subdomain, and using "www" for a subdomain is a lot more involved 

terraform {
  # require any 1.x version of Terraform
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }

  }

}

# www to non-www redirect
# https://developers.cloudflare.com/pages/how-to/www-redirect/

# note that since only 1 record of this can exist concurrently, we cant use this with a subdomain for testing
resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  value   = "100::"
  type    = "AAAA"

  proxied = true
}


resource "cloudflare_page_rule" "www" {
  zone_id = var.cloudflare_zone_id
  target  = "www.${var.cloudflare_domain}/*"

  actions {
    forwarding_url {
      # $1 allows us to match and keep any routes
      url         = "https://${var.cloudflare_domain}/$1"
      status_code = 301
    }
  }
}