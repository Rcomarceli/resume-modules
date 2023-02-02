
output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.application.website_endpoint
  description = "The website endpoint of the website s3 bucket"
}

output "website_bucket_arn" {
  value       = aws_s3_bucket.application.arn
  description = "ARN of the website s3 bucket"
}

output "website_bucket_id" {
  value       = aws_s3_bucket.application.id
  description = "ID of the website s3 bucket"
}