resource "aws_s3_bucket" "terraform_state" {
  bucket_prefix = "terraform-state-${var.bucket_name_suffix}-${var.environment}-"

  tags = {
    Name        = "terraform-state-${var.bucket_name_suffix}-${var.environment}"
    Environment = var.environment
    Purpose     = "terraform-remote-state"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.table_name}-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "${var.table_name}-${var.environment}"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_lifecycle" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id      = "expire-terraform-state"
    status = "Enabled"
  transition {
      days          = 30
      storage_class = "GLACIER"
    }
    filter {}
    expiration {
      days = var.lifecycle_expiration_days
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_public_access_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = var.block_public_acls
  ignore_public_acls      = var.ignore_public_acls
  block_public_policy     = var.block_public_policy
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket" "log_bucket" {
  bucket = "log-state-${var.bucket_name_suffix}-${var.environment}"

  tags = {
    environment = var.environment
    purpose     = "state-logging"
  }
}

resource "aws_s3_bucket_logging" "terraform_state_logging" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "logs_tf_state_${var.environment}/"
}