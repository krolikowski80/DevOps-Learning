module "ec2_firewall" {
  source = "../../../modules/ec2_firewall"
  
  environment          = var.environment
  ec2_instances        = var.ec2_instances
  ami_id              = var.ami_id
  subnet_cidr         = var.subnet_cidr
  network_name        = var.network_name
  allow_firewall_rules = var.allow_firewall_rules
}
