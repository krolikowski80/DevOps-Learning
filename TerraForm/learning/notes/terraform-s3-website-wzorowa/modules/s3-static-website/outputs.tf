# =============================================================================
# Module Outputs - Wartości zwracane przez moduł
# =============================================================================
#
# Outputs (wyjścia) to wartości, które moduł zwraca po wykonaniu.
# Możesz ich użyć w innych częściach kodu lub wyświetlić użytkownikowi.
#
# Dlaczego outputs są ważne:
# - Pokazują ważne informacje (np. URL strony)
# - Pozwalają przekazać dane do innych modułów
# - Dokumentują co moduł utworzył
#
# Każdy output ma:
# - description: Opis co to jest
# - value: Wartość do zwrócenia (odwołanie do zasobu)
# - sensitive: (opcjonalne) Czy ukryć wartość w logach (dla danych wrażliwych)
# =============================================================================

# -----------------------------------------------------------------------------
# website_url - URL do strony WWW
# -----------------------------------------------------------------------------
#
# To najważniejszy output - adres URL gdzie można zobaczyć stronę.
#
# aws_s3_bucket_website_configuration.website.website_endpoint zwraca:
# - Format: bucket-name.s3-website-region.amazonaws.com
# - Przykład: my-site.s3-website-eu-west-1.amazonaws.com
#
# UWAGA: To jest URL HTTP (nie HTTPS). Dla HTTPS trzeba użyć CloudFront.
#
output "website_url" {
  description = "URL strony WWW hostowanej na S3. Użyj tego adresu aby otworzyć stronę w przeglądarce."
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"

  # Dodajemy "http://" żeby było od razu gotowe do kliknięcia
}

# -----------------------------------------------------------------------------
# bucket_name - Nazwa utworzonego bucketa
# -----------------------------------------------------------------------------
#
# Zwraca nazwę bucketa który został utworzony.
# Przydatne gdy:
# - Chcesz zobaczyć jaki bucket został utworzony
# - Potrzebujesz przekazać nazwę do innych narzędzi (np. CI/CD)
# - Chcesz używać bucketa w innych modułach
#
output "bucket_name" {
  description = "Nazwa bucketa S3 który został utworzony. Użyj tego do zarządzania bucketem przez AWS CLI."
  value       = aws_s3_bucket.website.id

  # aws_s3_bucket.website.id zwraca nazwę bucketa
  # (dla S3, "id" i "bucket" to to samo)
}

# -----------------------------------------------------------------------------
# bucket_arn - ARN bucketa (unikalny identyfikator w AWS)
# -----------------------------------------------------------------------------
#
# ARN (Amazon Resource Name) to unikalny identyfikator zasobu w AWS.
# Format: arn:aws:s3:::bucket-name
#
# Używany do:
# - Konfiguracji uprawnień IAM
# - Łączenia zasobów (np. CloudFront + S3)
# - Automatyzacji i skryptów
#
# ARN jednoznacznie identyfikuje zasób w całym AWS (jak PESEL dla zasobów).
#
output "bucket_arn" {
  description = "ARN (Amazon Resource Name) bucketa. Unikalny identyfikator używany w policy i IAM."
  value       = aws_s3_bucket.website.arn

  # Przykładowa wartość: arn:aws:s3:::my-bucket-name
}

# -----------------------------------------------------------------------------
# website_endpoint - Endpoint S3 website (bez HTTP)
# -----------------------------------------------------------------------------
#
# Zwraca sam endpoint bez protokołu HTTP.
# Przydatne gdy potrzebujesz samej domeny (np. dla CNAME w DNS).
#
output "website_endpoint" {
  description = "Endpoint S3 website bez protokołu (sam hostname). Użyj do konfiguracji DNS CNAME."
  value       = aws_s3_bucket_website_configuration.website.website_endpoint

  # Przykładowa wartość: my-bucket.s3-website-eu-west-1.amazonaws.com
}

# =============================================================================
# Jak używać outputs:
# =============================================================================
#
# 1. Po "terraform apply" outputs są automatycznie wyświetlane:
#    Outputs:
#    website_url = "http://my-bucket.s3-website-eu-west-1.amazonaws.com"
#    bucket_name = "my-bucket"
#
# 2. Możesz je wyświetlić komendą:
#    terraform output
#    terraform output website_url  # konkretny output
#
# 3. Użycie w innym module/zasobie:
#    module "website" {
#      source = "..."
#    }
#
#    resource "aws_cloudfront_distribution" "cdn" {
#      origin {
#        domain_name = module.website.website_endpoint  # <-- używamy output
#      }
#    }
#
# 4. W skryptach (JSON format):
#    terraform output -json
#
# =============================================================================