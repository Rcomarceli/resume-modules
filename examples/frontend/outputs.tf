
output "website_endpoint" {
  value       = module.frontend.website_endpoint
  description = "The website endpoint of the website s3 bucket"
}

# output "website_html_etag" {
#   value = module.frontend.website_html_etag
#   description = "The Rendered index.html code. Used for testing"
# }