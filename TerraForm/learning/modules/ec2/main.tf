# ==============================================================================
# EC2 MODULE - MAIN RESOURCES
# ==============================================================================
# Tworzy 3 EC2 instances: 1 public (bastion/web) + 2 private (app/db)
# Plus security groups dla proper network isolation

## Data source - najnowsze Ubuntu 22.04 LTS AMI
## Używam data source zamiast hardcoded AMI ID bo AMI się zmieniają
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

## Public EC2 Instance - Web/Bastion server w public subnet
## Ma public IP i może być accessed z internetu przez SSH/HTTP
resource "aws_instance" "public" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = values(var.public_subnet_ids)[0] # First public subnet
  vpc_security_group_ids = [aws_security_group.public.id]

  # Enable public IP assignment
  associate_public_ip_address = true

  # User data script - basic setup
  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Public Instance - ${var.environment}</h1>" > /var/www/html/index.html
              EOF
  )

  tags = {
    Name = "${var.project_name}-${var.environment}-public"
    Type = "Public"
    Role = "Web/Bastion"
  }
}

## Private EC2 Instances - App servers w private subnets
## Accessible tylko przez bastion host, internet przez NAT Gateway
resource "aws_instance" "private" {
  for_each = var.private_subnet_ids

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.private.id]

  # No public IP for private instances
  associate_public_ip_address = false

  # User data script - basic setup
  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y htop curl
              echo "Private Instance - ${each.key} - ${var.environment}" > /etc/hostname
              hostname -F /etc/hostname
              EOF
  )

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${each.key}"
    Type = "Private"
    Role = each.key # "app" or "db"
  }
}
## Security Group - Public Instance (Web/Bastion)
## Pozwala SSH z internetu + HTTP traffic, outbound wszystko
resource "aws_security_group" "public" {
  name_prefix = "${var.project_name}-${var.environment}-public-"
  vpc_id      = var.vpc_id

  # SSH access from internet - needed for bastion functionality
  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from internet - for web server testing
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic allowed - needed for updates, NAT communication
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-sg"
    Type = "Public"
  }
}

## Security Group - Private Instances (App/DB)
## Pozwala SSH tylko z public subnet + internal communication
resource "aws_security_group" "private" {
  name_prefix = "${var.project_name}-${var.environment}-private-"
  vpc_id      = var.vpc_id

  # SSH access only from public subnet - bastion host pattern
  ingress {
    description     = "SSH from public subnet"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  # Internal communication between private instances
  ingress {
    description = "Internal communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # All outbound traffic - needed for NAT Gateway internet access
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-sg"
    Type = "Private"
  }
}

# Dokumentacja Security Groups: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html

## SSH Key Pair - używa istniejący AWS key
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = file(var.public_key_path)

  tags = {
    Name = "${var.project_name}-${var.environment}-key"
  }
}
