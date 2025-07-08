variable "name" {
  description = "Environment name"
  type        = string
}

variable "description" {
  description = "Environment description"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnets"
  type = map(object({
    cidr                    = string
    availability_zone       = string
    map_public_ip_on_launch = bool
  }))
}

variable "private_subnets" {
  description = "Map of private subnets"
  type = map(object({
    cidr                    = string
    availability_zone       = string
    map_public_ip_on_launch = bool
  }))
}

variable "aws_region" {
  description = "AWS region for the environment"
  type        = string
}

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
