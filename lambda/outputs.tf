
output "aws_s3_bucket_lambda_name" {
  value       = aws_s3_bucket.lambda_bucket.arn
  description = "ARN of the lambda bucket"
}

output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.update_visitor_counter.function_name
}