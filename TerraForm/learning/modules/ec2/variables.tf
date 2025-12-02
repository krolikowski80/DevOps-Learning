# ==============================================================================
# EC2 MODULE - INPUT VARIABLES
# ==============================================================================

## VPC networking - from VPC module outputs
variable "vpc_id" {
  description = "ID of the VPC where EC2 instances will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "Map of public subnet IDs from VPC module"
  type        = map(string)
}

variable "private_subnet_ids" {
  description = "Map of private subnet IDs from VPC module"
  type        = map(string)
}

## Instance configuration
variable "environment" {
  description = "Environment name for tagging and naming"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for all instances"
  type        = string
  default     = "t3.micro"
}


## AMI ID - image do użycia na instances
variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0e2c8caa4b6378d8c" # Ubuntu 22.04 LTS eu-central-1
}

## Project name dla tagging consistency
variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "terraform-learning"
}
## SSH Key path - używa existing AWS key
variable "public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa_AWS.pub" # Twój existing key
}
