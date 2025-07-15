module "vpc" {
  source = "../../modules/vpc"

  name            = var.name
  description     = var.description
  cidr_block      = var.cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

# module "s3" {
#   source           = "../../modules/S3"
#   bucket_name      = var.bucket_name
#   environment      = var.environment
#   main_page_suffix = var.main_page_suffix
#   not_found_page   = var.not_found_page
# }
