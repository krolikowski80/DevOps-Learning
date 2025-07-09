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
