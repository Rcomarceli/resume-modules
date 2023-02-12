
output "website_endpoint" {
  description = "The website endpoint of the website s3 bucket"
  value       = module.frontend.website_endpoint
}

output "api_url" {
  description = "URL to be put into the index.html javascript portion"
  value       = module.backend.api_url
}
