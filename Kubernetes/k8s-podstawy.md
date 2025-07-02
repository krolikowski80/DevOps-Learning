# Kubernetes - Podstawy i Architektura

## 🏗️ Architektura Klastra Kubernetes

### Węzły Sterujące (Control Plane)
```
┌─────────────────────────────────────┐
│           WĘZEŁ STERUJĄCY           │
├─────────────────────────────────────┤
│ • kube-apiserver                    │  ← Główny punkt API
│ • etcd                              │  ← Baza danych klastra
│ • kube-scheduler                    │  ← Przydziela pody do węzłów
│ • kube-controller-manager           │  ← Zarządza kontrolerami
│ • cloud-controller-manager          │  ← Integracja z chmurą
└─────────────────────────────────────┘
```

### Węzły Robocze (Worker Nodes)
```
┌─────────────────────────────────────┐
│            WĘZEŁ ROBOCZY            │
├─────────────────────────────────────┤
│ • kubelet                           │  ← Agent zarządzający podami
│ • kube-proxy                        │  ← Proxy sieciowe
│ • container runtime                 │  ← Docker/containerd/CRI-O
│                                     │
│ ┌─────────────────────────────────┐ │
│ │           PODY                  │ │  ← Kontenery aplikacji
│ │  ┌─────┐ ┌─────┐ ┌─────┐       │ │
│ │  │ APP │ │ APP │ │ APP │       │ │
│ │  └─────┘ └─────┘ └─────┘       │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## 📦 Podstawowe Obiekty Kubernetes

### Pod - Najmniejsza Jednostka
```yaml
# Pod to grupa jednego lub więcej kontenerów
# Kontenery w podzie dzielą:
# - Ten sam adres IP
# - Ten sam system plików (volumes)
# - Ten sam cykl życia

apiVersion: v1
kind: Pod                           # Typ obiektu - Pod
metadata:
  name: moja-aplikacja             # Nazwa poda (unikalna w namespace)
  namespace: produkcja             # Namespace gdzie pod istnieje
  labels:                          # Etykiety do identyfikacji
    app: frontend                  # Nazwa aplikacji
    wersja: v1                     # Wersja aplikacji
    srodowisko: produkcja          # Środowisko (dev/test/prod)
spec:                              # Specyfikacja poda
  containers:                      # Lista kontenerów w podzie
  - name: aplikacja-web            # Nazwa kontenera
    image: nginx:1.25-alpine       # Obraz kontenera (repozytorium:tag)
    ports:                         # Porty które kontener udostępnia
    - containerPort: 80            # Port wewnętrzny kontenera
      name: http                   # Nazwa portu (opcjonalna)
      protocol: TCP                # Protokół (TCP/UDP)
```

### Deployment - Zarządzanie Podami
```yaml
# Deployment zarządza grupą identycznych podów
# Zapewnia:
# - Określoną liczbę replik
# - Aktualizacje bez przestojów
# - Automatyczne odtwarzanie awarii

apiVersion: apps/v1
kind: Deployment                   # Typ obiektu - Deployment
metadata:
  name: aplikacja-frontend         # Nazwa deploymentu
  namespace: produkcja
  labels:
    app: frontend
spec:
  replicas: 3                      # Liczba identycznych podów
  selector:                        # Jak znaleźć pody do zarządzania
    matchLabels:
      app: frontend                # Musi pasować do template.labels
  template:                        # Szablon dla tworzonych podów
    metadata:
      labels:
        app: frontend              # Etykiety dla tworzonych podów
    spec:
      containers:                  # Specyfikacja kontenerów
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
```

### Service - Udostępnianie Aplikacji
```yaml
# Service zapewnia stały punkt dostępu do podów
# Rozdziela ruch między dostępne pody
# Zapewnia load balancing i service discovery

apiVersion: v1
kind: Service                      # Typ obiektu - Service
metadata:
  name: frontend-service           # Nazwa serwisu (DNS name)
  namespace: produkcja
spec:
  type: ClusterIP                  # Typ serwisu (ClusterIP/NodePort/LoadBalancer)
  selector:                        # Które pody obsługuje ten serwis
    app: frontend                  # Pasuje do etykiet podów
  ports:                           # Mapowanie portów
  - name: http                     # Nazwa portu
    port: 80                       # Port serwisu (na który łączą się klienci)
    targetPort: 80                 # Port kontenera (gdzie aplikacja słucha)
    protocol: TCP
```

## 🏷️ System Etykiet (Labels) i Selektorów

### Etykiety - Organizacja Obiektów
```yaml
# Etykiety to pary klucz-wartość przypisane do obiektów
# Używane do:
# - Organizacji zasobów
# - Selekcji obiektów
# - Routingu ruchu

metadata:
  labels:
    # Standardowe etykiety
    app: nazwa-aplikacji           # Identyfikuje aplikację
    version: v1.2.3                # Wersja aplikacji
    component: frontend            # Komponent (frontend/backend/database)
    tier: web                      # Warstwa (web/app/data)
    environment: production        # Środowisko
    
    # Własne etykiety
    team: zespol-backend           # Zespół odpowiedzialny
    cost-center: centrum-kosztow   # Centrum kosztów
    release: release-2024-06       # Wydanie
```

### Selektory - Wybieranie Obiektów
```bash
# Komenda kubectl z selektorami etykiet
kubectl get pods -l app=frontend                    # Pody z app=frontend
kubectl get pods -l environment=production          # Pody produkcyjne
kubectl get pods -l app=frontend,tier=web          # Pody z wieloma etykietami
kubectl get pods -l app!=backend                   # Pody które NIE są backend
kubectl get pods -l 'environment in (dev,test)'    # Pody z dev LUB test
```

## 🏠 Namespaces - Wirtualne Klastry

### Organizacja przez Namespaces
```yaml
# Namespace to wirtualny klaster wewnątrz fizycznego klastra
# Izoluje zasoby między zespołami/projektami/środowiskami

apiVersion: v1
kind: Namespace
metadata:
  name: produkcja                  # Nazwa namespace
  labels:
    environment: production        # Typ środowiska
    team: backend                  # Zespół właściciel
  annotations:                     # Dodatkowe metadane
    contact: "zespol@firma.com"    # Kontakt do zespołu
    description: "Środowisko produkcyjne aplikacji backend"
```

### Domyślne Namespaces
```bash
# Kubernetes tworzy automatycznie:
default          # Domyślny namespace dla obiektów bez określonego namespace
kube-system      # Obiekty systemowe Kubernetes
kube-public      # Obiekty publiczne dostępne dla wszystkich
kube-node-lease  # Obiekty związane z dzierżawą węzłów
```

### Praca z Namespaces
```bash
# Lista wszystkich namespaces
kubectl get namespaces
kubectl get ns

# Tworzenie namespace
kubectl create namespace moje-aplikacje

# Ustawienie domyślnego namespace dla sesji
kubectl config set-context --current --namespace=produkcja

# Sprawdzenie obecnego namespace
kubectl config view --minify | grep namespace
```

## 🔧 YAML - Język Konfiguracji

### Struktura Pliku YAML Kubernetes
```yaml
# Każdy obiekt Kubernetes ma taką samą podstawową strukturę:

apiVersion: apps/v1              # Wersja API dla tego typu obiektu
kind: Deployment                 # Typ obiektu Kubernetes
metadata:                        # Metadane obiektu
  name: nazwa-obiektu           # Unikalna nazwa w namespace
  namespace: moj-namespace      # Namespace gdzie obiekt istnieje
  labels:                       # Etykiety dla organizacji
    klucz: wartosc
  annotations:                  # Dodatkowe metadane (nie do selekcji)
    opis: "Szczegółowy opis obiektu"
spec:                           # Specyfikacja - jak obiekt ma działać
  # Zawartość spec zależy od typu obiektu (kind)
  replicas: 3
  # ... więcej konfiguracji
status:                         # Status - obecny stan (zarządzany przez K8s)
  # Ten sekcja jest zarządzana automatycznie przez Kubernetes
  # Nie edytujemy jej ręcznie
```

### Wiele Obiektów w Jednym Pliku
```yaml
# Można zdefiniować wiele obiektów w jednym pliku
# Oddzielone trzema myślnikami

apiVersion: v1
kind: Namespace
metadata:
  name: moja-aplikacja

---                             # Separator między obiektami

apiVersion: apps/v1
kind: Deployment
metadata:
  name: aplikacja
  namespace: moja-aplikacja     # Użyj namespace zdefiniowanego wyżej
spec:
  replicas: 2
  # ... reszta konfiguracji

---

apiVersion: v1
kind: Service
metadata:
  name: aplikacja-service
  namespace: moja-aplikacja
spec:
  # ... konfiguracja serwisu
```

## 🔄 Cykl Życia Obiektów

### Stany Obiektów
```
Plik YAML → kubectl apply → API Server → etcd → Controller → Kubelet → Kontener
    ↑                                                                      ↓
    └── kubectl get/describe ← Status ← Stan rzeczywisty ←──────────────────┘
```

### Podstawowe Operacje
```bash
# Tworzenie obiektów z pliku
kubectl apply -f plik.yaml                    # Tworzy lub aktualizuje
kubectl create -f plik.yaml                   # Tylko tworzy (błąd jeśli istnieje)

# Sprawdzanie stanu
kubectl get pods                               # Lista podów
kubectl get pods -o wide                      # Więcej szczegółów
kubectl describe pod nazwa-poda                # Pełne szczegóły

# Aktualizacja obiektów
kubectl apply -f zaktualizowany-plik.yaml     # Aktualizuje istniejący obiekt
kubectl patch deployment nazwa --patch='...'   # Częściowa aktualizacja

# Usuwanie obiektów
kubectl delete -f plik.yaml                   # Usuwa obiekty z pliku
kubectl delete pod nazwa-poda                 # Usuwa konkretny obiekt
```

## 🌐 Komunikacja w Klastrze

### DNS Wewnętrzny
```
# Format nazw DNS w Kubernetes:
nazwa-serwisu.namespace.svc.cluster.local

# Przykłady:
frontend-service.produkcja.svc.cluster.local     # Pełna nazwa
frontend-service.produkcja                       # Skrócona (bez svc.cluster.local)
frontend-service                                 # Z tego samego namespace
```

### Adresy IP
```bash
# Każdy pod otrzymuje unikalny adres IP w klastrze
# Adresy IP podów są:
# - Tymczasowe (pod zostaje usunięty → IP się zmienia)
# - Dostępne z całego klastra
# - Niewidoczne z zewnątrz klastra (bez specjalnej konfiguracji)

# Serwisy otrzymują stały adres IP (Cluster IP)
# Ten adres nie zmienia się przez cały czas życia serwisu
```

## 💡 Kluczowe Koncepcje

### Deklaratywne Zarządzanie
```yaml
# W Kubernetes opisujesz JAKI ma być stan (deklaratywnie)
# a nie JAK go osiągnąć (imperatywnie)

# Deklaratywnie (preferowane):
spec:
  replicas: 3                  # "Chcę 3 pody"

# Kubernetes automatycznie:
# - Tworzy brakujące pody
# - Usuwa nadmiarowe pody  
# - Restartuje awarie
# - Utrzymuje pożądany stan
```

### Kontrolery - Pętle Kontrolne
```
┌─────────────────────────────────────────────────────────┐
│                   PĘTLA KONTROLNA                       │
├─────────────────────────────────────────────────────────┤
│ 1. Obserwuj aktualny stan                              │
│ 2. Porównaj z pożądanym stanem                         │
│ 3. Jeśli różnią się → wykonaj akcję korekcyjną         │
│ 4. Powtarzaj                                           │
└─────────────────────────────────────────────────────────┘

# Przykład: Deployment Controller
# Pożądane: 3 pody
# Aktualne: 2 pody
# Akcja: Utwórz 1 nowy pod
```

### Tolerancja na Błędy
```yaml
# Kubernetes automatycznie radzi sobie z awariami:
# - Pod umiera → Tworzy nowy
# - Węzeł przestaje odpowiadać → Przenosi pody na inne węzły
# - Aplikacja nie przechodzi health check → Restartuje kontener
# - Za mało zasobów → Czeka na dostępność lub wyrzuca mniej ważne pody
```

---
*Solidne fundamenty dla zrozumienia Kubernetes! 🏗️*