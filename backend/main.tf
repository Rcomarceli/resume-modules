# database

resource "aws_dynamodb_table" "update_visitor_counter" {
  name         = var.database_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

}

# lambda


resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.lambda_bucket_name
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

data "archive_file" "lambda_code" {
  type = "zip"

  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda_code.zip"
}

resource "aws_s3_object" "lambda_code" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "lambda_code.zip"
  source = data.archive_file.lambda_code.output_path

  etag = filemd5(data.archive_file.lambda_code.output_path)
}


# use lambda archive in s3 bucket to define lambda function

resource "aws_lambda_function" "update_visitor_counter" {
  function_name = "update_visitor_counter"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_code.key

  runtime = "python3.9"
  handler = "update_visitor_counter.lambda_handler"

  source_code_hash = data.archive_file.lambda_code.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      DATABASE_NAME = aws_dynamodb_table.update_visitor_counter.name
    }
  }
}

resource "aws_cloudwatch_log_group" "update_visitor_counter" {
  name = "/aws/lambda/${aws_lambda_function.update_visitor_counter.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })

  # gonna need to refactor this somehow so we dont have to manually supply the arn
  # im thinking of an initial terraform file to create the needed user roles and permissions
  # then the main terraform file will use those same user roles and permissions to do the rest
  permissions_boundary = var.scope_permissions_arn
}

resource "aws_iam_policy" "database_access" {
  name        = "database-access"
  description = "Gives access to a lambda function to perform actions on dynamodb"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.update_visitor_counter.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "database_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.database_access.arn
}


# api
resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "update_visitor_counter" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.update_visitor_counter.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "update_visitor_counter" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /${var.update_visitor_counter_path}"
  target    = "integrations/${aws_apigatewayv2_integration.update_visitor_counter.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

