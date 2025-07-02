# 📌 AWS S3 – Kompletny Poradnik CLI, Polityki, Montowanie

## 📖 Opis
AWS S3 (Simple Storage Service) to skalowalna usługa przechowywania danych w chmurze. Ten poradnik obejmuje:
- Tworzenie i zarządzanie bucketami S3 w **AWS CLI**.
- **Polityki IAM** do kontroli dostępu.
- **Montowanie S3 jako dysk sieciowy** w **Windows i macOS**.

---

## 🔹 1. Tworzenie i zarządzanie bucketami w AWS CLI

### **🔧 Tworzenie bucketa S3**
```bash
aws s3 mb s3://nazwa-twojego-bucketa --region eu-central-1
```
> 📌 Bucket musi mieć unikalną nazwę globalnie.

### **📜 Lista bucketów**
```bash
aws s3 ls
```

### **📂 Wysyłanie plików**
```bash
aws s3 cp lokalny_plik.txt s3://nazwa-twojego-bucketa/
```

### **📥 Pobieranie plików**
```bash
aws s3 cp s3://nazwa-twojego-bucketa/lokalny_plik.txt .
```

### **🗑️ Usunięcie bucketa**
```bash
aws s3 rb s3://nazwa-twojego-bucketa --force
```

---

## 🔹 2. Polityki IAM dla S3

### **📜 Publiczny dostęp do wszystkich obiektów w bucketach** *(Uwaga: każdy ma dostęp!)*
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::nazwa-twojego-bucketa/*"
        }
    ]
}
```
📌 **Zastosowanie:**
- **AWS Console** → **S3** → **Permissions** → **Bucket Policy**.
- Wklej politykę i **zapisz zmiany**.

### **🔒 Prywatny dostęp tylko dla właściciela**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::nazwa-twojego-bucketa/*"
        }
    ]
}
```
📌 **Blokuje dostęp dla wszystkich poza właścicielem.**
#### Przekazanie polityki z pliku JSON
```bash
aws s3api put-bucket-policy \
    --bucket nazwa-twojego-bucketu \
    --policy file://bucket_policy.json
```
#### Sprawdzenie aktualnej polityki
```bash
aws s3api get-bucket-policy \
    --bucket nazwa-twojego-bucketu
```
---

## 🔹 3. Montowanie S3 jako dysk w Windows

### **🛠 Metoda 1: Rclone (zalecana)**
#### **1️⃣ Instalacja Rclone**
```bash
winget install Rclone
```
#### **2️⃣ Konfiguracja dostępu do AWS**
```bash
rclone config
```
- Wybierz `New remote`
- Nazwa np. **myS3**
- Typ: **s3**
- Wpisz **AWS Access Key ID** i **Secret Access Key**
- Region: `eu-central-1`

#### **3️⃣ Montowanie bucketa jako dysk X:**
```bash
rclone mount myS3:nazwa-twojego-bucketa X: --vfs-cache-mode full
```
#### **4️⃣ Automatyczne montowanie po restarcie**
Dodaj do **Task Scheduler**:
```bash
rclone mount myS3:nazwa-twojego-bucketa X: --vfs-cache-mode full
```

---


## 🔹 4. Montowanie S3 jako dysk w macOS

### **🛠 Metoda 1: Rclone (zalecana)**
#### **1️⃣ Instalacja Rclone**
```bash
brew install rclone
```
#### **2️⃣ Konfiguracja dostępu do AWS**
```bash
rclone config
```
#### **3️⃣ Montowanie S3 jako `/Volumes/S3`**
```bash
mkdir -p /Volumes/S3
rclone mount myS3:nazwa-twojego-bucketa /Volumes/S3 --daemon
```
#### **4️⃣ Automatyczne montowanie po restarcie**
Dodaj do `crontab`:
```bash
@reboot /usr/local/bin/rclone mount myS3:nazwa-twojego-bucketa /Volumes/S3 --daemon
```

---
# Automatyczny Multipart Upload w AWS S3

## 1. Wprowadzenie

Amazon S3 umożliwia **wieloczęściowe (multipart) przesyłanie plików** – szczególnie przydatne w przypadku obiektów powyżej 8 MB. Dzięki temu:

- Przesyłanie dużych plików jest **bardziej niezawodne** (błąd na jednej części nie przerywa całej operacji).
- Zwiększa się **przepustowość** dzięki przesyłaniu części równolegle.
- AWS CLI może **automatycznie** uruchomić wieloczęściowy upload bez ręcznej konfiguracji.

## 2. Automatyczny multipart upload w AWS CLI

### a) Domyślne zachowanie

W AWS Command Line Interface (CLI) wystarczy użyć prostego polecenia kopiowania do S3:

```bash
aws s3 cp /ścieżka/do/dużego_pliku s3://nazwa-twojego-bucketu/
```

Jeśli plik przekracza **8 MB**, CLI **automatycznie** dzieli go na mniejsze części, przesyła każdą część i na końcu scala je w jeden obiekt w S3.

### b) Wymuszenie parametrów multipart

Możemy jawnie określić rozmiar części i inne parametry. Przykładowo:

```bash
aws s3 cp /ścieżka/do/dużego_pliku s3://nazwa-twojego-bucketu/ \
  --multipart-chunk-size-mb 64 \
  --expected-size 200MB
```

- `--multipart-chunk-size-mb 64` ustawia rozmiar każdej części na 64 MB.
- `--expected-size` pozwala podać spodziewany rozmiar przesyłanego pliku.

