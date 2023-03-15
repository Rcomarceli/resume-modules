
# just have the security baked in (same for all env) for the website policy so we can test the website endpoint via github
terraform {
  # require any 1.x version of Terraform
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.52"
    }
  }

}


resource "aws_s3_bucket" "application" {
  bucket = var.website_bucket_name
}

resource "aws_s3_bucket_policy" "application" {
  bucket = aws_s3_bucket.application.id
  policy = data.aws_iam_policy_document.application.json
}

data "aws_iam_policy_document" "application" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.application.arn}/*"
    ]
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.allowed_ip_range
    }
  }
}


resource "aws_s3_bucket_website_configuration" "application" {
  bucket = aws_s3_bucket.application.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}


# this basically forces the code to only run on linux
# generates env file for our vite build. used to inject the api_url when building in the pipeline
# outputs a "dest" value that points to our "dist" build folder
data "external" "application" {
  program = ["bash", "/generateEnv.sh"]

  working_dir = "${path.module}/src"
  query = {
    API_URL = var.api_url
  }
}


resource "aws_s3_bucket_object" "application" {
  for_each = fileset("${data.external.application.working_dir}/${data.external.application.result.dest}", "*")
  key      = each.value
  source   = "${data.external.application.working_dir}/${data.external.application.result.dest}/${each.value}"
  bucket   = aws_s3_bucket.application.bucket

  etag = filemd5("${data.external.application.working_dir}/${data.external.application.result.dest}/${each.value}")

  # compare file extension to known file extension mime types, default to application/octet if not found
  content_type = lookup(local.mime_type_mappings, regex("[^.]+$", each.value), "application/octet-stream")
}

# source: https://advancedweb.hu/how-to-deploy-a-single-page-application-with-terraform/