
# this may not be needed
output "website_endpoint" {
  value       = module.frontend.website_endpoint
  description = "The website endpoint of the website s3 bucket"
}