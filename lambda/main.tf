
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

data "archive_file" "lambda_update_visitor_counter" {
  type = "zip"

  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda_update_visitor_counter.zip"
}

resource "aws_s3_object" "lambda_update_visitor_counter" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "lambda_update_visitor_counter.zip"
  source = data.archive_file.lambda_update_visitor_counter.output_path

  etag = filemd5(data.archive_file.lambda_update_visitor_counter.output_path)
}


# use lambda archive in s3 bucket to define lambda function

resource "aws_lambda_function" "update_visitor_counter" {
  function_name = "update_visitor_counter"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_update_visitor_counter.key

  runtime = "python3.9"
  handler = "update_visitor_counter.lambda_handler"

  source_code_hash = data.archive_file.lambda_update_visitor_counter.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      DATABASE_NAME = aws_dynamodb_table.website_db.name
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
        Resource = aws_dynamodb_table.website_db.arn
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

