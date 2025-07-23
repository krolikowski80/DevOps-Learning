# ==============================================================================
# ZMIENNE - ŚRODOWISKO DEV
# ==============================================================================
# Multi-AZ VPC z architekturą public/private subnet
# Dokumentacja: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenarios.html

## Określam środowisko w jakim to się znajduje. Separuję środowiska bo różne env mają różne wymagania
## bezpieczeństwa, kosztów i dostępności. Ta zmienna będzie potrzebna dla tagowania zasobów, 
## naming convention i conditional logic w module'ach.
variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment musi być dev, staging lub prod."
  }
}

## Definiuję region AWS bo chcę mieć kontrolę nad lokalizacją zasobów. Różne regiony mają różne
## koszty, compliance requirements i dostępność usług. Ta zmienna będzie używana przez provider
## i wszystkie zasoby muszą być w tym samym regionie dla prawidłowej komunikacji.
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"

  # Dokumentacja: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html
}

## Ustawiam CIDR dla VPC bo muszę zaplanować przestrzeń IP. /16 daje ~65k adresów co wystarcza
## na development. Ta zmienna będzie używana do tworzenia VPC i podziału na subnet'y.
variable "vpc_cidr" {
  description = "VPC CIDR block - RFC 1918 private range"
  type        = string
  default     = "10.0.0.0/16"

  # Dokumentacja: https://tools.ietf.org/html/rfc1918
}

## Map public subnet'ów z explicit AZ assignment - lepsze niż list approach
## bo eliminuje out-of-bounds errors i daje full control nad placement
variable "public_subnets" {
  description = "Map of public subnets with AZ mapping"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

## Map private subnet'ów dla aplikacji i baz danych - izolowane od internetu
variable "private_subnets" {
  description = "Map of private subnets with AZ mapping"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

## Kontroluję czy tworzyć NAT Gateway bo kosztuje ~$45/miesiąc per Gateway
## W dev mogę wyłączyć dla oszczędności, w prod muszę mieć dla HA
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = false
}

## Decyduję czy NAT Gateway w każdej AZ (HA + drożej) czy jeden wspólny (tańsza + SPOF)
## Multi-AZ = wysoka dostępność ale wyższe koszty (~$45 * liczba_AZ)
variable "single_nat_gateway" {
  description = "Use single NAT Gateway instead of one per AZ"
  type        = bool
  default     = true
}

## SSH Key configuration - path do public key dla EC2 access
variable "public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa_AWS.pub"
}
