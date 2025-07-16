variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "ec2_instances" {
  description = "Map of EC2 instances to create"
  type = map(object({
    instance_type        = string
    instance_description = optional(string)
    availability_zone    = string
    ip_host              = number
  }))
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet"
  type        = string
}

variable "network_name" {
  description = "Network name for the security group"
  type        = string
}

variable "allow_firewall_rules" {
  description = "Map of allow firewall rules"
  type = map(object({
    protocol         = string
    ports            = optional(list(string))
    priority         = number
    description      = string
    source_ip_ranges = list(string)
  }))
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
