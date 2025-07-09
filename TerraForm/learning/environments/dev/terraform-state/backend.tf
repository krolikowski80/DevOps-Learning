terraform {
  backend "s3" {
    bucket         = "terraform-state-tk-dev-20250709222448939700000001"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock-dev"
  }
}