variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "subnet_cidrs" {
  description = "List of CIDR blocks for subnets"
  type        = list(string)
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "aws_availability_zones" {
  description = "List of AWS availability zones to use for subnets"
  type        = list(string)

}

variable "aws_region" {
  description = "AWS region to deploy the VPC"
  type        = string
}
