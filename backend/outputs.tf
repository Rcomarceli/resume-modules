output "entire_api_url" {
  description = "URL to be put into the index.html javascript portion"

  value = "${aws_apigatewayv2_stage.lambda.invoke_url}/${var.update_visitor_counter_path}"
}
