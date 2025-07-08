module "vpc" {
  source = "../../modules/vpc"

  name            = var.name
  description     = var.description
  cidr_block      = var.cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}
