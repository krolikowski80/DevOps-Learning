# ==============================================================================
# VPC MODULE - MAIN RESOURCES
# ==============================================================================
# Tworzy VPC z public/private subnet architecture + routing

## VPC - Virtual Private Cloud, podstawa całej infrastruktury sieciowej
## To jest nasz izolowany network segment w AWS cloud
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Potrzebne żeby EC2 miały DNS names
  enable_dns_support   = true # Potrzebne do DNS resolution

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

## Internet Gateway - bramka do internetu dla public subnet'ów
## Bez tego public subnet nie będzie miał dostępu do internetu
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

## Public Subnets - for_each approach dla explicit control
## Tutaj będą zasoby z dostępem do internetu: NAT Gateway, Load Balancers, Bastion hosts
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true # Auto-assign public IP dla EC2

  tags = {
    Name = "${var.project_name}-${var.environment}-${each.key}"
    Type = "Public"
    AZ   = each.value.availability_zone
  }
}

## Private Subnets - izolowane od internetu, dostęp tylko przez NAT Gateway
## Tutaj będą aplikacje i bazy danych dla zwiększonego bezpieczeństwa
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  # map_public_ip_on_launch = false  # default dla private - no public IPs

  tags = {
    Name = "${var.project_name}-${var.environment}-${each.key}"
    Type = "Private"
    AZ   = each.value.availability_zone
  }
}

# Dokumentacja VPC: https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
# Dokumentacja Subnets: https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html

## Public Route Table - kieruje ruch z public subnet'ów do internetu
## Każdy public subnet potrzebuje route 0.0.0.0/0 → Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
    Type = "Public"
  }
}

## Associate public subnets z public route table
## Bez tego association subnet nie wie jak routować traffic
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

## Private Route Tables - per AZ dla flexibility (jeśli multi-NAT w przyszłości)
## Na razie bez routes - dodamy NAT Gateway routes później
resource "aws_route_table" "private" {
  for_each = var.private_subnets

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt-${each.key}"
    Type = "Private"
    AZ   = each.value.availability_zone
  }
}

## Associate private subnets z odpowiednimi route tables
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Dokumentacja Route Tables: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html

## Elastic IP dla NAT Gateway - potrzebne bo NAT musi mieć static public IP
## Tworzymy tylko jeśli NAT Gateway jest enabled
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0

  domain = "vpc" # Associate z VPC, nie EC2-Classic

  tags = {
    Name = "${var.project_name}-${var.environment}-eip-nat-${count.index + 1}"
  }

  # EIP musi poczekać aż IGW będzie attached do VPC
  depends_on = [aws_internet_gateway.main]
}

## NAT Gateway - umożliwia private subnet'om wychodzenie do internetu
## Musi być w public subnet bo potrzebuje dostępu do Internet Gateway
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = values(aws_subnet.public)[0].id # Pierwszy public subnet

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-gw-${count.index + 1}"
  }

  # NAT Gateway musi czekać na Internet Gateway
  depends_on = [aws_internet_gateway.main]
}

## Routes dla private subnet'ów do NAT Gateway
## Dodaje route 0.0.0.0/0 → NAT Gateway do każdej private route table
resource "aws_route" "private_nat_gateway" {
  for_each = var.enable_nat_gateway ? var.private_subnets : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[0].id
}

# Dokumentacja NAT Gateway: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html
