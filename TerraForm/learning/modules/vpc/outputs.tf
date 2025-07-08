output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.vpc.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [for subnet in aws_subnet.public_subnet : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [for subnet in aws_subnet.private_subnet : subnet.id]
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}
