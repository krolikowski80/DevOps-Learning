# ==============================================================================
# VPC MODULE - OUTPUT VALUES
# ==============================================================================
# Te values będą dostępne dla caller'a (envs/dev/main.tf) jako module.vpc.xxx

## VPC ID - potrzebne dla security groups, EC2, RDS, etc
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

## Public subnet IDs - potrzebne dla Load Balancers, NAT Gateway, Bastion hosts
output "public_subnet_ids" {
  description = "Map of public subnet IDs"
  value       = { for k, v in aws_subnet.public : k => v.id }
}

## Private subnet IDs - potrzebne dla EC2 instances, RDS, ElastiCache
output "private_subnet_ids" {
  description = "Map of private subnet IDs"
  value       = { for k, v in aws_subnet.private : k => v.id }
}

## Internet Gateway ID - na wszelki wypadek dla custom routing
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

## NAT Gateway IDs - jeśli ktoś potrzebuje reference
output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}
