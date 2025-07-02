variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string

}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string

}
