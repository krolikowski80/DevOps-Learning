variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
}

variable "main_page_suffix" {
  description = "The suffix for the main page of the static site"
  type        = string

}
variable "not_found_page" {
  description = "The name of the 404 not found page"
  type        = string
}
