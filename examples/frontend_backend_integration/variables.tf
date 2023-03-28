# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "environment" {
  description = "The name of the environment we're deploying to. Either Sandbox, Dev, or Prod"
  type        = string
}

variable "website_bucket_name" {
  description = "The name of the s3 bucket containing the website code"
  type        = string
}

variable "api_url" {
  description = "API URL for incrementing visitor counter. Rendered into index.html"
  type        = string
}

variable "allowed_ip_range" {
  description = "The allowed IP range to the website S3 bucket. By default, uses allowed IPs from Cloudflare"
  type        = list(string)
  default = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22",
    "2400:cb00::/32",
    "2606:4700::/32",
    "2803:f800::/32",
    "2405:b500::/32",
    "2405:8100::/32",
    "2a06:98c0::/29",
    "2c0f:f248::/32"
  ]
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

variable "cloudflare_api_token" {
  description = "API Token used for Cloudflare"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone ID for Cloudflare Domain"
  type        = string
}

variable "cloudflare_account_id" {
  description = "The account ID for Cloudflare"
  type        = string
}