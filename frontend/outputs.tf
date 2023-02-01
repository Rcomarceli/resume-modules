
output "aws_s3_bucket_website_endpoint_add_to_cloudflare_worker_js" {
  value       = aws_s3_bucket_website_configuration.application.website_endpoint
  description = "The endpoint of the website s3 bucket"
}