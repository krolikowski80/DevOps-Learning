resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = var.vpc_name
    description = "VPC for ${var.vpc_name}"
  }
}

resource "aws_subnet" "main" {
  for_each          = { for i, cidr in var.subnet_cidrs : i => cidr }
  cidr_block        = each.value
  vpc_id            = aws_vpc.main.id
  availability_zone = var.aws_availability_zones[each.key]
  tags = {
    Name = "${var.vpc_name}-${var.aws_availability_zones[each.key]}-subnet"
  }
}
