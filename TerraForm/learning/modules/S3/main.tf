resource "aws_s3_bucket" "static_sitee" {
  bucket = var.bucket_name
  tags = {
    Name        = "MyStaticSiteBucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_website_configuration" "static_sitee_config" {
  bucket = aws_s3_bucket.static_sitee.id
  index_document {
    suffix = var.main_page_suffix
  }
  error_document {
    key = var.not_found_page
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.static_sitee.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

}
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.static_sitee.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_sitee.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.public_access_block]
}
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static_sitee.bucket
  key          = var.main_page_suffix
  source       = "${path.module}/files/${var.main_page_suffix}"
  content_type = "text/html"
}

resource "aws_s3_object" "not_found_page_404_html" {
  bucket       = aws_s3_bucket.static_sitee.bucket
  key          = var.not_found_page
  source       = "${path.module}/files/${var.not_found_page}"
  content_type = "text/html"
}
