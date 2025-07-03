# Terraform VPC - Wskazówki

## Struktura reusable module:
- `modules/vpc/` - komponenty wielokrotnego użytku
- `environments/dev/` - konkretne środowiska
- Każdy environment: main.tf + variables.tf + terraform.tfvars + provider.tf

## Kluczowe patterns:
- `for_each = { for i, cidr in var.subnet_cidrs : i => cidr }` - iteracja przez listę
- `var.aws_availability_zones[each.key]` - mapowanie AZ do subnetów
- Nazwy: `${var.vpc_name}-${var.aws_availability_zones[each.key]}-subnet`

## Błędy których unikać:
- Duplikacja regionu w nazwach (region już jest w AZ)
- Hardcoded wartości w module
- Kopiowanie kodu zamiast parametryzacji

## Następne kroki:
- Prod environment (copy pattern, zmień wartości)
- Route tables dla kompletnych prywatnych subnetów