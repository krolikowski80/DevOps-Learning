# API Gateway + Lambda - Instrukcja użycia

## Przegląd architektury

```
User/Frontend → API Gateway → Lambda Function → S3 (w przyszłości)
```

**Komponenty:**
- **API Gateway HTTP API** - publiczny endpoint do wysyłania requestów
- **Lambda Function** - logika przetwarzania requestów
- **IAM Role** - uprawnienia dla Lambda

## Struktura projektu

```
.
├── lambda/                          # Kod Lambda (Python)
│   ├── lambda_function.py          # Handler Lambda
│   └── lambda_function.zip         # Spakowany kod (wymagane przez AWS)
├── modules/form-api/               # Moduł Terraform
│   ├── main.tf                     # API Gateway, Lambda, IAM
│   ├── variables.tf                # Parametry wejściowe
│   └── outputs.tf                  # Outputy (URL, ARN, itp.)
└── environments/dev/               # Konfiguracja środowiska
    └── main.tf                     # Wywołanie modułu
```

## Jak wdrożyć (deployment)

### 1. Przygotuj kod Lambda

Edytuj kod w `lambda/lambda_function.py`:

```python
import json

def lambda_handler(event, context):
    # Twoja logika tutaj
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "OK"})
    }
```

### 2. Spakuj kod do ZIP

```bash
cd lambda
zip lambda_function.zip lambda_function.py
cd ..
```

**WAŻNE:** Za każdym razem gdy zmieniasz kod Lambda, musisz:
1. Zaktualizować `lambda_function.py`
2. Przepakować do ZIP: `zip lambda_function.zip lambda_function.py`
3. Uruchomić `terraform apply`

### 3. Wdróż infrastrukturę

```bash
cd environments/dev
terraform init      # Tylko za pierwszym razem
terraform plan      # Sprawdź co się zmieni
terraform apply     # Wdróż zmiany
```

### 4. Odbierz URL endpointu

Po `terraform apply` dostaniesz:

```
Outputs:

api_gateway_url = "https://xxx.execute-api.eu-central-1.amazonaws.com/submit"
lambda_function_url = "https://xxx.lambda-url.eu-central-1.on.aws/"
```

- **api_gateway_url** - użyj tego w aplikacji front-endowej
- **lambda_function_url** - bezpośredni dostęp do Lambda (opcjonalny)

## Testowanie API

### Metoda 1: curl (terminal)

```bash
# Test podstawowy
curl -X POST https://xxx.execute-api.eu-central-1.amazonaws.com/submit \
  -H "Content-Type: application/json" \
  -d '{"name": "Jan", "email": "jan@example.com", "phone": "123456789"}'

# Test z zapisaniem odpowiedzi
curl -X POST https://xxx.execute-api.eu-central-1.amazonaws.com/submit \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}' \
  -o response.json
```

### Metoda 2: Postman

1. Otwórz Postman
2. Utwórz nowy request:
   - **Method:** POST
   - **URL:** `https://xxx.execute-api.eu-central-1.amazonaws.com/submit`
3. W Headers dodaj:
   - `Content-Type: application/json`
4. W Body wybierz "raw" → "JSON" i wklej:
   ```json
   {
     "name": "Jan",
     "email": "jan@example.com",
     "phone": "123456789"
   }
   ```
5. Kliknij **Send**

### Metoda 3: AWS Console (Test wbudowany)

1. Zaloguj się do AWS Console
2. Przejdź do: **API Gateway** → **APIs** → **form-api**
3. Kliknij na: **Routes** → **POST /submit**
4. Kliknij: **Test**
5. W sekcji **Request body** wklej JSON:
   ```json
   {"name": "Jan", "email": "jan@example.com"}
   ```
6. Kliknij **Test**

### Metoda 4: Test Lambda bezpośrednio (bez API Gateway)

1. AWS Console → **Lambda** → **Functions** → **my_lambda**
2. Zakładka **Test**
3. Kliknij **Create new test event**
4. Wybierz template: **API Gateway AWS Proxy**
5. Edytuj JSON (sekcja `body`):
   ```json
   {
     "body": "{\"name\":\"Jan\",\"email\":\"jan@example.com\"}"
   }
   ```
6. Kliknij **Test**

## Konfiguracja modułu

### Parametry w `environments/dev/main.tf`

```hcl
module "form_api" {
  source = "../../modules/form-api"

  # WYMAGANE
  function_name    = "my_lambda"                      # Nazwa funkcji Lambda w AWS
  lambda_zip_path  = "../../lambda/lambda_function.zip"  # Ścieżka do ZIP
  api_name         = "form-api"                       # Nazwa API Gateway

  # OPCJONALNE
  api_description     = "API Gateway for form submission"
  api_route_key       = "POST /submit"                # Metoda + path
  enable_function_url = true                          # Bezpośredni URL do Lambda
  lambda_runtime      = "python3.9"                   # Wersja Pythona
  lambda_handler      = "lambda_function.lambda_handler"

  # CORS (Cross-Origin Resource Sharing)
  cors_allow_origins = ["*"]                          # Dozwolone domeny (lub "*")
  cors_allow_methods = ["POST", "GET", "OPTIONS"]
  cors_allow_headers = ["content-type"]

  tags = {
    Environment = "dev"
    Project     = "FormAPI"
  }
}
```

### Zmiana route'a

Jeśli chcesz inny endpoint, np. `POST /contact`:

```hcl
api_route_key = "POST /contact"
```

URL będzie: `https://xxx.execute-api.eu-central-1.amazonaws.com/contact`

### Dodanie autoryzacji

Domyślnie endpoint jest **publiczny** (bez autoryzacji). Aby dodać autoryzację, edytuj `modules/form-api/main.tf`.

## Monitoring i logi

### Logi Lambda

```bash
# AWS CLI
aws logs tail /aws/lambda/my_lambda --follow

# Lub w AWS Console
Lambda → my_lambda → Monitor → View logs in CloudWatch
```

### Metryki API Gateway

AWS Console → API Gateway → form-api → Monitor

Metryki:
- **Count** - liczba requestów
- **Latency** - czas odpowiedzi
- **4XX/5XX Errors** - błędy

## Częste problemy

### Problem: `terraform apply` błąd "lambda_function.zip not found"

**Przyczyna:** Nie utworzono ZIP albo ścieżka jest błędna

**Rozwiązanie:**
```bash
cd lambda
zip lambda_function.zip lambda_function.py
cd ../environments/dev
terraform apply
```

### Problem: API Gateway zwraca 500 Internal Server Error

**Przyczyna:** Lambda wywaliła błąd

**Debugowanie:**
1. Sprawdź logi Lambda w CloudWatch
2. Test Lambda bezpośrednio w AWS Console
3. Sprawdź uprawnienia IAM (czy Lambda ma dostęp do S3/innych serwisów)

### Problem: CORS error w przeglądarce

**Przyczyna:** Niewłaściwa konfiguracja CORS

**Rozwiązanie:** W `environments/dev/main.tf`:
```hcl
cors_allow_origins = ["https://twoja-domena.com"]  # Lub "*" dla wszystkich
cors_allow_methods = ["POST", "OPTIONS"]
cors_allow_headers = ["content-type", "authorization"]
```

### Problem: Zmiany w kodzie Lambda nie działają po `terraform apply`

**Przyczyna:** Terraform nie widzi zmian w ZIP (ten sam hash)

**Rozwiązanie:**
1. Usuń stary ZIP: `rm lambda/lambda_function.zip`
2. Stwórz nowy: `cd lambda && zip lambda_function.zip lambda_function.py`
3. Terraform apply: `cd ../environments/dev && terraform apply`

## Dodawanie nowych funkcji Lambda

### Krok 1: Nowy plik Python

```bash
# Dodaj nowy plik
touch lambda/email_handler.py

# Spakuj wszystko
cd lambda
zip -r email_function.zip email_handler.py
```

### Krok 2: Nowy moduł w Terraform

```hcl
# W environments/dev/main.tf
module "email_api" {
  source = "../../modules/form-api"

  function_name   = "email_handler"
  lambda_zip_path = "../../lambda/email_function.zip"
  api_name        = "email-api"
  api_route_key   = "POST /send-email"
  tags            = var.tags
}
```

### Krok 3: Deploy

```bash
terraform apply
```

## Integracja z front-endem

### JavaScript (fetch API)

```javascript
async function submitForm(formData) {
  const response = await fetch('https://xxx.execute-api.eu-central-1.amazonaws.com/submit', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(formData)
  });

  const data = await response.json();
  return data;
}

// Użycie
const formData = {
  name: "Jan Kowalski",
  email: "jan@example.com",
  phone: "123456789"
};

submitForm(formData)
  .then(data => console.log('Success:', data))
  .catch(error => console.error('Error:', error));
```

### HTML formularz

```html
<!DOCTYPE html>
<html>
<head>
  <title>Contact Form</title>
</head>
<body>
  <form id="contactForm">
    <input type="text" name="name" placeholder="Imię" required>
    <input type="email" name="email" placeholder="Email" required>
    <input type="tel" name="phone" placeholder="Telefon" required>
    <button type="submit">Wyślij</button>
  </form>

  <script>
    document.getElementById('contactForm').addEventListener('submit', async (e) => {
      e.preventDefault();

      const formData = {
        name: e.target.name.value,
        email: e.target.email.value,
        phone: e.target.phone.value
      };

      const response = await fetch('https://xxx.execute-api.eu-central-1.amazonaws.com/submit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      const result = await response.json();
      alert('Formularz wysłany!');
    });
  </script>
</body>
</html>
```

## Koszty AWS

**Darmowy tier (Free Tier):**
- API Gateway: 1 milion requestów/miesiąc (12 miesięcy)
- Lambda: 1 milion requestów + 400,000 GB-sekund/miesiąc (zawsze darmowe)

**Po przekroczeniu:**
- API Gateway: ~$1 za milion requestów
- Lambda: ~$0.20 za milion requestów
- CloudWatch Logs: ~$0.50/GB

**Szacunek:** Przy 10,000 requestów/miesiąc ≈ **$0** (w ramach free tier)

## Usuwanie infrastruktury

```bash
cd environments/dev
terraform destroy
```

**UWAGA:** To usunie wszystko - API Gateway, Lambda, IAM Role. Dane w S3 (jeśli istnieją) też zostaną usunięte jeśli `force_destroy = true`.

## Checklist przed wdrożeniem na produkcję

- [ ] Zmień CORS origins z `["*"]` na konkretne domeny
- [ ] Dodaj monitoring i alerty CloudWatch
- [ ] Skonfiguruj API Gateway throttling (limit requestów)
- [ ] Dodaj autoryzację (API Key, Lambda Authorizer, Cognito)
- [ ] Włącz X-Ray dla debugowania
- [ ] Backup kodu Lambda w S3
- [ ] Dokumentacja API (Swagger/OpenAPI)
- [ ] Testy obciążeniowe
- [ ] Logowanie do zewnętrznego systemu (np. Datadog, Sentry)

## Pomocne komendy AWS CLI

```bash
# Lista funkcji Lambda
aws lambda list-functions --region eu-central-1

# Sprawdź konfigurację Lambda
aws lambda get-function --function-name my_lambda

# Invoke Lambda ręcznie
aws lambda invoke --function-name my_lambda --payload '{"test":"data"}' response.json

# Lista API Gateway
aws apigatewayv2 get-apis --region eu-central-1

# Logi Lambda (ostatnie 5 minut)
aws logs tail /aws/lambda/my_lambda --since 5m

# Usuń konkretną Lambda
aws lambda delete-function --function-name my_lambda
```

## Zasoby

- [AWS Lambda Docs](https://docs.aws.amazon.com/lambda/)
- [API Gateway HTTP API Docs](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
