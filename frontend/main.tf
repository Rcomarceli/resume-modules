
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
      values = var.allowed_ip_range
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

  # routing_rule {
  #   condition {
  #     key_prefix_equals = "docs/"
  #   }
  #   redirect {
  #     replace_key_prefix_with = "documents/"
  #   }
  # }
}

resource "aws_s3_object" "html_index" {
  bucket = aws_s3_bucket.application.id
  key    = "index.html"
  # source = "${path.module}/src/index.html"
  content = templatefile("${path.module}/index.html.tftpl", { "api_url" = var.api_url })
  # content type defaults to binary/octetstream which prompts the user to download the html file rather than view it
  content_type = "text/html"

  # etag = filemd5("${path.module}/src/index.html")
  etag = md5(templatefile("${path.module}/index.html.tftpl", { "api_url" = var.api_url }))
}

resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.application.id
  key          = "index.css"
  source       = "${path.module}/src/index.css"
  content_type = "text/css"

  etag = filemd5("${path.module}/src/index.css")
}
