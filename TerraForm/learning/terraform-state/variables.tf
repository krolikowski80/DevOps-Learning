# ==============================================================================
# TERRAFORM STATE BUCKET - BOOTSTRAP VARIABLES
# ==============================================================================
# Bootstrap module do tworzenia shared infrastructure dla remote state
# Używane tylko raz na początku projektu, potem wszystkie env używają tego bucket

## Environment identifier - dla tego bootstrap będzie 'shared' lub 'bootstrap'
variable "environment" {
  description = "Environment name for state bucket"
  type        = string
}

## Region gdzie będzie state bucket - najlepiej us-east-1 (najtańszy)
variable "region" {
  description = "AWS region for state bucket"
  type        = string
}

## Unikalny suffix żeby bucket name był globalnie unique w S3
variable "bucket_name_suffix" {
  description = "Unique suffix for bucket name"
  type        = string
}
