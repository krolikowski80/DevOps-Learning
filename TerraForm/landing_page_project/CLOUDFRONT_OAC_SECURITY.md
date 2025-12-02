# Zabezpieczanie S3 z CloudFront Origin Access Control (OAC)

Kompletny przewodnik dla juniorów: jak działa OAC, dlaczego go używać, i jak go wdrożyć krok po kroku.

## Spis treści

1. [Problem: Publiczny S3 Bucket](#problem-publiczny-s3-bucket)
2. [Rozwiązanie: Origin Access Control (OAC)](#rozwiązanie-origin-access-control-oac)
3. [Jak działa OAC - szczegóły techniczne](#jak-działa-oac-szczegóły-techniczne)
4. [Implementacja krok po kroku](#implementacja-krok-po-kroku)
5. [OAC vs OAI - różnice](#oac-vs-oai-różnice)
6. [Testowanie bezpieczeństwa](#testowanie-bezpieczeństwa)
7. [Troubleshooting](#troubleshooting)

---

## Problem: Publiczny S3 Bucket

### Scenariusz bez CloudFront (tylko S3)

```
                     ┌─────────────────┐
                     │                 │
User ──HTTP──────────▶  S3 Bucket      │
  (każdy)            │  (publiczny)    │
                     │                 │
                     └─────────────────┘
```

**Bucket Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",                    ← KAŻDY ma dostęp!
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::mybucket/*"
  }]
}
```

**Problemy:**

1. **Brak HTTPS** ❌
   - S3 website endpoint = tylko HTTP
   - Dane przesyłane niezaszyfrowane
   - Ryzyko Man-in-the-Middle attack

2. **Każdy może pobrać pliki bezpośrednio** ❌
   - Omijają CloudFront cache → wyższe koszty S3 transfer
   - Brak kontroli nad dostępem (geo-blocking, rate limiting)
   - Trudniejszy monitoring (rozproszone logi)

3. **Brak cache** ❌
   - Każdy request trafia do S3
   - Wolniejsze dla użytkowników globalnych
   - Wyższe koszty ($0.09/GB vs $0.085/GB z CloudFront)

4. **Ryzyko przypadkowego udostępnienia wrażliwych danych** ❌
   - Jeśli uploadujesz plik z hasłami/kluczami API
   - Jest natychmiast publiczny!

### Scenariusz z publicznym S3 + CloudFront (bez OAC)

```
                     ┌──────────────────┐
User ──HTTPS─────────▶  CloudFront      │
  (route 1)          │  (cache)         │
                     └────────┬─────────┘
                              │
                              ▼
                     ┌──────────────────┐
                     │  S3 Bucket       │
User ──HTTP──────────▶  (publiczny)     │
  (route 2)          │                  │
  OMIJA CLOUDFRONT!  └──────────────────┘
```

**Problem:** User może ominąć CloudFront i pobrać pliki bezpośrednio z S3!

**Przykład:**
```bash
# Przez CloudFront (cache) - chcemy tego
curl https://landing.zaproject.com/style.css

# Bezpośrednio z S3 (omija cache) - NIE CHCEMY tego!
curl http://landing.zaproject.com.s3-website-eu-west-1.amazonaws.com/style.css
```

---

## Rozwiązanie: Origin Access Control (OAC)

### Architektura z OAC

```
                     ┌──────────────────────┐
User ──HTTPS─────────▶  CloudFront          │
                     │  (cache + OAC token) │
                     └────────┬─────────────┘
                              │ Signed request
                              │ z ARN CloudFront
                              ▼
                     ┌──────────────────┐
                     │  S3 Bucket       │
User ──HTTP──────────▶  (PRYWATNY)      │
  ❌ 403 Forbidden    │  Sprawdza ARN   │
                     └──────────────────┘
```

**Bucket Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "cloudfront.amazonaws.com"     ← Tylko serwis CloudFront
    },
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::mybucket/*",
    "Condition": {
      "StringEquals": {
        "AWS:SourceArn": "arn:aws:cloudfront::123:distribution/E123"  ← Tylko TA dystrybucja
      }
    }
  }]
}
```

**Public Access Block (wszystkie na TRUE):**
```hcl
block_public_acls       = true   # Blokuje publiczne ACL
block_public_policy     = true   # Blokuje policy z Principal = "*"
ignore_public_acls      = true   # Ignoruje istniejące publiczne ACL
restrict_public_buckets = true   # Dodatkowa restrykcja
```

**Efekt:**
- ✅ Tylko CloudFront ma dostęp do S3
- ✅ Bezpośredni dostęp do S3 = 403 Forbidden
- ✅ Wymuszone HTTPS przez CloudFront
- ✅ Pełna kontrola nad traffic (WAF, geo-blocking, rate limiting)
- ✅ Niższe koszty (cache redukuje requesty do S3)

---

## Jak działa OAC - szczegóły techniczne

### Krok 1: CloudFront tworzy OAC token

Gdy tworzysz OAC resource w Terraform:

```hcl
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "OAC-landing.zaproject.com"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"      ← Zawsze podpisuj requesty
  signing_protocol                  = "sigv4"       ← AWS Signature Version 4
}
```

AWS tworzy "tożsamość" dla tej dystrybucji CloudFront.

### Krok 2: CloudFront podpisuje requesty do S3

Gdy user żąda pliku:

```
User Request: GET https://landing.zaproject.com/style.css
     ↓
CloudFront Cache Miss (plik nie w cache)
     ↓
CloudFront tworzy signed request do S3:

GET /style.css
Host: mybucket.s3.eu-west-1.amazonaws.com
Authorization: AWS4-HMAC-SHA256 Credential=...
X-Amz-Date: 20241023T120000Z
X-Amz-Content-Sha256: ...
X-Amz-Signature: ...                  ← Podpis zawierający ARN dystrybucji
```

**Kluczowe:** Request zawiera ARN dystrybucji CloudFront w podpisie!

### Krok 3: S3 weryfikuje podpis

S3 bucket policy sprawdza:

1. **Czy request pochodzi od CloudFront?**
   ```json
   "Principal": { "Service": "cloudfront.amazonaws.com" }
   ```

2. **Czy to właściwa dystrybucja CloudFront?**
   ```json
   "Condition": {
     "StringEquals": {
       "AWS:SourceArn": "arn:aws:cloudfront::123456789:distribution/E123ABC"
     }
   }
   ```

3. **Czy podpis jest poprawny?** (AWS SigV4)

**Jeśli wszystko OK:** S3 zwraca plik → CloudFront cache'uje → User otrzymuje

**Jeśli błąd:** S3 zwraca 403 Forbidden

### Krok 4: Bezpośredni request blokowany

Gdy user próbuje bezpośrednio:

```
User Request: GET http://mybucket.s3-website-eu-west-1.amazonaws.com/style.css
     ↓
S3 sprawdza bucket policy:
  - Principal = cloudfront.amazonaws.com? ❌ NIE (brak Principal)
  - AWS:SourceArn = ...? ❌ NIE (brak Condition)
     ↓
S3 zwraca: 403 Forbidden
```

---

## Implementacja krok po kroku

### Krok 1: Utwórz S3 bucket (publiczny na razie)

```hcl
module "s3" {
  source = "./modules/s3-static-website"

  domain_name         = "landing.zaproject.com"
  website_source_path = "./website-files"

  # NIE przekazuj cloudfront_distribution_arn jeszcze!
  # Bucket będzie publiczny na początek
}
```

```bash
terraform apply -target=module.s3
```

**Test:** Otwórz `http://landing.zaproject.com.s3-website-eu-west-1.amazonaws.com` → Powinieneś zobaczyć stronę ✅

### Krok 2: Utwórz OAC resource w CloudFront

```hcl
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "OAC-${var.domain_name}"
  description                       = "OAC for ${var.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
```

### Krok 3: Skonfiguruj CloudFront origin z OAC

```hcl
resource "aws_cloudfront_distribution" "website" {
  # ... inne ustawienia

  origin {
    domain_name              = var.s3_bucket_regional_domain  # WAŻNE: NIE website endpoint!
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id  # OAC token
  }

  # ... cache behavior, viewer certificate, etc.
}
```

**WAŻNE:** Użyj `bucket_regional_domain_name` (np. `bucket.s3.eu-west-1.amazonaws.com`), NIE `website_endpoint` (np. `bucket.s3-website-eu-west-1.amazonaws.com`).

**Dlaczego?**
- Website endpoint nie obsługuje OAC (legacy)
- Bucket regional domain = natywny dostęp przez AWS API

```bash
terraform apply -target=module.cloudfront
```

### Krok 4: Zaktualizuj S3 bucket policy (restrykcja dostępu)

```hcl
module "s3" {
  source = "./modules/s3-static-website"

  domain_name         = "landing.zaproject.com"
  website_source_path = "./website-files"

  # DODAJ ARN CloudFront
  cloudfront_distribution_arn = module.cloudfront.cloudfront_arn
}
```

To zmieni bucket policy z:
```json
"Principal": "*"
```

Na:
```json
"Principal": { "Service": "cloudfront.amazonaws.com" },
"Condition": {
  "StringEquals": {
    "AWS:SourceArn": "arn:aws:cloudfront::123:distribution/E123"
  }
}
```

I włączy Public Access Block (wszystkie na `true`).

```bash
terraform apply
```

### Krok 5: Test bezpieczeństwa

**Test 1: CloudFront działa ✅**
```bash
curl https://landing.zaproject.com
# Powinno zwrócić HTML strony
```

**Test 2: Bezpośredni dostęp do S3 zablokowany ❌**
```bash
curl http://landing.zaproject.com.s3-website-eu-west-1.amazonaws.com
# Powinno zwrócić: 403 Forbidden
```

**Test 3: Bucket regional domain też zablokowany ❌**
```bash
curl https://landing.zaproject.com.s3.eu-west-1.amazonaws.com/index.html
# Powinno zwrócić: 403 Forbidden (AccessDenied)
```

✅ **SUKCES!** Tylko CloudFront ma dostęp do S3.

---

## OAC vs OAI - różnice

| Feature | OAI (Origin Access Identity) | OAC (Origin Access Control) |
|---------|------------------------------|------------------------------|
| **Rok wprowadzenia** | 2009 | 2022 |
| **Status** | Legacy (deprecated) | Zalecane (current) |
| **Signing** | AWS Signature V2 | AWS Signature V4 (bezpieczniejsze) |
| **Wszystkie regiony S3** | ❌ Nie | ✅ Tak |
| **S3 Server-Side Encryption (SSE-KMS)** | ❌ Nie | ✅ Tak |
| **Dynamic requests (POST, PUT)** | ❌ Nie | ✅ Tak |
| **Terraform resource** | `aws_cloudfront_origin_access_identity` | `aws_cloudfront_origin_access_control` |

**Wniosek:** Zawsze używaj **OAC** dla nowych projektów!

### Migracja z OAI do OAC

Jeśli masz stary kod z OAI:

**STARE (OAI):**
```hcl
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.domain_name}"
}

origin {
  domain_name = aws_s3_bucket.website.bucket_regional_domain_name
  origin_id   = local.s3_origin_id

  s3_origin_config {
    origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
  }
}
```

**NOWE (OAC):**
```hcl
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "OAC-${var.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

origin {
  domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
  origin_id                = local.s3_origin_id
  origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
}
```

I zmień bucket policy na nowy format (patrz wyżej).

---

## Testowanie bezpieczeństwa

### Test 1: Sprawdź bucket policy

```bash
aws s3api get-bucket-policy --bucket landing.zaproject.com | jq -r '.Policy' | jq .
```

Powinno zwrócić:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "CloudFrontAccess",
    "Effect": "Allow",
    "Principal": {
      "Service": "cloudfront.amazonaws.com"
    },
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::landing.zaproject.com/*",
    "Condition": {
      "StringEquals": {
        "AWS:SourceArn": "arn:aws:cloudfront::123456789:distribution/E123ABC"
      }
    }
  }]
}
```

### Test 2: Sprawdź Public Access Block

```bash
aws s3api get-public-access-block --bucket landing.zaproject.com
```

Powinno zwrócić:
```json
{
  "PublicAccessBlockConfiguration": {
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }
}
```

### Test 3: Sprawdź CloudFront OAC

```bash
aws cloudfront list-distributions | jq '.DistributionList.Items[] | select(.Aliases.Items[] | contains("landing.zaproject.com")) | .Origins.Items[0]'
```

Powinno zawierać:
```json
{
  "DomainName": "landing.zaproject.com.s3.eu-west-1.amazonaws.com",
  "OriginAccessControlId": "E123ABC...",
  "S3OriginConfig": {
    "OriginAccessIdentity": ""  ← Puste (używamy OAC, nie OAI)
  }
}
```

### Test 4: Penetration test (bezpośredni dostęp)

```bash
# Test 1: Website endpoint
curl -I http://landing.zaproject.com.s3-website-eu-west-1.amazonaws.com
# Oczekiwany: HTTP 403 Forbidden

# Test 2: Bucket regional domain
curl -I https://landing.zaproject.com.s3.eu-west-1.amazonaws.com/index.html
# Oczekiwany: HTTP 403 AccessDenied

# Test 3: CloudFront (powinno działać)
curl -I https://landing.zaproject.com
# Oczekiwany: HTTP 200 OK
```

### Test 5: Sprawdź nagłówki odpowiedzi CloudFront

```bash
curl -I https://landing.zaproject.com
```

Szukaj:
```
X-Cache: Hit from cloudfront           ← Plik serwowany z cache
X-Amz-Cf-Pop: WAW50-C1                 ← Edge location (Warszawa)
X-Amz-Cf-Id: ...                       ← CloudFront request ID
```

---

## Troubleshooting

### Problem: CloudFront zwraca 403 Forbidden (po włączeniu OAC)

**Możliwe przyczyny:**

1. **S3 bucket policy nie zezwala CloudFront na dostęp**

```bash
# Sprawdź policy
aws s3api get-bucket-policy --bucket mybucket | jq -r '.Policy' | jq .

# Principal powinno być:
"Principal": { "Service": "cloudfront.amazonaws.com" }

# Condition powinno sprawdzać ARN
"Condition": {
  "StringEquals": {
    "AWS:SourceArn": "arn:aws:cloudfront::123:distribution/E123"
  }
}
```

**Fix:** Zaktualizuj bucket policy w S3 module (przekaż `cloudfront_distribution_arn`).

2. **Błędny ARN w bucket policy**

```bash
# Pobierz ARN dystrybucji CloudFront
aws cloudfront list-distributions | jq '.DistributionList.Items[] | select(.Aliases.Items[] | contains("landing.zaproject.com")) | .ARN'

# Porównaj z ARN w bucket policy
aws s3api get-bucket-policy --bucket mybucket | jq -r '.Policy' | jq '.Statement[0].Condition.StringEquals."AWS:SourceArn"'

# Muszą być identyczne!
```

**Fix:** Użyj `module.cloudfront.cloudfront_arn` w Terraform (nie hardcode ARN).

3. **Używasz website endpoint zamiast bucket regional domain**

```bash
# Sprawdź origin domain w CloudFront
aws cloudfront get-distribution --id E123 | jq '.Distribution.DistributionConfig.Origins.Items[0].DomainName'

# Powinno być (bucket regional domain):
"mybucket.s3.eu-west-1.amazonaws.com"

# NIE powinno być (website endpoint):
"mybucket.s3-website-eu-west-1.amazonaws.com"  ← TO NIE DZIAŁA Z OAC!
```

**Fix:** Zmień `domain_name` w origin na `bucket_regional_domain_name`.

### Problem: Bezpośredni dostęp do S3 nadal działa (nie zablokowany)

**Możliwe przyczyny:**

1. **Public Access Block nie jest włączony**

```bash
aws s3api get-public-access-block --bucket mybucket
# Wszystkie powinny być true
```

**Fix:**
```hcl
resource "aws_s3_bucket_public_access_block" "website" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

2. **Bucket policy nadal ma Principal = "*"**

```bash
aws s3api get-bucket-policy --bucket mybucket | jq -r '.Policy' | jq '.Statement[0].Principal'

# Jeśli zwraca:
"*"  ← BŁĄD! To publiczna policy

# Powinno być:
{"Service": "cloudfront.amazonaws.com"}
```

**Fix:** Przekaż `cloudfront_distribution_arn` do S3 module i uruchom `terraform apply`.

### Problem: Terraform pokazuje Cycle (circular dependency)

**Przyczyna:** CloudFront potrzebuje S3 bucket domain, S3 policy potrzebuje CloudFront ARN.

**Rozwiązanie:**

**Opcja 1: Dwuetapowy deployment**
```bash
terraform apply -target=module.s3          # Bez CloudFront ARN
terraform apply -target=module.cloudfront
terraform apply                             # Zaktualizuj S3 policy z ARN
```

**Opcja 2: Conditional policy w S3 module**

W `modules/s3-static-website/main.tf`:
```hcl
resource "aws_s3_bucket_policy" "website" {
  count = var.cloudfront_distribution_arn != null ? 1 : 0
  # ... policy z Condition
}

resource "aws_s3_bucket_policy" "website_public" {
  count = var.cloudfront_distribution_arn == null ? 1 : 0
  # ... publiczna policy
}
```

**Opcja 3: Użyj `depends_on`**
```hcl
module "s3" {
  # ...
  depends_on = [module.cloudfront]
}
```

---

## Checklist bezpieczeństwa

Przed wdrożeniem na produkcję:

- [ ] S3 bucket policy sprawdza CloudFront ARN w Condition
- [ ] Public Access Block włączony (wszystkie 4 flagi = true)
- [ ] CloudFront używa bucket regional domain (NIE website endpoint)
- [ ] CloudFront origin ma `origin_access_control_id` ustawione
- [ ] OAC resource ma `signing_behavior = "always"` i `signing_protocol = "sigv4"`
- [ ] Bezpośredni dostęp do S3 zwraca 403 Forbidden (test!)
- [ ] CloudFront wymusza HTTPS (`viewer_protocol_policy = "redirect-to-https"`)
- [ ] ACM certyfikat jest zweryfikowany i w regionie us-east-1
- [ ] Route53 rekord wskazuje na CloudFront (NIE na S3)

---

## Dodatkowe zabezpieczenia (opcjonalne)

### 1. AWS WAF (Web Application Firewall)

```hcl
resource "aws_wafv2_web_acl" "cloudfront" {
  name  = "cloudfront-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitRule"
    priority = 1

    statement {
      rate_based_statement {
        limit              = 2000  # Max 2000 requestów / 5 minut / IP
        aggregate_key_type = "IP"
      }
    }

    action {
      block {}
    }
  }
}

# Przypisz do CloudFront
resource "aws_cloudfront_distribution" "website" {
  web_acl_id = aws_wafv2_web_acl.cloudfront.arn
  # ...
}
```

### 2. CloudFront Functions (Security Headers)

```javascript
function handler(event) {
  var response = event.response;
  var headers = response.headers;

  headers['strict-transport-security'] = { value: 'max-age=63072000' };
  headers['x-content-type-options'] = { value: 'nosniff' };
  headers['x-frame-options'] = { value: 'DENY' };
  headers['x-xss-protection'] = { value: '1; mode=block' };

  return response;
}
```

### 3. Geo Restriction

```hcl
resource "aws_cloudfront_distribution" "website" {
  # ...
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["PL", "DE", "FR"]  # Tylko te kraje
    }
  }
}
```

---

## Zasoby

- [AWS Docs: Restricting access to S3 with OAC](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [AWS Blog: Introducing Origin Access Control](https://aws.amazon.com/blogs/networking-and-content-delivery/amazon-cloudfront-introduces-origin-access-control-oac/)
- [Terraform: aws_cloudfront_origin_access_control](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control)

---

**Autor:** Junior security guide
**Ostatnia aktualizacja:** 2024-10-23
