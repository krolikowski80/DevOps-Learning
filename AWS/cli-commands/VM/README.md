# Tworzenie Instancji Windows Server / Amazon Linux na AWS przez CLI z użyciem .env

## 📌 1. Tworzenie i sprawdzenie Key Pair (klucza dostępowego)

🔹 **Sprawdzę, czy mam już Key Pair**  
```sh
aws ec2 describe-key-pairs \
--query 'KeyPairs[*].KeyName' \
--output table
```

🔹 **Tworzenie nowego Key Pair**  
```sh
aws ec2 create-key-pair \
--key-name MyTestKey \
--query 'KeyMaterial' \
--output text > MyTestKey.pem
```
🔹 **Ustawienie poprawnych uprawnień do pliku:**

**To ważne**, poniewarz z innymi uprawnieniami klucz nie zostanie zaakceptowany. 

```sh
chmod 400 MyTestKey.pem
```

**WAŻNE:** AWS przechowuje **tylko publiczną część klucza**, więc **zachowaj plik `.pem`**, bo nie będzie można go pobrać ponownie!

---

## 📌 2. Tworzenie pliku `.env` dla zmiennych

Aby zapisać zmienne do późniejszego użycia, utworzę plik `.env`:

```sh
touch .env
```

Dodaj do niego następujące wartości:

```sh
echo 'AWS_REGION=eu-central-1' >> .env
echo 'KEY_NAME=MyTestKey' >> .env
```

Załaduj zmienne do środowiska:

```sh
export $(grep -v '^#' .env | xargs)
```

---

## 📌 3. Pobranie ID najnowszego obrazu AMI i zapisanie do `.env`

🔹 **Windows Server**

- Do wyszukania AMI działającego na t2.micro, trzeba dostosować zapytanie, dodając filtr : 
    - dla Name=root-device-type ustawiony na ebs
    - dla Name=virtualization-type ustawiony na hvm, co jest wymagane dla instancji t2.micro.
    - Dodatkowo, można dodać filtr dla architektury x86_64, ponieważ t2.micro nie obsługuje ARM.!!
- Wyniki przechowywane są w zmiennych - do wykożystania w późniejszych etapach.   
```sh
WINDOWS_AMI_ID=$(aws ec2 describe-images \
--owners amazon \
--filters "Name=name,Values=Windows_Server*" \
          "Name=state,Values=available" \
          "Name=root-device-type,Values=ebs" \
          "Name=virtualization-type,Values=hvm" \
          "Name=architecture,Values=x86_64" \
--query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
--output text)
echo "WINDOWS_AMI_ID=$WINDOWS_AMI_ID" >> .env
```

🔹 **Amazon Linux 2**

- amzn2-ami-hvm-*-x86_64-gp2 – Filtruje obrazy Amazon Linux 2 (amzn2-ami-hvm), które używają wirtualizacji HVM i systemu plików GP2 (EBS).
- Name=state,Values=available – Upewnia się, że obraz jest dostępny do użycia.
- sort_by(@, &CreationDate) | [-1].ImageId – Sortuje obrazy według daty utworzenia i wybiera najnowszy ([-1]).
- t2.micro obsługuje obrazy HVM, x86_64 i EBS-backed, więc ten AMI jest zgodny.  
```sh
AMAZON_LINUX_AMI_ID=$(aws ec2 describe-images \
--owners amazon \
--filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
          "Name=state,Values=available" \
--query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
--output text)
echo "AMAZON_LINUX_AMI_ID=$AMAZON_LINUX_AMI_ID" >> .env
```

Załaduję `.env` ponownie:
```sh
export $(grep -v '^#' .env | xargs)
```

---

## 📌 4. Tworzenie Security Groups  

🔹 **Security Group dla RDP (Windows Server)**  
```sh
SEC_GROUP_RDP_ID=$(aws ec2 create-security-group \
--group-name "connection-to-server-security-group" \
--description "Security group for RDP access" \
--query 'GroupId' \
--output text)
echo "SEC_GROUP_RDP_ID=$SEC_GROUP_RDP_ID" >> .env

aws ec2 authorize-security-group-ingress \
--group-id $SSEC_GROUP_RDP_ID \
--protocol tcp \
--port 3389 \
--cidr 0.0.0.0/0
```

🔹 **Security Group dla SSH (Linux Server)**
```sh
SEC_GROUP_SSH_ID=$(aws ec2 create-security-group \
--group-name "ssh-server-security-group" \
--description "Security group for SSH access" \
--query 'GroupId' \
--output text)
echo "SEC_GROUP_SSH_ID=$SEC_GROUP_SSH_ID" >> .env

aws ec2 authorize-security-group-ingress \
--group-id $SEC_GROUP_SSH_ID \
--protocol tcp \
--port 22 \
--cidr 0.0.0.0/0
```

🔹 **Security Group dla HTTP/HTTPS (Web Server)**  
```sh
SEC_GROUP_WEB_ID=$(aws ec2 create-security-group \
--group-name "web-server-security-group" \
--description "Security group for HTTP/HTTPS" \
--query 'GroupId' \
--output text)
echo "SEC_GROUP_WEB_ID=$SEC_GROUP_WEB_ID" >> .env

aws ec2 authorize-security-group-ingress \
--group-id $SEC_GROUP_WEB_ID \
--protocol tcp \
--port 80 \
--cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
--group-id $SEC_GROUP_WEB_ID \
--protocol tcp \
--port 443 \
--cidr 0.0.0.0/0
```

Załaduję `.env` ponownie - tak profilaktycznie ;):
```sh
export $(grep -v '^#' .env | xargs)
```

---

## 📌 5. Tworzenie instancji EC2  

#### Skrypty startowe dla Windows są zapisane na dysku pod nazwą user-data.ps1. Oczywiście sam ich nie napisałem. 
- Poza tym NIE DZIAŁA ZGODNIE Z OCZEKIWANIEM
```sh
<powershell>
# Ścieżka do pliku, który będzie informował, że User Data zostało wykonane pierwszy raz
$FirstRunFlag = "C:\FirstRunComplete.txt"

if (!(Test-Path $FirstRunFlag)) {
    # Pierwsze uruchomienie serwera - wykona się tylko raz
    Write-Output "Tworzy się nowy serwer" | Out-File -FilePath C:\startup-log.txt -Append
    New-Item -Path $FirstRunFlag -ItemType File -Force
}

# To wykona się przy każdym starcie serwera
Write-Output "Serwer startuje" | Out-File -FilePath C:\startup-log.txt -Append
</powershell>
```


🔹 **Tworzenie instancji Windows Server z Key Pair i User Data**  
```sh
INSTANCE_ID_WINDOWS=$(aws ec2 run-instances \
--image-id $WINDOWS_AMI_ID \
--instance-type t2.micro \
--security-group-ids $SEC_GROUP_RDP_ID $SEC_GROUP_WEB_ID \
--key-name $KEY_NAME \
--user-data file://user-data.ps1 \
--query 'Instances[0].InstanceId' \
--output text)
echo "INSTANCE_ID_WINDOWS=$INSTANCE_ID_WINDOWS" >> .env
```

🔹 **Tworzenie instancji Amazon Linux z Key Pair**  
```sh
INSTANCE_ID_LINUX=$(aws ec2 run-instances \
--image-id $AMAZON_LINUX_AMI_ID \
--instance-type t2.micro \
--security-group-ids $SEC_GROUP_RDP_ID $SEC_GROUP_WEB_ID \
--key-name $KEY_NAME \
--query 'Instances[0].InstanceId' \
--output text)
echo "INSTANCE_ID_LINUX=$INSTANCE_ID_LINUX" >> .env
```

---

## 📌 6. Oczekiwanie na uruchomienie instancji Windows Server  
```sh
aws ec2 wait instance-status-ok \
--instance-ids $INSTANCE_ID_WINDOWS
echo "Instancja Windows Server jest gotowa!"
```

---

## 📌 7. Pobranie hasła Administratora Windows Server  

🔹 **Odszyfrowanie hasła Administratora**  
```sh
DECRYPTED_PASSWORD=$(aws ec2 get-password-data \
--instance-id $INSTANCE_ID_WINDOWS \
--priv-launch-key /Users/tomasz/$KEY_NAME.pem \
--query 'PasswordData' \
--output text)
echo "DECRYPTED_PASSWORD=$DECRYPTED_PASSWORD" >> .env
```

---

## 📌 8. Pobranie Publicznego IP instancji  
🔹 **Windows Server**  
```sh
PUBLIC_IP_WINDOWS=$(aws ec2 describe-instances \
--instance-ids $INSTANCE_ID_WINDOWS \
--query 'Reservations[0].Instances[0].PublicIpAddress' \
--output text)
echo "PUBLIC_IP_WINDOWS=$PUBLIC_IP_WINDOWS" >> .env
```

🔹 **Amazon Linux**  
```sh
PUBLIC_IP_LINUX=$(aws ec2 describe-instances \
--instance-ids $INSTANCE_ID_LINUX \
--query 'Reservations[0].Instances[0].PublicIpAddress' \
--output text)
echo "PUBLIC_IP_LINUX=$PUBLIC_IP_LINUX" >> .env
```

🔹 **Logowanie via SSH do Linux Server**
```sh
ssh -i /Users/tomasz/$KEY_NAME.pem ec2-user@$PUBLIC_IP_LINUX
```

- i oopssss - podpiąłem Linux Server do nieodpowiedniej security group, więc szybka anaprawa.

- jakie mam sec_grupy?
```sh
aws ec2 describe-instances \
--instance-ids $INSTANCE_ID_LINUX \
--query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' \
--output table
```

- szybka podmianka
```sh
aws ec2 modify-instance-attribute \
--instance-id $INSTANCE_ID_LINUX \
--groups $SEC_GROUP_SSH_ID $SEC_GROUP_WEB_ID
```
<br>

---
---
<br>

# 🧹 Usuwanie zasobów po labie

🔹 Załaduję `.env` ponownie - tak profilaktycznie ;):
```sh
export $(grep -v '^#' .env | xargs)
```

## 📌 1. Usunięcie instancji EC2 (VM)
🔹 Jakie w ogóe są aktywne instancje:

```sh
aws ec2 describe-instances \
--query 'Reservations[*].Instances[*].[InstanceId, State.Name]' \
--output table
```

🔹 Zabijamy konkretne instancje:

```sh
aws ec2 terminate-instances \
--instance-ids $INSTANCE_ID_LINUX $INSTANCE_ID_WINDOWS
```

🔹🔹 Bardziej hard core - Eliminate them all, without a shred of regret. 😁

➡️  Ze wszytskim tak można zrobić
- pobrać listę rzeczy
– wyciągnąć tylko identyfikatory
- zwrócić jako tekst
- przekazać wyniki do xargs
    - xargs -n1 – przekazuje każdy identyfikator osobno jako argument do następnego polecenia.
- i do pieca z nimi


```sh
aws ec2 describe-instances \
--query 'Reservations[*].Instances[*].InstanceId' \
--output text | xargs aws ec2 terminate-instances \
--instance-ids \
```

🔹 Sprawdzamy czy instancje są **terminated**:

```sh
aws ec2 describe-instances \
--query 'Reservations[*].Instances[*].[InstanceId, State.Name]' \
--output table
```
👍🏻 Wynik 
```
---------------------------------------
|          DescribeInstances          |
+----------------------+--------------+
|  i-0434a6af0546544b9 |  terminated  |
|  i-01b1d80474df9c810 |  terminated  |
+----------------------+--------------+
```
---

## 📌 2. Usunięcie Security Groups
🔹 Security Groups nie mogą być usunięte, jeśli są nadal przypisane do instancji. Więc czekam cierpliwie aż wszystkie instancje zostaną usunięte.

🔹 → I do pieca z nimi...

```sh
aws ec2 delete-security-group --group-id $SEC_GROUP_SSH_ID
aws ec2 delete-security-group --group-id $SEC_GROUP_WEB_ID
aws ec2 delete-security-group --group-id $SEC_GROUP_RDP_ID
```

🔹 → Oczywiście oprócz domyślnych 😁

---

## 📌 3. Usunięcie kluczy SSH
🔹 Jakie mam klucze:

```sh
aws ec2 describe-key-pairs \
--query 'KeyPairs[*].KeyName' \
--output table
```

🔹 Usuwam  klucz:

```sh
aws ec2 delete-key-pair \
--key-name $KEY_NAME
```

🔹 Usunę także lokalny plik `.pem`, nie jest już potrzebny:

```sh
rm -f /Users/tomasz/MyTestKey.pem
```

---

## 📌 4. Usunięcie woluminów EBS (opcjonalnie)
🔹 Jakie dyski mam w użyciu?
```sh
aws ec2 describe-volumes \
--query 'Volumes[*].[VolumeId, State]' \
--output table
```

🔹 Ni eposiadamadnych dysków
- Lecz jeżeli jest inaczej to - usuwam **odłączone (`available`)** woluminy:

```sh
aws ec2 describe-volumes \
--query 'Volumes[?State==`available`].VolumeId' \
--output text | xargs -n1 aws ec2 delete-volume \
--volume-id
```

---

## 📌 5. Usunięcie Elastic IP (opcjonalnie)
🔹 Jakie są przypisane **Elastic IP**:

```sh
aws ec2 describe-addresses \
--query 'Addresses[*].[PublicIp, AllocationId]' \
--output table
```

🔹 BRAK, ale jak są do do pieca z nimi:

```sh
aws ec2 describe-addresses \
--query 'Addresses[*].AllocationId' \
--output text | xargs -n1 aws ec2 release-address \
--allocation-id
```

---

## 📌 6. Sprawdzenie, czy wszystko zostało usunięte
🔹 Czy na pewno nic nie zostało:

- **Instancje EC2**
  ```sh
  aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text
  ```
  Jeśli wynik jest pusty → **wszystkie VM usunięte**.

- **Security Groups**
  ```sh
  aws ec2 describe-security-groups \
  --query 'SecurityGroups[*].GroupId' \
  --output text
  ```
  Jeśli została tylko domylna → **wszystkie Security Groups usunięte**.

- **Klucze SSH**
  ```sh
  aws ec2 describe-key-pairs \
  --query 'KeyPairs[*].KeyName' \
  --output text
  ```
  Jeśli brak wyników → **klucze usunięte**.

- **Woluminy EBS**
  ```sh
  aws ec2 describe-volumes \
  --query 'Volumes[*].VolumeId' \
  --output text
  ```
  Jeśli brak wyników → **woluminy usunięte**.
- **Elastic IP**
  ```sh
  aws ec2 describe-addresses \
  --query 'Addresses[*].PublicIp' \
  --output text
  ```
  Jeśli brak wyników → **Elastic IP usunięte**.


---
# THE END 🫡