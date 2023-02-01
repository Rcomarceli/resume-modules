# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

# lambda bucket name here. 

# resource "random_pet" "lambda_bucket_name" {
#   prefix = "terraform-lambda"
#   length = 4
# }

variable "scope_permissions_arn" {
  description = "ARN of the permission boundary that *should* be on the terraform user"
  type        = string
}

variable "update_visitor_counter_path" {
  default = "updateVisitorCounter"
  type    = string
}
