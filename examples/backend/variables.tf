# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "environment" {
  description = "The name of the environment we're deploying to. Either Sandbox, Dev, or Prod"
  type        = string
}

# api
variable "scope_permissions_arn" {
  description = "ARN of the permission boundary that *should* be on the terraform user"
  type        = string
}

variable "update_visitor_counter_path" {
  default = "updateVisitorCounter"
  type    = string
}

variable "lambda_bucket_name" {
  description = "The name of the s3 bucket containing the lambda code"
  type        = string
}

variable "database_name" {
  description = "Name of the DB used to hold the visitor counter"
  type        = string
}

variable "cloudflare_domain" {
  description = "Domain name to be used for accessing the website"
  type        = string
}

variable "function_name" {
  description = "Lambda Function Name"
  type        = string
}

variable "lambda_iam_role_name" {
  description = "Name for Lambda IAM Role. Used for permissions for the lambda function"
  type        = string
}

variable "lambda_iam_policy_name" {
  description = "Name for Lambda IAM Policy. Attached to Lambda Role"
  type        = string
}

variable "api_gateway_name" {
  description = "Name for API Gateway"
  type        = string
}

variable "api_gateway_stage_name" {
  description = "Name for API Gateway Stage"
  type        = string
}

variable "lambda_permission_name" {
  description = "Name for lambda permission"
  type        = string
}