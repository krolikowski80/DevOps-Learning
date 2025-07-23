# ==============================================================================
# TERRAFORM STATE BUCKET MODULE - MAIN RESOURCES
# ==============================================================================
# Tworzy S3 bucket + DynamoDB table dla remote state storage + locking

## S3 Bucket - główne storage dla terraform state files
## Bucket name musi być globally unique w całym AWS
resource "aws_s3_bucket" "terraform_state" {
  bucket_prefix = "terraform-state-${var.bucket_name_suffix}-"

  tags = {
    Name        = "terraform-state-${var.bucket_name_suffix}"
    Environment = var.environment
    Purpose     = "terraform-remote-state"
  }
}

## S3 Bucket Versioning - żeby mieć historię zmian state
## Pozwala rollback do poprzednich wersji jeśli coś pójdzie nie tak
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

## S3 Bucket Public Access Block - zapobiega przypadkowemu public access
## State files zawierają sensitive data więc muszą być private
resource "aws_s3_bucket_public_access_block" "terraform_state_public_access_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

## S3 Bucket Lifecycle Configuration - automatyczne czyszczenie starych wersji
## Oszczędza koszty przez usuwanie bardzo starych state versions
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_lifecycle" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-terraform-state"
    status = "Enabled"
    filter {}
    expiration {
      days = var.lifecycle_expiration_days
    }

    # Przechowuj recent versions ale usuń bardzo stare
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

## DynamoDB Table - state locking żeby zapobiec concurrent modifications
## Prevents corruption gdy dwóch developerów robi terraform apply simultaneously
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.table_name}-${var.environment}"
  billing_mode = "PAY_PER_REQUEST" # Pay per operation, no fixed cost
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S" # String type
  }

  tags = {
    Name = "${var.table_name}-${var.environment}"
  }
}

# Dokumentacja S3 backend: https://www.terraform.io/language/settings/backends/s3
# Dokumentacja DynamoDB locking: https://www.terraform.io/language/settings/backends/s3#dynamodb-state-locking
