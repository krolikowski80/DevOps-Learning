output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = [for subnet in aws_subnet.main : subnet.id]
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "subnet_cidrs" {
  description = "List of CIDR blocks for the subnets"
  value       = [for subnet in aws_subnet.main : subnet.cidr_block]
}

output "availability_zones" {
  description = "List of availability zones used for the subnets"
  value       = var.aws_availability_zones
}

output "aws_region" {
  description = "value of the AWS region"
  value       = var.aws_region
}
