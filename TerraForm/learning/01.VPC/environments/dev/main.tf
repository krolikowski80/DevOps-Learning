module "vpc" {
  source                 = "../../modules/vpc"
  vpc_cidr               = var.vpc_cidr
  subnet_cidrs           = var.subnet_cidrs
  vpc_name               = var.vpc_name
  aws_availability_zones = var.aws_availability_zones
  aws_region             = var.aws_region
}
