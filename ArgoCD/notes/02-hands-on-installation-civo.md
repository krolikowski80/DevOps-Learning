# ArgoCD - Praktyczna instalacja na Civo Kubernetes

> **Projekt:** Test-APP
> **Data:** 04.12.2025
> **Status:** Klaster wdrożony, ArgoCD działa, pierwszy GitOps workflow przetestowany

---

## Cel sesji

Wdrożyć kompletne środowisko ArgoCD na klastrze Kubernetes (Civo Cloud) z GitHub App authentication i przetestować pełny workflow GitOps.

---

## 1. Środowisko

### Infrastruktura

- **Provider:** Civo Cloud
- **Region:** FRA1 (Frankfurt)
- **Cluster:** K3s v1.32.5
- **Nodes:** 2x g4s.kube.small (2GB RAM, 1 vCPU)
- **IaC:** Terraform

### Komponenty wdrożone

```
┌─────────────────────────────────────────┐
│         Civo Kubernetes Cluster         │
│                                         │
│  ┌───────────────┐  ┌────────────────┐  │
│  │  cert-manager │  │    ArgoCD      │  │
│  │   v1.19.1     │  │    v9.1.6      │  │
│  └───────────────┘  └────────────────┘
│
│                                         │
│  Network: 192.168.1.0/24                │
│  Firewall: HTTP/HTTPS/SSH/K8s API       │
└─────────────────────────────────────────┘
```

### Dostępy

- **ArgoCD UI:** https://74.220.29.232
- **Nginx test app:** http://74.220.30.48
- **Kubeconfig:** `~/.kube/config_cyberbastion`
- **Context:** `cyberbastion-test`

---

## 2. Krok po kroku - Instalacja

### 2.1. Przygotowanie środowiska lokalnego

#### Instalacja narzędzi

```bash
# Civo CLI
curl -sL https://civo.com/get | sh
sudo mv /tmp/civo /usr/local/bin/civo

# Civo autocomplete
sudo mkdir -p /usr/local/share/zsh/site-functions
civo completion zsh | sudo tee /usr/local/share/zsh/site-functions/_civo > /dev/null
source ~/.zshrc

# ArgoCD CLI
brew install argocd

# ArgoCD autocomplete
argocd completion zsh | sudo tee /usr/local/share/zsh/site-functions/_argocd > /dev/null
source ~/.zshrc
```

#### Konfiguracja Civo

```bash
# Dodaj API key (z https://dashboard.civo.com)
civo apikey add cyberbastion YOUR_API_KEY
civo apikey current cyberbastion

# Sprawdź dostępne regiony
civo region ls

# Ustaw zmienną środowiskową
export CIVO_TOKEN="YOUR_API_KEY"
```

#### Helm repositories

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

---

### 2.2. Terraform - Struktura projektu

```
Infrastructure/Civo/terraform-live/
├── backend.tf              # Providers (Civo, kubectl, kubernetes, helm)
├── network.tf              # Civo Network
├── firewall.tf             # Firewall rules
├── kubernetes.tf           # K8s cluster + kubeconfig fetch
├── cert-manager.tf         # cert-manager + ClusterIssuer
├── argocd.tf               # ArgoCD Helm release + GitHub App creds
├── var.tf                  # Variables definitions
└── terraform.tfvars        # Values (gitignored!)
```

---

### 2.3. Konfiguracja zmiennych

**Plik: `terraform.tfvars`** (nie commituj!)

```hcl
# Basic configuration
commonName  = "cyberbastion-test"
region      = "FRA1"
homeIp      = "0.0.0.0/0"  # Do produkcji: ustaw konkretne IP!
nodeSize    = "g4s.kube.small"
nodeCount   = 2
networkCidr = "192.168.1.0/24"

# Email for Let's Encrypt
email = "tomasz.krolikowski@vnet.com.pl"

# ArgoCD - without Ingress (LoadBalancer)
argocd_host           = ""
argocd_admin_password = "YOUR_SECURE_PASSWORD"

# Cloudflare - not used but variable required
cloudflare_api_token = "dummy-not-used"

# GitHub App - configured
github_app_url_prefix       = "https://github.com/krolikowski80"
github_app_id               = "2411066"
github_app_installation_id  = "98003868"
github_app_private_key_pem  = <<-EOF
-----BEGIN RSA PRIVATE KEY-----
YOUR_PRIVATE_KEY_HERE
-----END RSA PRIVATE KEY-----
EOF
```

---

### 2.4. GitHub App - Konfiguracja

#### Tworzenie GitHub App

1. https://github.com/settings/apps → **New GitHub App**
2. Wypełnij:
   - **Name:** `argocd-my-first-app-test` (globalnie unikalna)
   - **Homepage URL:** `https://your-argocd-url`
   - **Webhook:** Odznacz "Active" (nie potrzebny)
3. **Repository permissions:**
   - Contents: **Read-only**
   - Metadata: **Read-only** (auto)
4. **Where can install:** Only on this account
5. Kliknij **Create GitHub App**

#### Pobranie credentials

**App ID:** Widoczny na stronie App (np. `2411066`)

**Installation ID:**

1. Install App → wybierz konto/organizację
2. Wybierz repozytoria (np. tylko `argocd-test-app`)
3. Z URL: `https://github.com/settings/installations/98003868` → Installation ID = `98003868`

**Private Key:**

1. Scroll do "Private keys"
2. **Generate a private key**
3. Pobierze się plik `.pem`

#### Alternatywnie - przez CLI

```bash
# Installation ID
gh api /user/installations --jq '.installations[] | select(.app_slug=="argocd-my-first-app-test") | .id'
```

---

### 2.5. Wdrożenie infrastruktury

#### Etap 1: Klaster (bez aplikacji)

```bash
cd Infrastructure/Civo/terraform-live

terraform init

# Plan tylko dla infrastruktury bazowej
terraform plan \
  -target=civo_network.network \
  -target=civo_firewall.firewall \
  -target=civo_kubernetes_cluster.cluster \
  -target=null_resource.fetch_kubeconfig

# Apply
terraform apply \
  -target=civo_network.network \
  -target=civo_firewall.firewall \
  -target=civo_kubernetes_cluster.cluster \
  -target=null_resource.fetch_kubeconfig
```

**Czas:** ~3 minuty

**Co powstało:**

- Network: `cyberbastion-test`
- Firewall: `cyberbastion-test`
- Klaster K8s: 2 nody SMALL
- Kubeconfig: `~/.kube/config_cyberbastion`

#### Sprawdzenie klastra

```bash
kubectl get nodes --kubeconfig ~/.kube/config_cyberbastion

# Merge kubeconfig do głównego pliku
KUBECONFIG=~/.kube/config:~/.kube/config_cyberbastion kubectl config view --flatten > /tmp/merged
cp ~/.kube/config ~/.kube/config.backup_$(date +%Y%m%d)
mv /tmp/merged ~/.kube/config

# Przełącz context
kubectl config use-context cyberbastion-test

# Test
kubectl get nodes
```

#### Etap 2: Aplikacje (cert-manager, ArgoCD)

```bash
# Pełny plan
terraform plan

# Apply wszystkiego
terraform apply
```

**Czas:** ~3-4 minuty

**Co powstało:**

- cert-manager + CRDs
- ClusterIssuer (Let's Encrypt production)
- ArgoCD (Helm chart)
- GitHub App credentials (Kubernetes secret)

---

### 2.6. Weryfikacja ArgoCD

#### Sprawdzenie podów

```bash
kubectl get pods -n argocd
```

**Oczekiwany output (wszystkie Running):**

```
NAME                                                        READY   STATUS
argo-cd-argocd-application-controller-0                     1/1     Running
argo-cd-argocd-applicationset-controller-5fbc4b686d-gwtg5   1/1     Running
argo-cd-argocd-dex-server-64c4c48665-kcg6m                  1/1     Running
argo-cd-argocd-notifications-controller-c77ddf86d-clpcg     1/1     Running
argo-cd-argocd-redis-685f45bccf-rwgx4                       1/1     Running
argo-cd-argocd-repo-server-74d7c65997-xnwpt                 1/1     Running
argo-cd-argocd-server-d5b667f87-zbhst                       1/1     Running
```

#### Pobranie LoadBalancer IP

```bash
kubectl get svc -n argocd argo-cd-argocd-server

# Output:
# NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)
# argo-cd-argocd-server   LoadBalancer   10.43.55.74   74.220.29.232   80:30563/TCP,443:31187/TCP
```

#### Logowanie do UI

1. Otwórz: **https://74.220.29.232**
2. Zaakceptuj self-signed certificate
3. Login:
   - **Username:** `admin`
   - **Password:** `wartość z terraform.tfvars`

---

## 3. Pierwszy deployment - GitOps workflow

### 3.1. Przygotowanie testowego repo

#### Utworzenie repo na GitHub

```bash
cd ~
mkdir argocd-test-app
cd argocd-test-app
git init
gh repo create argocd-test-app --public --source=. --remote=origin
```

**Uwaga:** Dla testów używamy public repo (bez GitHub App). Dla private - credentials są już skonfigurowane w ArgoCD.

#### Struktura katalogów

```
argocd-test-app/
├── README.md
└── k8s/
    ├── deployment.yaml
    └── service.yaml
```

#### Manifesty Kubernetes

**deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "128Mi"
              cpu: "200m"
```

**service.yaml:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-test
  labels:
    app: nginx
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
      name: http
  selector:
    app: nginx
```

#### Push do GitHub

```bash
git add .
git commit -m "Add nginx test deployment for ArgoCD

- Add nginx deployment with 2 replicas
- Add LoadBalancer service
- Configure resource limits"
git push -u origin main
```

**Repo:** https://github.com/krolikowski80/argocd-test-app

---

### 3.2. Dodanie repo do ArgoCD

#### Usunięcie błędnych dummy credentials

```bash
# Terraform utworzył dummy secret - usuń go
kubectl delete secret argocd-github-app-creds -n argocd
```

#### Przez CLI (preferowane)

```bash
# Login
argocd login 74.220.29.232:80 --insecure --username admin --password 'YOUR_PASSWORD' --grpc-web

# Dodaj repo (użyje GitHub App credentials automatycznie)
argocd repo add https://github.com/krolikowski80/argocd-test-app

# Weryfikacja
argocd repo list
```

**Output:**

```
TYPE  NAME  REPO                                              INSECURE  OCI    LFS    CREDS      STATUS      MESSAGE
git         https://github.com/krolikowski80/argocd-test-app  false     false  false  inherited  Successful
```

**CREDS: inherited** = używa GitHub App credentials

---

### 3.3. Utworzenie Application

#### Przez CLI

```bash
argocd app create nginx-test \
  --repo https://github.com/krolikowski80/argocd-test-app \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

#### Sprawdzenie statusu

```bash
argocd app list

# Output:
# NAME               CLUSTER                         NAMESPACE  PROJECT  STATUS     HEALTH   SYNCPOLICY
# argocd/nginx-test  https://kubernetes.default.svc  default    default  OutOfSync  Missing  Manual
```

**STATUS: OutOfSync** = Git ≠ Klaster (nic nie jest wdrożone)
**HEALTH: Missing** = zasoby nie istnieją
**SYNCPOLICY: Manual** = wymaga ręcznej synchronizacji

#### Szczegóły aplikacji

```bash
argocd app get nginx-test
```

**Output pokazuje:**

- Source repo i path
- Wykryte zasoby: `Deployment`, `Service`
- Stan: OutOfSync

---

### 3.4. Synchronizacja (deployment)

```bash
# Synchronizuj
argocd app sync nginx-test

# Czekaj na completion
argocd app wait nginx-test

# Sprawdź status
argocd app get nginx-test
```

**Output sync:**

```
TIMESTAMP                  GROUP        KIND   NAMESPACE      NAME        STATUS    HEALTH
2025-12-04T20:31:35+01:00            Service     default  nginx-test    Synced   Progressing
2025-12-04T20:31:35+01:00   apps  Deployment     default  nginx-test    Synced   Progressing

Operation:          Sync
Sync Revision:      236bbe1aeefb375744e0102efba5e846cd255b99
Phase:              Succeeded
```

#### Weryfikacja w klastrze

```bash
# Pody
kubectl get pods -n default

# Output:
# NAME                          READY   STATUS    RESTARTS   AGE
# nginx-test-6bf6787979-2l7hn   1/1     Running   0          34s
# nginx-test-6bf6787979-4t68j   1/1     Running   0          34s

# Service
kubectl get svc -n default nginx-test

# Output:
# NAME         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)
# nginx-test   LoadBalancer   10.43.4.248   74.220.30.48    80:30422/TCP
```

#### Test w przeglądarce

Otwórz: **http://74.220.30.48**

**Wynik:** Welcome to nginx! ✅

---

### 3.5. GitOps workflow - test zmian

#### Scenariusz: Skalowanie z 2 do 3 replik

**Zmiana w Git:**

```bash
cd ~/local_repo/argocd-test-app

# Edytuj deployment.yaml: replicas: 2 → replicas: 3
sed -i '' 's/replicas: 2/replicas: 3/' k8s/deployment.yaml

# Commit
git add k8s/deployment.yaml
git commit -m "Scale nginx to 3 replicas"
git push
```

**W ArgoCD:**

1. Aplikacja zmienia status na **OutOfSync** (żółta)
2. Kliknij **Sync** w UI (lub przez CLI)
3. ArgoCD wdraża zmianę

```bash
# Przez CLI
argocd app sync nginx-test

# Sprawdź pody
kubectl get pods -n default

# Output: 3 pody Running
```

**Obserwacja:**

- Git = single source of truth
- Zmiana w Git → automatyczna detekcja przez ArgoCD
- Sync → klaster dostosowuje się do Git

---

## 4. Kluczowe problemy i rozwiązania

### Problem 1: Za małe nody (g4s.kube.xsmall)

**Symptom:**

```
NAME                                   READY   STATUS
argo-cd-argocd-server-d5b667f87-xxx    0/1     Evicted
argo-cd-argocd-dex-server-xxx          0/1     Evicted
```

Masowe **Evicted** pody - brak pamięci.

**Rozwiązanie:**

Civo nie pozwala na resize nodów w istniejącym klastrze. Trzeba:

```bash
# Destroy
terraform destroy -auto-approve

# Edytuj terraform.tfvars: nodeSize = "g4s.kube.small"

# Recreate
terraform apply -auto-approve
```

**Wniosek:** Dla ArgoCD minimum **g4s.kube.small** (2GB RAM).

---

### Problem 2: Timeout przy tworzeniu secretów

**Symptom:**

```
Error: Post "https://74.220.25.7:6443/api/v1/namespaces/argocd/secrets":
dial tcp 74.220.25.7:6443: i/o timeout
```

**Przyczyna:** Stary kubeconfig ze starym IP po recreate klastra.

**Rozwiązanie:**

```bash
# Kubeconfig aktualizuje się automatycznie przez Terraform provisioner
# Ale merged config w ~/.kube/config może być stary

# Sprawdź context
kubectl config current-context

# Sprawdź nody (powinny być nowe)
kubectl get nodes

# Jeśli błąd - pobierz nowy kubeconfig
civo kubernetes config cyberbastion-test --region FRA1 > ~/.kube/config_cyberbastion_new
mv ~/.kube/config_cyberbastion_new ~/.kube/config_cyberbastion

# Zmerge ponownie
KUBECONFIG=~/.kube/config.backup:~/.kube/config_cyberbastion kubectl config view --flatten > /tmp/merged
mv /tmp/merged ~/.kube/config
```

---

### Problem 3: ArgoCD CLI - connection refused

**Symptom:**

```
{"level":"fatal","msg":"gRPC connection not ready: context deadline exceeded"}
```

**Rozwiązanie:**

Użyj `--grpc-web` dla LoadBalancer bez TLS:

```bash
argocd login 74.220.29.232:80 --insecure --username admin --password 'PASS' --grpc-web
```

Alternatywnie - port-forward:

```bash
kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:80 &
argocd login localhost:8080 --insecure --username admin --password 'PASS' --plaintext
```

---

### Problem 4: CORS error przy dodawaniu repo w UI

**Symptom:**

```
Request has been terminated
Possible causes: Origin is not allowed by Access-Control-Allow-Origin
```

**Rozwiązanie:**

Dodaj repo przez CLI zamiast UI:

```bash
argocd repo add https://github.com/krolikowski80/argocd-test-app
```

---

### Problem 5: Dummy GitHub App credentials

**Symptom:**

```
unable to get repository credentials:
strconv.ParseInt: parsing "dummy": invalid syntax
```

**Przyczyna:** Terraform utworzył secret z dummy wartościami.

**Rozwiązanie:**

```bash
# Usuń błędny secret
kubectl delete secret argocd-github-app-creds -n argocd

# ArgoCD użyje prawidłowego secret utworzonego przez Terraform
# (po fix w terraform.tfvars i terraform apply)
```

---

## 5. Architektura końcowa

```
┌────────────────────────────────────────────────────────────────┐
│                      Civo Cloud (FRA1)                         │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           cyberbastion-test (K3s v1.32.5)                │  │
│  │                                                          │  │
│  │  Namespace: cert-manager                                 │  │
│  │  ├── cert-manager pods (3)                               │  │
│  │  ├── ClusterIssuer: letsencrypt-production               │  │
│  │  └── Secret: cloudflare-api-token-secret                 │  │
│  │                                                          │  │
│  │  Namespace: argocd                                       │  │
│  │  ├── argo-cd-argocd-server (LB: 74.220.29.232)           │  │
│  │  ├── argo-cd-argocd-application-controller               │  │
│  │  ├── argo-cd-argocd-repo-server                          │  │
│  │  ├── argo-cd-argocd-dex-server                           │  │
│  │  ├── argo-cd-argocd-redis                                │  │
│  │  ├── argo-cd-argocd-applicationset-controller            │  │
│  │  ├── argo-cd-argocd-notifications-controller             │  │
│  │  └── Secret: argocd-github-app-creds                     │  │
│  │      ├── githubAppID: 2411066                            │  │
│  │      ├── githubAppInstallationID: 98003868               │  │
│  │      └── githubAppPrivateKey: <PEM>                      │  │
│  │                                                          │  │
│  │  Namespace: default                                      │  │
│  │  └── Application: nginx-test                             │  │
│  │      ├── Deployment: nginx-test (3 replicas)             │  │
│  │      └── Service: nginx-test (LB: 74.220.30.48)          │  │
│  │                                                          │  │
│  │  Nodes:                                                  │  │
│  │  ├── k3s-cyberbastion-test-...-rgaan (2GB, 1vCPU, Ready) │  │
│  │  └── k3s-cyberbastion-test-...-td9vp (2GB, 1vCPU, Ready) │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                │
│  Network: 192.168.1.0/24                                       │
│  Firewall: cyberbastion-test                                   │
│  ├── HTTP (80): 0.0.0.0/0 → allow                              │
│  ├── HTTPS (443): 0.0.0.0/0 → allow                            │
│  ├── SSH (22): 0.0.0.0/0 → allow                               │
│  └── K8s API (6443): 0.0.0.0/0 → allow                         │
└────────────────────────────────────────────────────────────────┘
         ▲                           ▲
         │                           │
    (pulls repo)              (manages apps)
         │                           │
         │                           │
┌────────┴──────────┐       ┌────────┴──────────┐
│  GitHub           │       │  kubectl/argocd   │
│  ├── ArgoCD App   │       │  CLI              │
│  │   (private)    │       │  (local machine)  │
│  └── argocd-test- │       └───────────────────┘
│      app (public) │
│      └── k8s/     │
│          ├── deployment.yaml
│          └── service.yaml
└───────────────────┘
```

---

## 6. Komendy Quick Reference

### Terraform

```bash
# Init
terraform init

# Plan
terraform plan

# Apply wszystkiego
terraform apply -auto-approve

# Apply specific resources
terraform apply -target=civo_kubernetes_cluster.cluster

# Destroy
terraform destroy -auto-approve

# State
terraform state list
terraform show
```

### Kubernetes

```bash
# Context
kubectl config get-contexts
kubectl config use-context cyberbastion-test
kubectl config current-context

# Resources
kubectl get nodes
kubectl get pods -n argocd
kubectl get svc -n argocd
kubectl get all -n default

# Logs
kubectl logs -n argocd deployment/argo-cd-argocd-server
kubectl logs -n default deployment/nginx-test

# Describe
kubectl describe pod -n argocd <pod-name>
kubectl describe svc -n default nginx-test

# Delete
kubectl delete pod -n argocd <pod-name>
kubectl delete secret -n argocd argocd-github-app-creds
```

### ArgoCD CLI - Complete Handbook

#### Authentication & Context

```bash
# Login (LoadBalancer HTTP)
argocd login 74.220.29.232:80 --insecure --username admin --password 'PASS' --grpc-web

# Login (LoadBalancer HTTPS)
argocd login 74.220.29.232 --insecure --username admin --password 'PASS'

# Login (port-forward)
kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:80 &
argocd login localhost:8080 --insecure --username admin --password 'PASS' --plaintext

# Logout
argocd logout 74.220.29.232

# Account info
argocd account get-user-info

# Change password
argocd account update-password
```

#### Repositories

```bash
# List repositories
argocd repo list

# Add repository (public)
argocd repo add https://github.com/user/repo

# Add repository (private - SSH)
argocd repo add git@github.com:user/repo.git --ssh-private-key-path ~/.ssh/id_rsa

# Add repository (private - HTTPS with token)
argocd repo add https://github.com/user/repo --username USERNAME --password TOKEN

# Add repository (uses inherited GitHub App creds)
argocd repo add https://github.com/krolikowski80/argocd-test-app

# Get repository details
argocd repo get https://github.com/user/repo

# Remove repository
argocd repo rm https://github.com/user/repo
```

#### Applications - Lifecycle

```bash
# List all applications
argocd app list

# List applications with output format
argocd app list -o wide
argocd app list -o yaml

# Get application details
argocd app get nginx-test

# Get application details (YAML)
argocd app get nginx-test -o yaml

# Create application
argocd app create nginx-test \
  --repo https://github.com/krolikowski80/argocd-test-app \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Create with Helm
argocd app create my-app \
  --repo https://github.com/user/helm-repo \
  --path charts/my-chart \
  --helm-set replicas=3 \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production

# Create with Kustomize
argocd app create my-app \
  --repo https://github.com/user/kustomize-repo \
  --path overlays/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production

# Delete application (keep resources in cluster)
argocd app delete nginx-test

# Delete application (remove resources from cluster)
argocd app delete nginx-test --cascade
```

#### Applications - Sync & State

```bash
# Sync application (manual)
argocd app sync nginx-test

# Sync and wait
argocd app sync nginx-test --async=false

# Sync specific resource
argocd app sync nginx-test --resource apps:Deployment:nginx-test

# Sync with prune (delete resources not in Git)
argocd app sync nginx-test --prune

# Force sync (ignore sync windows)
argocd app sync nginx-test --force

# Wait for application to be synced
argocd app wait nginx-test

# Wait with timeout
argocd app wait nginx-test --timeout 300

# Rollback to previous sync
argocd app rollback nginx-test

# Rollback to specific revision
argocd app rollback nginx-test 2

# Get application history
argocd app history nginx-test

# Diff (compare Git vs Cluster)
argocd app diff nginx-test

# Diff local manifests
argocd app diff nginx-test --local /path/to/manifests
```

#### Applications - Configuration

```bash
# Set sync policy to auto
argocd app set nginx-test --sync-policy automated

# Set sync policy to manual
argocd app set nginx-test --sync-policy none

# Enable auto-sync with prune and self-heal
argocd app set nginx-test \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Set sync window
argocd app set nginx-test --sync-option CreateNamespace=true

# Set revision/branch
argocd app set nginx-test --revision main

# Set path
argocd app set nginx-test --path k8s/production

# Set Helm parameters
argocd app set nginx-test --helm-set replicas=5

# Set resource tracking method
argocd app set nginx-test --tracking-method annotation
```

#### Applications - Resources

```bash
# List resources of application
argocd app resources nginx-test

# Get specific resource
argocd app manifests nginx-test

# Get resource tree
argocd app tree nginx-test

# Terminate running operation
argocd app terminate-op nginx-test
```

#### Applications - Troubleshooting

```bash
# Get logs from application pods
argocd app logs nginx-test

# Get logs from specific pod
argocd app logs nginx-test --pod nginx-test-6bf6787979-2l7hn

# Follow logs
argocd app logs nginx-test --follow

# Get events
argocd app get nginx-test --show-operation

# Refresh application (force Git pull)
argocd app get nginx-test --refresh

# Hard refresh (ignore cache)
argocd app get nginx-test --hard-refresh
```

#### Projects

```bash
# List projects
argocd proj list

# Get project details
argocd proj get default

# Create project
argocd proj create my-project \
  --description "My project" \
  --dest https://kubernetes.default.svc,default \
  --src https://github.com/user/*

# Add destination
argocd proj add-destination my-project \
  https://kubernetes.default.svc \
  production

# Add source repository
argocd proj add-source my-project https://github.com/user/repo

# Delete project
argocd proj delete my-project
```

#### Clusters

```bash
# List clusters
argocd cluster list

# Add cluster (from kubeconfig)
argocd cluster add my-cluster-context

# Remove cluster
argocd cluster rm https://my-cluster-api

# Get cluster info
argocd cluster get https://kubernetes.default.svc
```

#### Settings & Admin

```bash
# Get ArgoCD settings
argocd admin settings

# Export applications
argocd admin export > backup.yaml

# Import applications
argocd admin import - < backup.yaml

# Generate manifests
argocd admin app generate-spec nginx-test

# Validate project
argocd proj get default --validate
```

#### Version & Help

```bash
# Version
argocd version

# Help
argocd --help
argocd app --help
argocd app create --help
```

### Civo CLI

```bash
# Kubernetes
civo kubernetes ls
civo kubernetes show cyberbastion-test
civo kubernetes config cyberbastion-test --region FRA1

# Firewall
civo firewall ls
civo firewall show <firewall-id>

# Network
civo network ls
```

### Git workflow

```bash
# Zmiana w repo
cd ~/local_repo/argocd-test-app
# ... edytuj pliki ...
git add .
git commit -m "Description"
git push

# ArgoCD wykryje zmianę (polling co 3 min)
# Sync ręcznie lub auto (jeśli skonfigurowane)
argocd app sync nginx-test
```

---

## 7. Wnioski i best practices

### ✅ Co zadziałało dobrze

1. **Terraform dla IaC** - pełna powtarzalność wdrożenia
2. **GitHub App authentication** - bezpieczny dostęp do private repos
3. **LoadBalancer exposure** - szybki dostęp bez Ingress (test)
4. **CLI-first approach** - omija problemy z CORS w UI
5. **Merged kubeconfig** - łatwe przełączanie między klastrami

### ⚠️ Do poprawy w produkcji

1. **Firewall:** `0.0.0.0/0` → konkretne IP/zakresy
2. **ArgoCD Ingress:** LoadBalancer → Ingress + TLS (cert-manager)
3. **Auto-sync:** Manual → Automated (z pruning i self-healing)
4. **Monitoring:** Brak - dodać Prometheus/Grafana
5. **Backup:** State tylko lokalny - użyć S3 backend
6. **Secrets:** terraform.tfvars lokalnie - przenieść do Vault/SOPS
7. **Node size:** Startować od **medium** dla stabilności

### 🎯 Następne kroki

1. **App of Apps pattern** - ArgoCD zarządza swoimi Applications
2. **Helm charts** - zamiast raw YAML
3. **Kustomize** - overlays dla różnych środowisk (dev/stage/prod)
4. **Multi-cluster** - jeden ArgoCD → wiele klastrów
5. **RBAC** - role dla zespołów
6. **Notifications** - Slack/email przy zmianach
7. **Image updater** - auto-update image tags
8. **ApplicationSet** - generowanie Applications z templat

---

## 8. Koszty

**Civo kredyt:** $250 (initial)

**Zużycie sesji (~2h testów):**

- 2x g4s.kube.small: ~$0.03/h × 2 = $0.06/h
- LoadBalancers: 2 × $0.01/h = $0.02/h
- **Total:** ~$0.08/h = **~$0.16 za sesję**

**Pozostało:** $249.84

---

## 9. Linki

### Dokumentacja

- ArgoCD: https://argo-cd.readthedocs.io
- Civo: https://www.civo.com/docs
- Terraform Civo Provider: https://registry.terraform.io/providers/civo/civo/latest/docs

### Repozytoria

- IaC: `CyberBastion/Infrastructure/Civo/terraform-live`
- Test app: https://github.com/krolikowski80/argocd-test-app

### Dashboardy

- Civo: https://dashboard.civo.com
- ArgoCD: https://74.220.29.232
- GitHub App: https://github.com/settings/apps/argocd-my-first-app-test

---
