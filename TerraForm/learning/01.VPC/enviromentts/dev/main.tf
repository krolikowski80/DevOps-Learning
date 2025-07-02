resource "aws_vpc" "dev_vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = var.vpc_name
  }
}

