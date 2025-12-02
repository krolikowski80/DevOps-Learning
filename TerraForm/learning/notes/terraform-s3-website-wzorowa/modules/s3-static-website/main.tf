# =============================================================================
# S3 Static Website Module - Main Configuration
# =============================================================================
#
# Ten moduł tworzy i konfiguruje bucket S3 do hostowania statycznej strony WWW.
# Strona będzie dostępna publicznie przez Internet.
#
# Czego się nauczysz z tego pliku:
# - Jak stworzyć bucket S3 z unikalną nazwą
# - Jak włączyć hosting statycznej strony na S3
# - Jak skonfigurować publiczny dostęp do strony
# - Jak wgrać pliki HTML na S3
# - Jak ustawić odpowiednie uprawnienia (policy)
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Bucket - główny zasób do przechowywania plików strony
# -----------------------------------------------------------------------------
#
# Bucket S3 to kontener na pliki w AWS (podobny do folderu).
# Tutaj będą przechowywane pliki HTML, CSS, JS naszej strony.
#
# Ważne opcje:
# - bucket: Nazwa bucketa (musi być globalnie unikalna w całym AWS!)
# - force_destroy: Pozwala usunąć bucket nawet jeśli zawiera pliki
#
resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  force_destroy = true # Uwaga: W produkcji ustaw na false, żeby przypadkiem nie usunąć danych!

  tags = merge(
    var.tags,
    {
      Name        = var.bucket_name
      Environment = var.environment
      Purpose     = "Static Website Hosting"
    }
  )
}

# -----------------------------------------------------------------------------
# Website Configuration - włącza funkcję hostingu stron WWW
# -----------------------------------------------------------------------------
#
# Ta konfiguracja mówi AWS, że bucket ma działać jak serwer WWW.
# Określa które pliki pokazać jako stronę główną i stronę błędu.
#
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  # index_document: Plik wyświetlany gdy ktoś wejdzie na stronę (np. example.com/)
  index_document {
    suffix = "index.html"
  }

  # error_document: Plik wyświetlany gdy strona nie zostanie znaleziona (błąd 404)
  error_document {
    key = "error.html"
  }
}

# -----------------------------------------------------------------------------
# Public Access Block Settings - kontrola publicznego dostępu
# -----------------------------------------------------------------------------
#
# Domyślnie AWS blokuje publiczny dostęp do S3 ze względów bezpieczeństwa.
# Tutaj wyłączamy te blokady, bo chcemy aby nasza strona była publiczna.
#
# UWAGA: Rób to tylko dla stron WWW! Nigdy dla danych wrażliwych!
#
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false # Pozwalamy na publiczne ACL
  block_public_policy     = false # Pozwalamy na publiczne policy
  ignore_public_acls      = false # Nie ignorujemy publicznych ACL
  restrict_public_buckets = false # Nie ograniczamy publicznych bucketów
}

# -----------------------------------------------------------------------------
# Bucket Policy - dokument określający kto ma dostęp do bucketa
# -----------------------------------------------------------------------------
#
# Policy to dokument JSON który definiuje uprawnienia.
# Ta policy mówi: "Każdy (Principal: *) może odczytać (GetObject) wszystkie pliki"
#
# Struktura policy:
# - Version: Wersja języka policy (zawsze użyj "2012-10-17")
# - Statement: Lista reguł uprawnień
#   - Effect: "Allow" = pozwól, "Deny" = zabroń
#   - Principal: Kto może (tutaj "*" = wszyscy)
#   - Action: Co może robić (tutaj "s3:GetObject" = czytać pliki)
#   - Resource: Których zasobów dotyczy (tutaj wszystkie pliki w bucket)
#
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  # depends_on zapewnia, że najpierw wyłączymy blokady publicznego dostępu
  # przed ustawieniem publicznej policy (ważna kolejność!)
  depends_on = [aws_s3_bucket_public_access_block.website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject" # ID tego statement (dla czytelności)
        Effect    = "Allow"
        Principal = "*" # Gwiazdka = każdy użytkownik Internetu
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*" # ARN to unikalny identyfikator zasobu w AWS
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# S3 Objects - wgrywanie plików na bucket
# -----------------------------------------------------------------------------
#
# Każdy plik na S3 to "object". Tutaj wgrywamy pliki HTML naszej strony.
#
# Ważne parametry:
# - bucket: Do którego bucketa wgrać
# - key: Nazwa pliku na S3 (ścieżka)
# - source: Skąd wziąć plik lokalnie
# - content_type: Typ MIME (mówi przeglądarce jak interpretować plik)
# - etag: Hash pliku - Terraform dzięki temu wie kiedy plik się zmienił
#

# Główna strona (index.html)
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.module}/website/index.html" # path.module = ścieżka do tego modułu
  content_type = "text/html"
  etag         = filemd5("${path.module}/website/index.html") # MD5 hash do wykrywania zmian
}

# Strona błędu (error.html)
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  source       = "${path.module}/website/error.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/website/error.html")
}

# =============================================================================
# Podsumowanie - Co robi ten moduł krok po kroku:
# =============================================================================
#
# 1. Tworzy bucket S3 z unikalną nazwą
# 2. Włącza konfigurację website (index.html, error.html)
# 3. Wyłącza blokady publicznego dostępu
# 4. Ustawia policy pozwalającą każdemu czytać pliki
# 5. Wgrywa pliki HTML na bucket
#
# Rezultat: Działająca statyczna strona WWW dostępna przez URL S3
# =============================================================================