
# Instalacja i konfiguracja AWS CLI na Mac M1

Aby rozpocząć pracę z AWS przez CLI na Macu M1, musisz zainstalować kilka narzędzi i skonfigurować dostęp do swojego konta AWS. Poniżej znajdziesz szczegółowe instrukcje krok po kroku.

## 1. Instalacja Homebrew

Homebrew to menedżer pakietów dla macOS, który ułatwia instalowanie narzędzi i aplikacji. Jeśli jeszcze nie masz Homebrew, zainstaluj go za pomocą poniższego polecenia:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Po zakończeniu instalacji sprawdź, czy Homebrew działa:

```bash
brew --version
```

## 2. Instalacja AWS CLI

Teraz zainstaluj AWS CLI za pomocą Homebrew:

```bash
brew install awscli
```

Sprawdź, czy AWS CLI zostało poprawnie zainstalowane:

```bash
aws --version
```
Powinna się wyświetlić wersja AWS CLI, np. `aws-cli/2.x.x`.

Zainstaluj `jq`** (jeśli nie masz):  
```sh
brew install jq  # dla macOS
sudo apt install jq  # dla Ubuntu/Debian
sudo yum install jq  # dla CentOS
```

## 3. Tworzenie kluczy dostępu w AWS

Aby korzystać z AWS CLI, musisz utworzyć **AWS Access Key ID** i **AWS Secret Access Key**. Postępuj zgodnie z poniższymi krokami:

### a) Zaloguj się do konsoli AWS
- Przejdź na stronę [AWS Console](https://aws.amazon.com/console/).
- Zaloguj się na swoje konto.

### b) Przejdź do IAM
- W pasku wyszukiwania wpisz "IAM" i kliknij na wynik, aby przejść do usługi **IAM (Identity and Access Management)**.
- Możesz również kliknąć bezpośrednio [tutaj](https://console.aws.amazon.com/iam/).

### c) Utwórz użytkownika IAM
- Kliknij na **Users** (Użytkownicy) w lewym panelu.
- Kliknij **Add user** (Dodaj użytkownika).
- Wprowadź nazwę użytkownika, np. `cli-user`.
- Wybierz **Access type** jako **Programmatic access** (Dostęp programowy).
- Kliknij **Next: Permissions** i przypisz odpowiednie uprawnienia (np. **AdministratorAccess**).
- Kliknij **Next: Tags**, a następnie **Next: Review**.
- Kliknij **Create user**.

### d) Zapisz klucze dostępu
Po utworzeniu użytkownika zostaną wyświetlone klucze:
- **AWS Access Key ID**
- **AWS Secret Access Key**

**WAŻNE**: Zapisz te klucze w bezpiecznym miejscu, ponieważ **Secret Access Key** będzie wyświetlony tylko raz.

## 4. Konfiguracja AWS CLI

Teraz skonfiguruj AWS CLI, aby połączyć się z Twoim kontem AWS. Uruchom poniższe polecenie w terminalu:

```bash
aws configure
```

Podaj następujące informacje:

- **AWS Access Key ID**: Wklej **Access Key ID** utworzone w poprzednim kroku.
- **AWS Secret Access Key**: Wklej **Secret Access Key**.
- **Default region name**: Wprowadź `eu-central-1` (najbliższy region dla Polski).
- **Default output format**: Wprowadź `json` (lub inny format, jeśli preferujesz).

## 5. (Opcjonalnie) Instalacja AWS SAM CLI

Jeśli planujesz pracować z aplikacjami serverless lub AWS Lambda, możesz zainstalować **AWS SAM CLI**. Wykonaj poniższe polecenie:

```bash
brew install aws-sam-cli
```

## 6. (Opcjonalnie) Instalacja AWS Elastic Beanstalk CLI

Jeśli zamierzasz używać AWS Elastic Beanstalk, możesz zainstalować **EB CLI**:

```bash
brew install awsebcli
```

## 7. Testowanie konfiguracji

Aby upewnić się, że konfiguracja została przeprowadzona poprawnie, uruchom polecenie:

```bash
aws s3 ls
```

To polecenie powinno wyświetlić listę Twoich zasobów w S3, jeśli masz dostęp do tej usługi.

---

