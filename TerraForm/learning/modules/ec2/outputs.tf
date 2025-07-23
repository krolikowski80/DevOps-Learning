# ==============================================================================
# EC2 MODULE - OUTPUT VALUES  
# ==============================================================================

output "public_instance_id" {
  description = "ID of the public EC2 instance"
  value       = aws_instance.public.id
}

output "public_instance_ip" {
  description = "Public IP of the web/bastion instance"
  value       = aws_instance.public.public_ip
}

output "private_instance_ids" {
  description = "Map of private instance IDs"
  value       = { for k, v in aws_instance.private : k => v.id }
}

output "private_instance_ips" {
  description = "Map of private instance IPs"
  value       = { for k, v in aws_instance.private : k => v.private_ip }
}
