# S3 Static Website Module - Notatki z nauki

## 🎯 Czym w ogóle jest S3 Static Website?

**Podstawy:** S3 to AWS storage, ale można go skonfigurować żeby działał jak web server. Zamiast wynajmować EC2 i stawiać Apache/Nginx, po prostu wrzucasz HTML/CSS/JS do bucketa i AWS serwuje to jako stronę internetową.

**Dlaczego to super:**
- ✅ **Tanie** - płacisz tylko za storage i transfer
- ✅ **Skalowalne** - AWS obsłuży miliony requestów
- ✅ **Proste** - nie musisz zarządzać serwerami
- ✅ **Niezawodne** - 99.9% uptime z AWS

## 📁 Struktura modułu (moja organizacja)

```
learning/modules/S3/
├── main.tf         # Wszystkie resources - mózg modułu
├── variables.tf    # Parametry wejściowe - co można konfigurować
├── outputs.tf      # Co moduł zwraca - URL do strony
└── files/
    ├── index.html  # Strona główna
    └── 404.html    # Strona błędu
```

**Przemyślenia o strukturze:**
- **Dlaczego files/ w module?** Bo to proste do nauki. W prodzie pliki deployuje się przez CI/CD
- **Dlaczego osobny outputs.tf?** Bo lubię mieć outputs oddzielnie - łatwiej się odnaleźć
- **Dlaczego wszystko w main.tf?** Bo to mały moduł. Większe moduły robiłbym z podziałem na pliki

## 🔧 Resources - szczegółowe wyjaśnienia

### 1. aws_s3_bucket - podstawowy pojemnik

```hcl
resource "aws_s3_bucket" "static_sitee" {
  bucket = var.bucket_name
  tags = {
    Name        = "MyStaticSiteBucket"
    Environment = var.environment
  }
}
```

**Co to robi:**
- Tworzy podstawowy bucket (pojemnik na pliki)
- Bucket name MUSI być globalnie unikalny w całym AWS (dlatego "tomasz-dev-static-site")
- Tags pomagają w organizacji i billing

**Lessons learned:**
- **Dlaczego var.bucket_name?** Bo chcę używać tego modułu w dev i prod z różnymi nazwami
- **Dlaczego nie dodałem region?** Provider już to ustawia w provider.tf
- **Dlaczego static_sitee z 'ee'?** Bo pierwszy raz zrobiłem typo i zostało 😅

### 2. aws_s3_bucket_website_configuration - magia web hostingu

```hcl
resource "aws_s3_bucket_website_configuration" "static_sitee_config" {
  bucket = aws_s3_bucket.static_sitee.id
  
  index_document {
    suffix = var.main_page_suffix  # index.html
  }
  error_document {
    key = var.not_found_page      # 404.html
  }
}
```

**Co to robi:**
- **Zmienia bucket ze storage na web server!**
- `index_document` - jaki plik pokazać gdy ktoś wejdzie na główną stronę
- `error_document` - jaki plik pokazać gdy strona nie istnieje (404)

**Kluczowe insights:**
- **Bez tego resource bucket to tylko storage** - pliki można pobrać, ale nie da się przeglądać jak strona
- **index_document suffix** - to rozszerzenie, nie pełna nazwa pliku
- **error_document key** - to pełna nazwa pliku
- **Reference do bucket.id** - Terraform wie że najpierw bucket, potem konfiguracja

### 3. aws_s3_bucket_public_access_block - bezpieczeństwo vs dostępność

```hcl
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.static_sitee.id
  
  block_public_acls       = false  # Musi być false!
  block_public_policy     = false  # Musi być false!
  ignore_public_acls      = false
  restrict_public_buckets = false
}
```

**Co to robi:**
- **AWS domyślnie blokuje publiczny dostęp** (bezpieczeństwo)
- **Dla static website MUSIMY wyłączyć blokady**
- To jest jak "przełącznik główny" dla publicznego dostępu

**Dlaczego to takie ważne:**
- **AWS security first** - domyślnie wszystko prywatne
- **Musisz świadomie włączyć publiczny dostęp** - nie przypadkowo
- **Częsty błąd początkujących** - zapomnienie o tym resource

**Zastanawiałem się:** Czy to nie niebezpieczne? Ale bez tego strona nie będzie dostępna z internetu. W prodzie dodałbym CloudFront żeby ograniczyć dostęp.

### 4. aws_s3_bucket_policy - IAM dla publicznego czytania

```hcl
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.static_sitee.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"                                    # Wszyscy użytkownicy
        Action    = "s3:GetObject"                        # Tylko czytanie plików
        Resource  = "${aws_s3_bucket.static_sitee.arn}/*" # Wszystkie pliki w bucket
      }
    ]
  })
  
  depends_on = [aws_s3_bucket_public_access_block.public_access_block]
}
```

**Co to robi:**
- **Definiuje kto i co może robić z plikami**
- `Principal = "*"` - wszyscy (internet)
- `Action = "s3:GetObject"` - tylko pobieranie/czytanie (nie upload, nie delete)
- `Resource = "arn/*"` - wszystkie pliki w bucket

**Bezpieczeństwo:**
- **Tylko GetObject** - nikt nie może uploadować ani usuwać
- **Tylko pliki** - nikt nie może listować bucket ani zmieniać ustawień
- **depends_on ważne** - najpierw access block, potem policy

**Nauka o JSON w Terraform:**
- `jsonencode()` zamienia HCL na JSON
- Można było wkleić string JSON, ale HCL czytelniejszy
- AWS IAM policy to zawsze JSON format

### 5. aws_s3_object - upload plików przez Terraform

```hcl
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static_sitee.bucket
  key          = var.main_page_suffix              # index.html
  source       = "${path.module}/files/${var.main_page_suffix}"
  content_type = "text/html"
}

resource "aws_s3_object" "not_found_page_404_html" {
  bucket       = aws_s3_bucket.static_sitee.bucket
  key          = var.not_found_page                # 404.html
  source       = "${path.module}/files/${var.not_found_page}"
  content_type = "text/html"
}
```

**Co to robi:**
- **Upload plików z lokalnego dysku do S3**
- `key` - nazwa pliku w bucket (jak go widać w AWS)
- `source` - skąd wziąć plik lokalnie
- `content_type` - mówi przeglądarce co to za typ pliku

**Szczegóły techniczne:**
- **${path.module}** - ścieżka do katalogu modułu (nie environment!)
- **content_type ważny** - bez tego przeglądarka nie wie czy to HTML czy plik do download
- **Terraform trackuje zmiany** - jak zmienisz plik lokalnie, terraform to wykryje

**Przemyślenia:**
- **Czy upload przez Terraform to dobra praktyka?** Dla nauki tak, dla prodji lepiej CI/CD
- **Dlaczego używam zmiennych?** Bo chcę móc zmienić nazwy plików bez zmiany kodu
- **Co jak plik nie istnieje?** Terraform się wywali - trzeba najpierw stworzyć pliki

## 🎛️ Variables - parametryzacja modułu

```hcl
variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
}

variable "main_page_suffix" {
  description = "Index document for website"
  type        = string
  default     = "index.html"
}

variable "not_found_page" {
  description = "Error document for website"
  type        = string
  default     = "404.html"
}
```

**Filozofia parametryzacji:**
- **Wszystko co może się różnić między environments = zmienna**
- **Sensowne defaults** - moduł działa out-of-box
- **Dobre descriptions** - za 6 miesięcy nie pamiętam co to robiło

**Przemyślenia o każdej zmiennej:**

**bucket_name** - musi być zmienna bo:
- Dev: `tomasz-dev-static-site`
- Prod: `tomasz-prod-static-site`
- Każdy dev może mieć swój prefix

**environment** - używam w tags, przydatne do:
- Billing (ile kosztuje dev vs prod)
- Monitoring (alerty per environment)
- Governance (polityki per environment)

**main_page_suffix/not_found_page** - mają defaults ale:
- Można zmienić na `start.html` czy coś
- Różne języki (index_pl.html, index_en.html)
- A/B testing różnych stron

## 📤 Outputs - co moduł zwraca

```hcl
output "website_url" {
  description = "URL of the static website"
  value       = aws_s3_bucket_website_configuration.static_sitee_config.website_endpoint
}
```

**Dlaczego output:**
- **Potrzebuję URL żeby otworzyć stronę** po deployment
- **Inne moduły mogą używać** tego URL (np. CloudFront)
- **CI/CD może wyświetlić** URL w logach

**Detale techniczne:**
- **website_endpoint** to specjalny URL S3 dla static hosting
- **Różni się od normalnego S3 URL** - obsługuje index.html redirects
- **Format:** `bucket-name.s3-website-region.amazonaws.com`

## 🏗️ Integracja z environment

### Struktura wywołania w main.tf:
```hcl
module "s3" {
  source           = "../../modules/S3"
  bucket_name      = var.bucket_name
  environment      = var.environment
  main_page_suffix = var.main_page_suffix
  not_found_page   = var.not_found_page
}
```

**Dlaczego duplikacja zmiennych?**
- **Module variables** = parametry wejściowe (jak arguments funkcji)
- **Environment variables** = konfiguracja środowiska (jak config file)
- **To normalna praktyka** w Terraform - nie da się tego uniknąć

### Wartości w dev.tfvars:
```hcl
bucket_name      = "tomasz-dev-static-site"  # Unikalna nazwa
environment      = "dev"                     # Tag environment
main_page_suffix = "index.html"              # Standard
not_found_page   = "404.html"                # Standard
```

**Strategia nazewnictwa:**
- **Prefix z imieniem** - żeby nie kolidować z innymi
- **Environment w nazwie** - łatwo rozróżnić dev/prod
- **Krótkie ale opisowe** - bucket names mają limity

## 🚨 Błędy i rozwiązania (moje fails)

### Fail #1: ACL deprecated
**Co robiłem źle:**
```hcl
acl = "public-read"  # Już nie działa!
```
**Error message:** "ACL-based access control is deprecated"

**Dlaczego się wywaliło:**
- AWS zmienił politykę bezpieczeństwa
- ACL to stary sposób, teraz bucket policies
- Nowa wersja AWS provider nie obsługuje

**Rozwiązanie:**
Usunąć ACL, użyć bucket_policy + public_access_block

### Fail #2: Hardcoded values w tags
**Co robiłem źle:**
```hcl
Environment = "development"  # Co jak chcę prod?
```

**Dlaczego to słabe:**
- Nie mogę użyć modułu w prod
- Copy-paste programming zamiast reusable code
- Scaling nightmare

**Rozwiązanie:**
```hcl
Environment = var.environment  # Parametryzacja FTW
```

### Fail #3: Zmienne w cudzysłowach
**Co robiłem źle:**
```hcl
Environment = "var.environment"  # Literal string!
```

**Co się stało:**
- Tag miał wartość "var.environment" zamiast "dev"
- Terraform interpretował to jako string, nie zmienną
- Typowy błąd początkującego

**Rozwiązanie:**
```hcl
Environment = var.environment  # Bez cudzysłowów!
```

### Fail #4: Złe ścieżki do plików
**Co się stało:**
```
key = "files/index.html"           # Źle!
source = "files/files/index.html"  # Podwójne files/
```

**Dlaczego:**
- Pomylki w interpolacji zmiennych
- Nie przemyślałem jak variables działają w ścieżkach
- Copy-paste z różnych źródeł

**Debugowanie:**
```bash
terraform plan  # Pokazuje co będzie stworzone
```
Tam zobaczyłem że ścieżki są pokręcone

**Rozwiązanie:**
```hcl
key    = var.main_page_suffix                    # index.html
source = "${path.module}/files/${var.main_page_suffix}"  # path/to/module/files/index.html
```

## 🎯 Kluczowe learnings (co mnie zaskoczyło)

### 1. S3 website hosting to nie tylko bucket
**Myślałem:** Stworzę bucket, wrzucę plik, będzie działać  
**Rzeczywistość:** Potrzebuję 5 różnych resources żeby to działało

**Lekcja:** AWS rozbija funkcjonalność na małe kawałki. Bezpieczeństwo przez separation of concerns.

### 2. Public access to skomplikowana sprawa
**Myślałem:** Dam "public-read" i będzie git  
**Rzeczywistość:** Public access block + bucket policy + jeszcze pewnie CloudFront w prodji

**Lekcja:** AWS naprawdę dba o bezpieczeństwo. Trzeba świadomie i na kilku poziomach włączyć publiczny dostęp.

### 3. Terraform modules to jak functions
**Myślałem:** Module to folder z plikami  
**Rzeczywistość:** Module to interface z input variables i outputs, ma swój lifecycle

**Lekcja:** Myślenie o modules jak o reusable functions pomaga w projektowaniu.

### 4. Variables vs values - głębsze zrozumienie
**Myślałem:** Czemu duplikuję zmienne między module a environment?  
**Zrozumiałem:** To są różne warstwy abstrakcji

```
Environment values -> Module variables -> Resource attributes
"tomasz-dev"      -> var.bucket_name  -> bucket = var.bucket_name
```

### 5. Path interpolation
**Nowe:** `${path.module}/files/` - ścieżka względna do modułu  
**Dlaczego ważne:** Module może być wywołany z różnych miejsc, ale pliki są zawsze w module

## 🔄 Workflow (jak pracuję z tym module)

### Development cycle:
```bash
# 1. Edytuję moduł
vim learning/modules/S3/main.tf

# 2. Przechodzę do environment
cd learning/environments/dev

# 3. Sprawdzam plan
terraform plan -var-file=dev.tfvars
# Patrzę czy resources wyglądają ok, czy ścieżki się zgadzają

# 4. Jeśli ok, wdrażam
terraform apply -var-file=dev.tfvars

# 5. Testuję w przeglądarce
# URL z terraform output albo AWS console

# 6. Jak coś nie działa
terraform show  # Zobacz co zostało stworzone
terraform destroy -var-file=dev.tfvars  # Wyczyść i spróbuj ponownie
```

### Debugging workflow:
```bash
# Problem z public access?
aws s3api get-bucket-policy --bucket tomasz-dev-static-site
aws s3api get-public-access-block --bucket tomasz-dev-static-site

# Problem z plikami?
aws s3 ls s3://tomasz-dev-static-site
aws s3api head-object --bucket tomasz-dev-static-site --key index.html

# Problem z website config?
aws s3api get-bucket-website --bucket tomasz-dev-static-site
```

## 🏆 Co osiągnąłem (konkretnie)

### ✅ Techniczne achievements:
- **Reusable module** - działa w dev, będzie działać w prod
- **Kompletny static website** - hosting + security + pliki
- **Professional structure** - czysty kod, parametryzacja
- **Error handling** - 404 page, proper content types
- **Output integration** - inne moduły mogą używać URL

### ✅ Konceptualne zrozumienie:
- **AWS S3 website hosting** - jak to działa pod spodem
- **Terraform module design** - inputs, processing, outputs
- **AWS security model** - layers of protection
- **Multi-environment patterns** - jak skalować kod


## 📊 Porównanie z VPC module

**Podobieństwa:**
- Multi-environment structure (dev/prod)
- Reusable module z variables
- Professional Terraform patterns

**Różnice:**
- **VPC = infrastruktura** / S3 = aplikacja
- **VPC = networking** / S3 = storage + web server
- **VPC = foundation** / S3 = konkretny use case

**Co było łatwiejsze:** S3 ma mniej moving parts  
**Co było trudniejsze:** Security configuration bardziej skomplikowane

## 📚 Następne kroki (moja roadmapa)

### Natychmiastowe improvements:
- [ ] **Dodać force_destroy = true** - łatwiejsze cleanup podczas nauki
- [ ] **Versioning bucket** - backup dla content
- [ ] **Outputs rozszerzyć** - bucket ARN, domain name


## 💭 Refleksje nad nauką

**Co poszło dobrze:**
- Krok po kroku approach - nie rzuciłem się na cały kod od razu
- Testowanie po każdej zmianie - terraform plan saved my ass
- Dokumentowanie błędów - teraz wiem dlaczego ACL nie działa

**Co mogłbym lepiej:**
- Wcześniej przeczytać o AWS security model
- Zrobić research o best practices przed kodowaniem
- Więcej czasu na planowanie struktury