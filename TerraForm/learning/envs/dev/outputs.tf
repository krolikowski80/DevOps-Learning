# ==============================================================================
# DEV ENVIRONMENT - OUTPUT VALUES
# ==============================================================================
# Te outputs służą jako "API" naszej infrastruktury - pozwalają innym projektom
# lub team membersom używać naszych resources bez znajomości internal details.
# Są też przydatne do debugging i weryfikacji czy deployment się udał.

## VPC ID - najważniejszy output bo bez tego nie można tworzyć żadnych resources
## Używany przez: security groups, EC2 instances, RDS, load balancers, etc.
## Przykład użycia: "aws ec2 describe-instances --filters Name=vpc-id,Values=vpc-xxx"
output "vpc_id" {
  description = "ID of the VPC - needed for all resources in this network"
  value       = module.vpc.vpc_id
}

## VPC CIDR - przydatne do planowania nowych subnet'ów lub security group rules
## Pokazuje jaki range IP używamy, pomaga w conflict resolution z innymi VPC
## Przykład: jeśli mamy 10.0.0.0/16, to wiemy że możemy używać 10.0.x.x addresses
output "vpc_cidr" {
  description = "CIDR block of the VPC - useful for security group rules and peering"
  value       = var.vpc_cidr
}

## Public subnet IDs - gdzie deployować resources potrzebujące internet access
## Load balancers MUSZĄ być w public subnet żeby internet mógł do nich dotrzeć
## NAT Gateway też musi być w public subnet bo potrzebuje Internet Gateway
## Map format pozwala wybierać subnet po nazwie: subnet_ids["web"]
output "public_subnet_ids" {
  description = "Map of public subnet IDs - use for load balancers, NAT gateways, bastion hosts"
  value       = module.vpc.public_subnet_ids
}

## Private subnet IDs - gdzie deployować aplikacje i bazy danych dla bezpieczeństwa
## EC2 instances w private subnet nie mają direct internet access (security best practice)
## Mogą wychodzić do internetu przez NAT Gateway ale nikt nie może wejść z internetu
## Map format: można wybrać konkretny subnet dla konkretnego purpose (app vs db)
output "private_subnet_ids" {
  description = "Map of private subnet IDs - use for application servers and databases"
  value       = module.vpc.private_subnet_ids
}

## Internet Gateway ID - potrzebne jeśli ktoś chce custom routing do internetu
## Normalnie nie używamy tego bezpośrednio, ale przydatne do troubleshooting
## "Dlaczego mój resource nie ma internetu?" - sprawdź czy jest route do tego IGW
output "internet_gateway_id" {
  description = "ID of the Internet Gateway - for custom routing or troubleshooting"
  value       = module.vpc.internet_gateway_id
}

## NAT Gateway IDs - potrzebne do troubleshooting private subnet connectivity
## Kosztują ~$45/miesiąc więc important to track które istnieją
## Lista bo może być więcej niż jeden (multi-AZ setup)
output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs - expensive resources ($45/month each)"
  value       = module.vpc.nat_gateway_ids
}

## Environment name - przydatne w CI/CD pipelines i multi-env deployments
## Pozwala skryptom wiedzieć w jakim środowisku operują
## Przykład: "if environment == 'prod' then use encrypted storage"
output "environment" {
  description = "Environment name - useful for conditional logic in automation"
  value       = var.environment
}

## AWS Region - ważne dla cross-region operations i compliance
## Niektóre regulacje wymagają data w konkretnych regionach
## Przydatne też dla backup strategies (cross-region replication)
output "aws_region" {
  description = "AWS region where infrastructure is deployed - important for compliance"
  value       = var.aws_region
}

# Dokumentacja outputs: https://www.terraform.io/language/values/outputs
# Best practices: https://www.terraform.io/language/values/outputs#when-to-use-outputs

## EC2 Connection Information - ready-to-use SSH commands
output "public_instance_ip" {
  description = "Public IP of bastion/web instance for SSH access"
  value       = module.ec2.public_instance_ip
}

output "private_instance_ips" {
  description = "Private IPs of app/db instances (accessible via bastion)"
  value       = module.ec2.private_instance_ips
}

output "ssh_commands" {
  description = "Copy-paste SSH commands for connecting to instances"
  value = {
    bastion    = "ssh -i ~/.ssh/id_rsa_AWS ubuntu@${module.ec2.public_instance_ip}"
    app_server = "ssh -J ubuntu@${module.ec2.public_instance_ip} -i ~/.ssh/id_rsa_AWS ubuntu@${module.ec2.private_instance_ips["app"]}"
    db_server  = "ssh -J ubuntu@${module.ec2.public_instance_ip} -i ~/.ssh/id_rsa_AWS ubuntu@${module.ec2.private_instance_ips["db"]}"
  }
}

output "web_server_url" {
  description = "URL to access nginx web server on public instance"
  value       = "http://${module.ec2.public_instance_ip}"
}
