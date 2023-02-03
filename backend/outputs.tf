# api

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.lambda.invoke_url
}

output "entire_api_url" {
  description = "URL to be put into the index.html javascript portion"

  value = "${aws_apigatewayv2_stage.lambda.invoke_url}/${var.update_visitor_counter_path}"
}

# lambda


output "aws_s3_bucket_lambda_name" {
  value       = aws_s3_bucket.lambda_bucket.arn
  description = "ARN of the lambda bucket"
}

output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.update_visitor_counter.function_name
}