
# just have the security baked in (same for all env) for the website policy so we can test the website endpoint via github

resource "aws_s3_bucket" "application" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_acl" "application" {
  bucket = aws_s3_bucket.application.id

  acl = "public-read"
}


resource "aws_s3_bucket_website_configuration" "application" {
  bucket = aws_s3_bucket.application.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}

resource "aws_s3_object" "html_index" {
  bucket = aws_s3_bucket.application.id
  key    = "index.html"
  source = "${path.module}/src/index.html"
  # content type defaults to binary/octetstream which prompts the user to download the html file rather than view it
  content_type = "text/html"

  etag = filemd5("${path.module}/src/index.html")
}
resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.application.id
  key          = "index.css"
  source       = "${path.module}/src/index.css"
  content_type = "text/css"

  etag = filemd5("${path.module}/src/index.css")
}
