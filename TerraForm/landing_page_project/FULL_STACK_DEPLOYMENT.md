# Full-Stack Deployment: S3 + CloudFront + HTTPS + API Gateway

Kompletny przewodnik od zera do działającej strony z formularzem - dla juniorów.

## Co będziemy budować?

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  Landing Page (HTML + CSS + JS)                     │
│  Domena: https://landing.zaproject.com             │
│                                                     │
│  Features:                                          │
│  ✅ Statyczna strona hostowana na S3                │
│  ✅ HTTPS z certyfikatem SSL (ACM)                  │
│  ✅ Globalny cache (CloudFront)                    │
│  ✅ Formularz kontaktowy wysyłający do API Gateway │
│  ✅ S3 prywatny (tylko CloudFront ma dostęp - OAC) │
│  ✅ Custom domena z Route53                         │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Architektura:**
```
User Browser
    ↓ HTTPS
CloudFront (landing.zaproject.com) + OAC
    ↓
S3 Bucket (PRIVATE) ──[Form Submit]──▶ API Gateway
                                            ↓
                                        Lambda Function
                                            ↓
                                        S3 Bucket (form data)
```

## Wymagania wstępne

### 1. AWS Account
- Utworz konto na [aws.amazon.com](https://aws.amazon.com)
- Zweryfikuj email i kartę kredytową

### 2. AWS CLI
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Konfiguracja
aws configure
# AWS Access Key ID: [Twoje ID]
# AWS Secret Access Key: [Twój klucz]
# Default region name: eu-west-1
# Default output format: json
```

### 3. Terraform
```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Test
terraform -version
```

### 4. Domena i Route53 Hosted Zone

**Opcja A: Kupno domeny w Route53**
```
AWS Console → Route53 → Register Domain → zaproject.com ($12/rok)
```

**Opcja B: Transfer domeny z innego rejestratora**
```
1. AWS Console → Route53 → Transfer Domain
2. Zmień DNS servery u obecnego rejestratora na AWS nameservers
```

Po utworzeniu hosted zone, zapisz **Hosted Zone ID** (np. `Z1234567890ABC`).

### 5. Certyfikat ACM (WAŻNE: region us-east-1!)

```bash
# KROK 1: Przełącz się na region us-east-1
aws configure set region us-east-1

# KROK 2: Requestuj certyfikat
aws acm request-certificate \
  --domain-name "*.zaproject.com" \
  --validation-method DNS \
  --subject-alternative-names "zaproject.com"

# Output: Zapisz CertificateArn

# KROK 3: Pobierz CNAME rekord do walidacji
aws acm describe-certificate \
  --certificate-arn "arn:aws:acm:us-east-1:123:certificate/xxx" \
  | jq '.Certificate.DomainValidationOptions[0].ResourceRecord'

# KROK 4: Dodaj CNAME rekord do Route53
# AWS Console → Route53 → Hosted zones → zaproject.com → Create record
# Record name: _xxx.zaproject.com
# Record type: CNAME
# Value: _yyy.acm-validations.aws

# KROK 5: Poczekaj na status "Issued" (5-30 minut)
aws acm describe-certificate \
  --certificate-arn "arn:aws:acm:us-east-1:123:certificate/xxx" \
  | jq '.Certificate.Status'

# Powinno zwrócić: "ISSUED"

# KROK 6: Przywróć domyślny region
aws configure set region eu-west-1
```

---

## Krok 1: Przygotuj strukturę projektu

```bash
mkdir landing-page-project
cd landing-page-project

# Struktura:
# landing-page-project/
# ├── environments/
# │   └── prod/
# │       ├── main.tf
# │       ├── variables.tf
# │       ├── providers.tf
# │       ├── terraform.tfvars
# │       └── outputs.tf
# ├── lambda/
# │   ├── lambda_function.py
# │   └── lambda_function.zip
# ├── website-files/
# │   ├── index.html
# │   ├── style.css
# │   ├── script.js
# │   └── error.html
# └── modules/
#     ├── s3-static-website/
#     ├── cloudfront-https/
#     └── form-api/
```

### Pobierz moduły

```bash
# Opcja 1: Klonuj repozytorium
git clone https://github.com/your-org/terraform-modules.git
cd terraform-modules

# Opcja 2: Kopiuj moduły ręcznie
mkdir -p modules
# ... skopiuj s3-static-website, cloudfront-https, form-api
```

---

## Krok 2: Przygotuj pliki strony

### `website-files/index.html`

```html
<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Landing Page - Contact Us</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <div class="container">
    <h1>Contact Us</h1>
    <p>Fill out the form below and we'll get back to you!</p>

    <form id="contactForm">
      <input type="text" name="name" placeholder="Your Name" required>
      <input type="email" name="email" placeholder="Your Email" required>
      <input type="tel" name="phone" placeholder="Your Phone">
      <textarea name="message" placeholder="Your Message" rows="5"></textarea>
      <button type="submit">Send Message</button>
    </form>

    <div id="status"></div>
  </div>

  <script src="script.js"></script>
</body>
</html>
```

### `website-files/style.css`

```css
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.container {
  background: white;
  border-radius: 20px;
  padding: 40px;
  max-width: 500px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0,0,0,0.3);
}

h1 {
  color: #667eea;
  margin-bottom: 10px;
  font-size: 32px;
}

p {
  color: #666;
  margin-bottom: 30px;
}

form {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

input, textarea {
  padding: 15px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  font-size: 16px;
  transition: border-color 0.3s;
}

input:focus, textarea:focus {
  outline: none;
  border-color: #667eea;
}

button {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 15px;
  border: none;
  border-radius: 10px;
  font-size: 18px;
  font-weight: bold;
  cursor: pointer;
  transition: transform 0.2s;
}

button:hover {
  transform: translateY(-2px);
}

button:active {
  transform: translateY(0);
}

#status {
  margin-top: 20px;
  padding: 15px;
  border-radius: 10px;
  text-align: center;
  display: none;
}

#status.success {
  background: #d4edda;
  color: #155724;
  display: block;
}

#status.error {
  background: #f8d7da;
  color: #721c24;
  display: block;
}
```

### `website-files/script.js`

```javascript
document.getElementById('contactForm').addEventListener('submit', async (e) => {
  e.preventDefault();

  const form = e.target;
  const statusDiv = document.getElementById('status');
  const button = form.querySelector('button');

  // Disable button podczas wysyłania
  button.disabled = true;
  button.textContent = 'Sending...';

  const data = {
    name: form.name.value,
    email: form.email.value,
    phone: form.phone.value,
    message: form.message.value,
    timestamp: new Date().toISOString()
  };

  try {
    // __api_gateway_url__ zostanie zamieniony przez Terraform na prawdziwy URL
    const response = await fetch('__api_gateway_url__', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    });

    if (response.ok) {
      statusDiv.className = 'success';
      statusDiv.textContent = '✅ Message sent successfully! We\'ll get back to you soon.';
      form.reset();
    } else {
      throw new Error('Server error');
    }
  } catch (error) {
    statusDiv.className = 'error';
    statusDiv.textContent = '❌ Failed to send message. Please try again.';
  } finally {
    button.disabled = false;
    button.textContent = 'Send Message';
  }
});
```

### `website-files/error.html`

```html
<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="UTF-8">
  <title>404 - Page Not Found</title>
  <style>
    body {
      font-family: sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
      background: #f0f0f0;
    }
    .error {
      text-align: center;
    }
    h1 {
      font-size: 72px;
      margin: 0;
      color: #667eea;
    }
    p {
      font-size: 24px;
      color: #666;
    }
  </style>
</head>
<body>
  <div class="error">
    <h1>404</h1>
    <p>Page Not Found</p>
  </div>
</body>
</html>
```

---

## Krok 3: Przygotuj funkcję Lambda

### `lambda/lambda_function.py`

```python
import json
import boto3
from datetime import datetime
from decimal import Decimal

s3 = boto3.client('s3')

def lambda_handler(event, context):
    print(f"Event: {json.dumps(event)}")

    try:
        # Parse body (API Gateway przekazuje jako string)
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', {})

        # Walidacja
        required_fields = ['name', 'email']
        for field in required_fields:
            if field not in body or not body[field]:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({
                        'error': f'Missing required field: {field}'
                    })
                }

        # Przygotuj dane
        timestamp = datetime.now().isoformat()
        filename = f"submissions/{timestamp}_{body['email']}.json"

        # Zapisz do S3 (opcjonalne - wymaga bucketa i uprawnień)
        # bucket_name = 'landing.zaproject.com-form-post-data'
        # s3.put_object(
        #     Bucket=bucket_name,
        #     Key=filename,
        #     Body=json.dumps(body, indent=2),
        #     ContentType='application/json'
        # )

        print(f"Form submitted by {body['email']}")

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Form submitted successfully',
                'data': body
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error'
            })
        }
```

### Spakuj Lambda

```bash
cd lambda
zip lambda_function.zip lambda_function.py
cd ..
```

---

## Krok 4: Terraform Configuration

### `environments/prod/providers.tf`

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}
```

### `environments/prod/variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "domain_name" {
  description = "Domain name for landing page"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM Certificate ARN (must be in us-east-1)"
  type        = string
}

variable "website_source_path" {
  description = "Path to website files"
  type        = string
  default     = "../../website-files"
}

variable "lambda_zip_path" {
  description = "Path to Lambda ZIP file"
  type        = string
  default     = "../../lambda/lambda_function.zip"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Landing Page"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### `environments/prod/terraform.tfvars`

```hcl
# ZMIEŃ NA SWOJE WARTOŚCI!
domain_name          = "landing.zaproject.com"
route53_zone_id      = "Z1234567890ABC"        # Twój Hosted Zone ID
acm_certificate_arn  = "arn:aws:acm:us-east-1:123456789:certificate/xxx-xxx-xxx"

common_tags = {
  Project     = "Landing Page"
  Environment = "production"
  Owner       = "your-name"
}
```

### `environments/prod/main.tf`

```hcl
# ============================================
# API Gateway + Lambda (form submission)
# ============================================
module "form_api" {
  source = "../../modules/form-api"

  function_name       = "landing-form-handler"
  lambda_zip_path     = var.lambda_zip_path
  api_name            = "landing-form-api"
  api_route_key       = "POST /submit"
  enable_function_url = false

  cors_allow_origins = ["*"]  # W produkcji zmień na: ["https://${var.domain_name}"]
  cors_allow_methods = ["POST", "OPTIONS"]
  cors_allow_headers = ["content-type"]

  tags = var.common_tags
}

# ============================================
# S3 Static Website (prywatny z OAC)
# ============================================
module "s3_website" {
  source = "../../modules/s3-static-website"

  domain_name         = var.domain_name
  website_source_path = var.website_source_path
  api_gateway_url     = module.form_api.api_gateway_url

  # KLUCZOWE: Przekaż ARN CloudFront dla OAC
  cloudfront_distribution_arn = module.cloudfront.cloudfront_arn

  tags = var.common_tags

  # UWAGA: Circular dependency - może wymagać 2x terraform apply
  depends_on = [module.cloudfront]
}

# ============================================
# CloudFront + HTTPS + Route53
# ============================================
module "cloudfront" {
  source = "../../modules/cloudfront-https"

  domain_name               = var.domain_name
  s3_bucket_regional_domain = module.s3_website.bucket_regional_domain_name
  acm_certificate_arn       = var.acm_certificate_arn
  route53_zone_id           = var.route53_zone_id

  price_class = "PriceClass_100"  # USA, Canada, Europa

  tags = var.common_tags
}
```

### `environments/prod/outputs.tf`

```hcl
output "website_url" {
  description = "HTTPS URL strony"
  value       = module.cloudfront.website_url
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID (do invalidacji cache)"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "api_gateway_url" {
  description = "API Gateway URL (endpoint formularza)"
  value       = module.form_api.api_gateway_url
}

output "s3_bucket_name" {
  description = "Nazwa bucketa S3"
  value       = module.s3_website.bucket_name
}
```

---

## Krok 5: Deployment

### Inicjalizacja Terraform

```bash
cd environments/prod
terraform init
```

### Plan deployment

```bash
terraform plan
```

Sprawdź output - powinno pokazać utworzenie:
- 1x API Gateway HTTP API
- 1x Lambda Function
- 1x S3 Bucket
- 1x CloudFront Distribution
- 1x Route53 Record
- ~10 innych zasobów (IAM roles, policies, etc.)

### Deploy (dwuetapowy - unikanie circular dependency)

**ETAP 1: S3 + API (bez CloudFront ARN)**

Zakomentuj linię w `main.tf`:
```hcl
# cloudfront_distribution_arn = module.cloudfront.cloudfront_arn  # <-- ZAKOMENTUJ!
```

```bash
terraform apply -target=module.s3_website -target=module.form_api
# Type: yes
```

**ETAP 2: CloudFront**

```bash
terraform apply -target=module.cloudfront
# Type: yes
```

**ETAP 3: Zaktualizuj S3 policy z CloudFront ARN**

Odkomentuj linię:
```hcl
cloudfront_distribution_arn = module.cloudfront.cloudfront_arn  # <-- ODKOMENTUJ!
```

```bash
terraform apply
# Type: yes
```

### Czekaj na propagację CloudFront

```bash
# Sprawdź status dystrybucji
aws cloudfront get-distribution --id $(terraform output -raw cloudfront_distribution_id) \
  | jq '.Distribution.Status'

# Czekaj na "Deployed" (5-15 minut)
```

---

## Krok 6: Test

### Test 1: Podstawowy dostęp

```bash
# Otwórz URL w przeglądarce
open https://landing.zaproject.com
```

Powinieneś zobaczyć stronę z formularzem ✅

### Test 2: Sprawdź HTTPS i certyfikat

```bash
curl -I https://landing.zaproject.com
```

Szukaj:
```
HTTP/2 200
x-cache: Hit from cloudfront
```

### Test 3: Sprawdź czy S3 jest prywatny

```bash
# Bezpośredni dostęp do S3 powinien zwrócić 403
curl -I http://landing.zaproject.com.s3-website-eu-west-1.amazonaws.com
# Oczekiwane: HTTP/1.1 403 Forbidden
```

✅ Jeśli widzisz 403 = S3 jest bezpieczny!

### Test 4: Test formularza

1. Otwórz https://landing.zaproject.com
2. Wypełnij formularz
3. Kliknij "Send Message"
4. Powinieneś zobaczyć: "✅ Message sent successfully!"

### Test 5: Sprawdź logi Lambda

```bash
aws logs tail /aws/lambda/landing-form-handler --follow
```

Powinieneś zobaczyć logi z submitted data.

---

## Krok 7: Aktualizacja strony (zmiana plików)

### Zmień plik lokalnie

```bash
# Edytuj index.html
echo "<h1>Updated Landing Page!</h1>" > ../../website-files/index.html
```

### Deploy zmian

```bash
terraform apply
# Type: yes
```

Terraform wykryje zmiany (porównuje MD5) i upload tylko zmienione pliki.

### Invalidacja cache CloudFront

```bash
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

Czekaj 1-2 minuty, potem odśwież stronę (Ctrl+F5).

---

## Troubleshooting

### Problem 1: Terraform pokazuje "Error: Cycle"

**Rozwiązanie:** Używaj dwuetapowego deployment (patrz Krok 5).

### Problem 2: CloudFront zwraca 403 Forbidden

**Sprawdź:**
```bash
# 1. Bucket policy
aws s3api get-bucket-policy --bucket landing.zaproject.com | jq -r '.Policy' | jq .

# 2. CloudFront origin domain (powinno być bucket regional domain)
aws cloudfront get-distribution --id E123 | jq '.Distribution.DistributionConfig.Origins.Items[0].DomainName'

# 3. OAC ID
aws cloudfront get-distribution --id E123 | jq '.Distribution.DistributionConfig.Origins.Items[0].OriginAccessControlId'
```

### Problem 3: Formularz nie działa (API Gateway error)

**Sprawdź:**
```bash
# Test API Gateway bezpośrednio
curl -X POST $(terraform output -raw api_gateway_url) \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com"}'

# Sprawdź logi Lambda
aws logs tail /aws/lambda/landing-form-handler --follow
```

### Problem 4: DNS nie resolve

```bash
# Sprawdź rekord Route53
aws route53 list-resource-record-sets --hosted-zone-id Z123 \
  | jq '.ResourceRecordSets[] | select(.Name == "landing.zaproject.com.")'

# Test DNS
nslookup landing.zaproject.com

# Propagacja może trwać 5-60 minut
```

---

## Koszty miesięczne (szacunek)

Przy założeniu: Landing page 5MB, 10,000 odwiedzin/miesiąc, 100 formularzy/miesiąc

| Serwis | Koszt |
|--------|-------|
| S3 Storage (5MB) | $0.0001 |
| CloudFront Transfer (50GB) | $4.25 |
| CloudFront Requests (10k) | $0.01 |
| Route53 Hosted Zone | $0.50 |
| Route53 Queries (10k) | $0.01 |
| API Gateway Requests (100) | $0.0001 |
| Lambda Invocations (100) | $0.0001 |
| ACM Certificate | $0 (darmowy) |
| **TOTAL** | **~$4.76/miesiąc** |

**Darmowy tier (pierwsze 12 miesięcy):**
- API Gateway: 1M requestów/miesiąc
- Lambda: 1M requestów/miesiąc
- **Możesz zaoszczędzić ~$0.50/miesiąc w pierwszym roku**

---

## Clean Up (usunięcie wszystkiego)

```bash
cd environments/prod

# UWAGA: To usunie WSZYSTKO (nieodwracalne!)
terraform destroy
# Type: yes

# Sprawdź czy wszystko usunięte
aws s3 ls | grep landing.zaproject.com
# Powinno być puste
```

---

## Co dalej?

### Dodatkowe funkcje:

1. **Email Notifications** - Dodaj AWS SES do Lambda, żeby wysyłać email po submicie formularza
2. **reCAPTCHA** - Dodaj Google reCAPTCHA do formularza (spam protection)
3. **AWS WAF** - Dodaj Web Application Firewall dla security
4. **Multiple Environments** - Stwórz `dev`, `staging`, `prod` environments
5. **CI/CD** - Automatyzuj deployment z GitHub Actions
6. **Monitoring** - Dodaj CloudWatch Alarms dla błędów Lambda
7. **Analytics** - Integruj Google Analytics lub AWS CloudWatch RUM

### Dokumentacja modułów:

- [`modules/s3-static-website/README.md`](../modules/s3-static-website/README.md)
- [`modules/cloudfront-https/README.md`](../modules/cloudfront-https/README.md)
- [`modules/form-api/README.md`](../modules/form-api/README.md) (jeśli istnieje)
- [`docs/CLOUDFRONT_OAC_SECURITY.md`](./CLOUDFRONT_OAC_SECURITY.md)

---

**Autor:** Full-stack deployment guide for juniors
**Ostatnia aktualizacja:** 2024-10-23
