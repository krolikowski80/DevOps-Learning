provider "aws" {
  region = var.region
}

module "terraform_state_bucket" {
  source             = "../../../modules/terraform-state-bucket"
  environment        = var.environment
  region             = var.region
  bucket_name_suffix = var.bucket_name_suffix
}
