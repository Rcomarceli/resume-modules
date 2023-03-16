
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

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.application.bucket
  key    = "index.html"
  source = "${path.module}/src/${local.build_folder}/index.html"
  etag   = filemd5("${path.module}/src/${local.build_folder}/index.html")

  content_type = "text/html"
}

resource "aws_s3_object" "assets" {
  for_each = fileset("${path.module}/src/${local.build_folder}/assets", "*")
  key      = each.value
  source   = "${path.module}/src/${local.build_folder}/assets/${each.value}"
  bucket   = aws_s3_bucket.application.bucket

  etag = filemd5("${path.module}/src/${local.build_folder}/assets/${each.value}")

  # compare file extension to known file extension mime types, default to application/octet if not found
  content_type = lookup(local.mime_type_mappings, regex("[^.]+$", each.value), "application/octet-stream")
}

