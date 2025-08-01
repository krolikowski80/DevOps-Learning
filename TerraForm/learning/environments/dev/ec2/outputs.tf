output "instance_private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = module.ec2_firewall.instance_ips
}

output "instance_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = module.ec2_firewall.instance_public_ips
}

output "instance_names" {
  description = "Names of EC2 instances"
  value       = module.ec2_firewall.instance_names
}
