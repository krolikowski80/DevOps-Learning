resource "aws_vpc" "prod_vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = var.vpc_name
  }
}

