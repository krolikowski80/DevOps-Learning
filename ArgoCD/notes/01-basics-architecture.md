# ArgoCD - Notatki z nauki

> **Projekt:** CyberBastion  
> **Data:** 02.12.2025  
> **Status:** Teoria opanowana, czekam na klaster AKS

---

## 1. GitOps - Filozofia

### Problem z tradycyjnym CI/CD (push-based)

```
Git repo ──(push)──> CI Pipeline ──(push)──> Klaster
                          │
                    (tylko gdy commit)
```

**Problemy:**

- Klaster żyje własnym życiem między renderami pipeline'u
- Brak widoczności co naprawdę działa w klastrze
- **Drift** - klaster "odpływa" od deklaracji w Git
- Ktoś robi `kubectl edit` i nikt nie wie

### GitOps - rozwiązanie (pull-based)

> **Git jest JEDYNYM źródłem prawdy o stanie infrastruktury.**

```
         ┌──────────────────────────────────┐
         │          ArgoCD                  │
         │   (działa W klastrze 24/7)       │
         └──────────────────────────────────┘
                    │              │
            (pull co 3 min)    (obserwuje)
                    │              │
                    ▼              ▼
              Git repo ◄────?────► Klaster

         "Czy te dwa stany są identyczne?"
```

### Zasada GitOps

> **Jeśli zmiana nie przeszła przez Git - nie powinna istnieć.**

---

## 2. Architektura ArgoCD

### Trzy komponenty

```
┌─────────────────────────────────────────────────────────────┐
│                    ArgoCD (namespace: argocd)               │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │   API Server    │  │   Repo Server   │  │ Application │  │
│  │                 │  │                 │  │ Controller  │  │
│  │ - UI (webapp)   │  │ - klonuje Git   │  │             │  │
│  │ - REST API      │  │ - renderuje     │  │ - porównuje │  │
│  │ - gRPC API      │  │   manifesty     │  │ - sync'uje  │  │
│  │ - AuthN/AuthZ   │  │ - cache'uje     │  │ - wykrywa   │  │
│  │                 │  │                 │  │   drift     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Role komponentów

| Komponent                  | Rola                                           | Analogia                          |
| -------------------------- | ---------------------------------------------- | --------------------------------- |
| **Repo Server**            | Klonuje repo, renderuje Helm/Kustomize → YAML  | Bibliotekarz z instrukcjami       |
| **Application Controller** | Porównuje Git vs Klaster, sync'uje             | Robot na linii produkcyjnej       |
| **API Server**             | UI, CLI, REST API - do obsługi przez człowieka | Pokój kontrolny ze szklaną ścianą |

### Kluczowa cecha

**Application Controller działa niezależnie!**

Jeśli API Server padnie → sync działa dalej, tylko nie widzisz UI.

### Flow synchronizacji

```
git push
    │
    ▼
┌─────────────────┐
│   Repo Server   │  ← 1. Klonuje/pull'uje repo, renderuje manifesty
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ Application         │  ← 2. Porównuje DESIRED vs ACTUAL
│ Controller          │       Wykrywa różnicę, wykonuje sync
└─────────────────────┘
         │
         ▼
    Klaster K8s        ← 3. Zmiany zaaplikowane
```

**API Server NIE jest w tym flow** - to tylko okno do oglądania.

---

## 3. ArgoCD Application CRD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/user/repo # Skąd brać repo
    path: manifests/ # Katalog z manifestami
    targetRevision: main # Branch/tag do śledzenia
  destination:
    server: https://kubernetes.default.svc # Który klaster
    namespace: my-app # Który namespace
```

### Source vs Destination

- **source** = SKĄD brać manifesty (repo, path, branch)
- **destination** = GDZIE deployować (klaster, namespace)

---

## 4. ArgoCD vs Flux

| Cecha              | ArgoCD              | Flux                |
| ------------------ | ------------------- | ------------------- |
| **UI**             | ✅ Bogaty dashboard | ❌ Brak (CLI only)  |
| **Architektura**   | Scentralizowany     | Rozproszony         |
| **Multi-cluster**  | ✅ Wbudowane        | Wymaga konfiguracji |
| **Krzywa uczenia** | Łatwiejszy start    | Bardziej K8s-native |
| **RBAC**           | Własny system + SSO | K8s RBAC            |

**Dla nauki:** ArgoCD lepszy - UI pokazuje drift, historię, graf zależności.

---

## 5. Instalacja ArgoCD

### Metoda 1: kubectl (najprostsza)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Metoda 2: Helm

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values values-argocd.yaml
```

### Metoda 3: Terraform + Helm (dla CyberBastion)

```hcl
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.51.0"

  depends_on = [azurerm_kubernetes_cluster.aks]

  values = [
    file("${path.module}/values-argocd.yaml")
  ]
}
```

### Terraform dependency chain

```hcl
# 1. Tworzy klaster AKS
resource "azurerm_kubernetes_cluster" "aks" {
  name = "cyberbastion-aks"
  # ...
}

# 2. Provider Helm używa outputów z AKS
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }
}

# 3. ArgoCD czeka na AKS
resource "helm_release" "argocd" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  # ...
}
```

**`depends_on`** wymusza kolejność: AKS musi być GOTOWY zanim Helm zacznie instalować.

---

## 6. Pierwszy login

### Pobranie hasła admina

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

- **User:** `admin`
- **Password:** output komendy wyżej

### ArgoCD CLI

```bash
# Instalacja (macOS)
brew install argocd

# Login
argocd login <ARGOCD_SERVER> --username admin --password <PASSWORD>

# Podstawowe komendy
argocd app list                    # lista aplikacji
argocd app get <APP_NAME>          # szczegóły aplikacji
argocd app sync <APP_NAME>         # wymuś synchronizację
argocd app history <APP_NAME>      # historia deploymentów
```

---

## 7. Dostęp do UI

ArgoCD domyślnie działa jako `ClusterIP` - niedostępny z zewnątrz.

| Metoda                                                      | Kiedy używać            |
| ----------------------------------------------------------- | ----------------------- |
| `kubectl port-forward svc/argocd-server -n argocd 8080:443` | Dev, debugging          |
| **Ingress**                                                 | Produkcja, stały dostęp |
| `LoadBalancer` Service                                      | Chmura (AKS/EKS/GKE)    |
| NodePort                                                    | Bare-metal, on-prem     |

### Przykład Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
spec:
  rules:
    - host: argocd.cyberbastion.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 443
```

---

## 8. Sync modes

| Tryb            | Zachowanie                          |
| --------------- | ----------------------------------- |
| **Manual sync** | Alert o drift, człowiek decyduje    |
| **Auto-sync**   | Automatyczne wymuszanie stanu z Git |

**Rekomendacja:** Zacznij od manual, włącz auto-sync gdy zespół dojrzeje do GitOps.

---

## 9. Checklist na start z AKS

Gdy klaster wstanie:

- [ ] `terraform apply` → AKS + ArgoCD
- [ ] Pobrać hasło: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- [ ] Wystawić UI (Ingress lub LoadBalancer)
- [ ] Zalogować się do UI
- [ ] Zainstalować CLI: `brew install argocd`
- [ ] Stworzyć pierwszą Application

---

## 10. Następne kroki (do nauki)

- [ ] Tworzenie Application przez UI i CLI
- [ ] Application of Applications (App of Apps pattern)
- [ ] ApplicationSet - dynamiczne generowanie aplikacji
- [ ] SSO integration (Azure AD dla CyberBastion?)
- [ ] RBAC w ArgoCD
- [ ] Notifications (Slack, Teams)
- [ ] Image Updater - automatyczne aktualizacje obrazów

---

_Notatki z sesji nauki ArgoCD - Tomasz Królik_  
_Projekt: CyberBastion_
