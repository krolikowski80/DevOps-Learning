# AWS CLI Ściągawka - Edycja DevOps

> Kompletny przewodnik AWS CLI do codziennych operacji DevOps

## 🔧 Konfiguracja i Ustawienia

### Początkowa konfiguracja
```bash
# Konfiguracja AWS CLI
aws configure

# Sprawdzenie obecnej konfiguracji
aws configure list

# Sprawdzenie tożsamości użytkownika
aws sts get-caller-identity

# Ustawienie regionu dla sesji
export AWS_DEFAULT_REGION=eu-west-1
```

### Wiele profili
```bash
# Konfiguracja nazwanego profilu
aws configure --profile produkcja

# Użycie konkretnego profilu
aws s3 ls --profile produkcja

# Ustawienie domyślnego profilu dla sesji
export AWS_PROFILE=produkcja
```

## 💰 Rozliczenia i Zarządzanie Kosztami

### Koszty bieżącego miesiąca
```bash
# Całkowity koszt od początku miesiąca
aws ce get-cost-and-usage \
  --time-period Start=2025-07-01,End=2025-07-17 \
  --granularity MONTHLY \
  --metrics BlendedCost

# Koszty dzienne (ostatnie 7 dni)
aws ce get-cost-and-usage \
  --time-period Start=2025-07-10,End=2025-07-17 \
  --granularity DAILY \
  --metrics BlendedCost
```

### Podział kosztów
```bash
# Koszty według usług AWS
aws ce get-cost-and-usage \
  --time-period Start=2025-07-01,End=2025-07-17 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Koszty według regionów
aws ce get-cost-and-usage \
  --time-period Start=2025-07-01,End=2025-07-17 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=REGION

# Koszty według tagów zasobów
aws ce get-cost-and-usage \
  --time-period Start=2025-07-01,End=2025-07-17 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Environment
```

### Alerty budżetowe
```bash
# Lista budżetów
aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text)

# Utworzenie alertu budżetowego
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budzet.json
```

## 🌐 VPC i Sieć

### Operacje VPC
```bash
# Lista wszystkich VPC
aws ec2 describe-vpcs

# Znajdź VPC po tagu
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=dev-vpc"

# Utwórz VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# Usuń VPC
aws ec2 delete-vpc --vpc-id vpc-12345678

# Znajdż AMI w regionie
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images[*].[ImageId,Name,CreationDate]' \
  --output table \
  --region eu-west-1 | head -10
```

### Zarządzanie podsieciami
```bash
# Lista podsieci w VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-12345678"

# Znajdź podsieć po tagu
aws ec2 describe-subnets --filters "Name=tag:Name,Values=dev-public-subnet-01"

# Utwórz podsieć
aws ec2 create-subnet --vpc-id vpc-12345678 --cidr-block 10.0.1.0/24

# Modyfikuj podsieć (włącz auto-przypisywanie publicznych IP)
aws ec2 modify-subnet-attribute --subnet-id subnet-12345678 --map-public-ip-on-launch
```

### Grupy bezpieczeństwa
```bash
# Lista grup bezpieczeństwa
aws ec2 describe-security-groups

# Znajdź grupę bezpieczeństwa po nazwie
aws ec2 describe-security-groups --filters "Name=group-name,Values=web-servers"

# Dodaj regułę przychodzącą (dostęp SSH)
aws ec2 authorize-security-group-ingress \
  --group-id sg-12345678 \
  --protocol tcp \
  --port 22 \
  --source-group sg-87654321

# Usuń regułę przychodzącą
aws ec2 revoke-security-group-ingress \
  --group-id sg-12345678 \
  --protocol tcp \
  --port 22 \
  --source-group sg-87654321
```

## 🖥️ Zarządzanie Instancjami EC2

### Operacje na instancjach
```bash
# Lista wszystkich instancji
aws ec2 describe-instances

# Lista tylko uruchomionych instancji
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# Znajdź instancje po tagu
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev"

# Szczegóły konkretnej instancji
aws ec2 describe-instances --instance-ids i-1234567890abcdef0
```

### Cykl życia instancji
```bash
# Uruchom instancję
aws ec2 run-instances \
  --image-id ami-12345678 \
  --count 1 \
  --instance-type t3.micro \
  --key-name moj-klucz \
  --security-group-ids sg-12345678 \
  --subnet-id subnet-12345678

# Uruchom zatrzymaną instancję
aws ec2 start-instances --instance-ids i-1234567890abcdef0

# Zatrzymaj działającą instancję
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Restart instancji
aws ec2 reboot-instances --instance-ids i-1234567890abcdef0

# Zakończ instancję (usuń)
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
```

### Informacje o instancji
```bash
# Pobierz publiczne IP instancji
aws ec2 describe-instances \
  --instance-ids i-1234567890abcdef0 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

# Pobierz prywatne IP instancji
aws ec2 describe-instances \
  --instance-ids i-1234567890abcdef0 \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text

# Status instancji
aws ec2 describe-instance-status --instance-ids i-1234567890abcdef0
```

## 🗄️ Przechowywanie S3

### Operacje na bucketach
```bash
# Lista wszystkich bucketów
aws s3 ls

# Zawartość bucketa
aws s3 ls s3://moj-bucket/

# Lista ze szczegółami
aws s3 ls s3://moj-bucket/ --recursive --human-readable --summarize

# Utwórz bucket
aws s3 mb s3://moj-nowy-bucket --region eu-west-1

# Usuń pusty bucket
aws s3 rb s3://moj-bucket

# Usuń bucket z zawartością
aws s3 rb s3://moj-bucket --force
```

### Operacje na plikach
```bash
# Wyślij plik
aws s3 cp plik.txt s3://moj-bucket/

# Wyślij katalog (rekursywnie)
aws s3 cp ./lokalny-folder s3://moj-bucket/zdalny-folder/ --recursive

# Pobierz plik
aws s3 cp s3://moj-bucket/plik.txt ./lokalny-plik.txt

# Pobierz katalog
aws s3 cp s3://moj-bucket/folder/ ./lokalny-folder/ --recursive

# Synchronizuj katalogi
aws s3 sync ./lokalny-folder s3://moj-bucket/zdalny-folder/
```

### Konfiguracja bucketa
```bash
# Sprawdź wersjonowanie bucketa
aws s3api get-bucket-versioning --bucket moj-bucket

# Włącz wersjonowanie
aws s3api put-bucket-versioning \
  --bucket moj-bucket \
  --versioning-configuration Status=Enabled

# Ustaw politykę bucketa
aws s3api put-bucket-policy --bucket moj-bucket --policy file://polityka.json

# Pobierz politykę bucketa
aws s3api get-bucket-policy --bucket moj-bucket
```

## 🔐 IAM (Zarządzanie Tożsamością i Dostępem)

### Zarządzanie użytkownikami
```bash
# Lista użytkowników
aws iam list-users

# Szczegóły użytkownika
aws iam get-user --user-name nazwa-uzytkownika

# Utwórz użytkownika
aws iam create-user --user-name nowy-uzytkownik

# Usuń użytkownika
aws iam delete-user --user-name nazwa-uzytkownika
```

### Zarządzanie politykami
```bash
# Lista przypisanych polityk użytkownika
aws iam list-attached-user-policies --user-name nazwa-uzytkownika

# Przypisz politykę do użytkownika
aws iam attach-user-policy \
  --user-name nazwa-uzytkownika \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Odepnij politykę od użytkownika
aws iam detach-user-policy \
  --user-name nazwa-uzytkownika \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Lista polityk zarządzanych przez AWS
aws iam list-policies --scope AWS --max-items 50
```

### Zarządzanie rolami
```bash
# Lista ról
aws iam list-roles

# Szczegóły roli
aws iam get-role --role-name MojaRola

# Przejmij rolę
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/MojaRola \
  --role-session-name MojaSesja
```

## 🏷️ Tagowanie Zasobów

### Tagowanie EC2
```bash
# Dodaj tagi do instancji
aws ec2 create-tags \
  --resources i-1234567890abcdef0 \
  --tags Key=Environment,Value=dev Key=Owner,Value=tomasz

# Usuń tagi z instancji
aws ec2 delete-tags \
  --resources i-1234567890abcdef0 \
  --tags Key=Environment Key=Owner

# Znajdź zasoby po tagu
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev"
```

### Tagowanie S3
```bash
# Dodaj tagi do bucketa S3
aws s3api put-bucket-tagging \
  --bucket moj-bucket \
  --tagging 'TagSet=[{Key=Environment,Value=dev},{Key=Owner,Value=tomasz}]'

# Pobierz tagi bucketa
aws s3api get-bucket-tagging --bucket moj-bucket

# Usuń tagi bucketa
aws s3api delete-bucket-tagging --bucket moj-bucket
```

## 📊 Monitorowanie i Logi

### Metryki CloudWatch
```bash
# Lista dostępnych metryk
aws cloudwatch list-metrics --namespace AWS/EC2

# Pobierz statystyki metryki
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --start-time 2025-07-16T00:00:00Z \
  --end-time 2025-07-16T23:59:59Z \
  --period 3600 \
  --statistics Average
```

### Logi CloudWatch
```bash
# Lista grup logów
aws logs describe-log-groups

# Lista strumieni logów
aws logs describe-log-streams --log-group-name /aws/lambda/moja-funkcja

# Pobierz zdarzenia z logów
aws logs get-log-events \
  --log-group-name /aws/lambda/moja-funkcja \
  --log-stream-name 2025/07/16/[wersja]
```

## 🔍 Przydatne Filtry i Zapytania

### Popularne filtry
```bash
# Tylko uruchomione instancje
--filters "Name=instance-state-name,Values=running"

# Instancje po tagu
--filters "Name=tag:Environment,Values=dev"

# Zasoby w konkretnym VPC
--filters "Name=vpc-id,Values=vpc-12345678"

# Zasoby w konkretnej podsieci
--filters "Name=subnet-id,Values=subnet-12345678"
```

### Zapytania JQ (z zainstalowanym jq)
```bash
# Pobierz wszystkie ID instancji
aws ec2 describe-instances | jq -r '.Reservations[].Instances[].InstanceId'

# Pobierz nazwę i stan instancji
aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | "\(.Tags[]|select(.Key=="Name")|.Value) - \(.State.Name)"'

# Pobierz bloki CIDR VPC
aws ec2 describe-vpcs | jq -r '.Vpcs[] | "\(.VpcId) - \(.CidrBlock)"'
```

## 🚀 Skrypty Automatyzacji DevOps

### Sprawdzenie zdrowia instancji
```bash
#!/bin/bash
# Sprawdź wszystkie uruchomione instancje
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output table
```

### Skrypt alertu kosztów
```bash
#!/bin/bash
# Pobierz koszty od początku miesiąca
KOSZT=$(aws ce get-cost-and-usage \
  --time-period Start=2025-07-01,End=2025-07-17 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
  --output text)

echo "Koszt bieżącego miesiąca: \$${KOSZT}"
```

### Czyszczenie środowiska
```bash
#!/bin/bash
# Zatrzymaj wszystkie instancje środowiska dev
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text | xargs aws ec2 stop-instances --instance-ids
```

## 📚 Wskazówki i Najlepsze Praktyki

### Formatowanie wyników
```bash
# Format tabeli (czytelny)
aws ec2 describe-instances --output table

# Format JSON (domyślny, do parsowania)
aws ec2 describe-instances --output json

# Format tekstowy (proste wartości)
aws ec2 describe-instances --output text

# Format YAML
aws ec2 describe-instances --output yaml
```

### Wydajność i limity
```bash
# Zwiększ timeout CLI
aws configure set cli_read_timeout 300

# Zwiększ liczbę prób
aws configure set max_attempts 10

# Paginacja (duże zbiory danych)
aws ec2 describe-instances --max-items 50 --starting-token <token>
```

### Najlepsze praktyki bezpieczeństwa
- Zawsze używaj ról IAM zamiast kluczy dostępu gdy to możliwe
- Włącz CloudTrail do logowania wywołań API
- Stosuj zasadę najmniejszych uprawnień
- Regularnie rotuj klucze dostępu
- Używaj profili AWS CLI zamiast hardkodowanych credentials

### Popularne rozwiązywanie problemów
```bash
# Debugowanie wywołań API
aws ec2 describe-instances --debug

# Walidacja plików JSON
aws iam create-policy --policy-document file://polityka.json --dry-run

# Sprawdź dostępność usługi
aws ec2 describe-availability-zones --region eu-west-1
```

## 💡 Przydatne Aliasy dla .zshrc

```bash
# Skróty AWS CLI
alias awsid='aws sts get-caller-identity'
alias awsregion='aws configure get region'
alias awsprofile='echo $AWS_PROFILE'

# EC2 shortcuts
alias ec2ls='aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,Tags[?Key==\`Name\`].Value|[0],State.Name]" --output table'
alias ec2running='aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --output table'

# S3 shortcuts
alias s3ls='aws s3 ls'
alias s3size='aws s3 ls --recursive --human-readable --summarize'

# Monitoring shortcuts
alias awscost='aws ce get-cost-and-usage --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) --granularity MONTHLY --metrics BlendedCost'
```

---

**Utworzono:** 16 lipca 2025  
**Autor:** Tomasz Królik  
**Wersja:** 1.0  
**Ostatnia aktualizacja:** Dla AWS CLI v2.x  

**Uwaga:** Wszystkie przykłady zostały przetestowane w środowisku eu-west-1. Pamiętaj o dostosowaniu regionów do swoich potrzeb!