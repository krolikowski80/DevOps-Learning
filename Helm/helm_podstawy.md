# 🚀 Helm – Podstawy i Architektura
---

## 🎯 Czym Jest Helm

### 🧠 Definicja

> **Helm** to **menedżer pakietów dla Kubernetes**, podobny do `apt` (Ubuntu), `brew` (macOS) lub `pip` (Python), ale specjalnie zaprojektowany do wdrażania aplikacji w klastrze Kubernetes.

Helm pozwala Ci:

- 🧱 **Zapakować aplikację** do tzw. *Chartów* (czyli szablonów YAML),
- 🔁 **Zarządzać wersjami wdrożeń** (każda instalacja to *release*),
- 🛠️ **Dostosowywać konfigurację** (np. ilość replik, obraz dockera),
- 🔄 **Reużywać gotowe rozwiązania** z repozytoriów Helm Charts.

---

## ⚙️ Architektura Helm 3

### 🔧 Komponenty Helm 3

```
┌───────────────────────────────────────────────────────┐
│                    HELM KLIENT (twój laptop)          │
├───────────────────────────────────────────────────────┤
│ • helm CLI – narzędzie w terminalu                    │
│ • zarządzanie chartami (tworzenie, edycja, usuwanie) │
│ • renderowanie szablonów do YAML                      │
│ • śledzenie stanu wdrożeń (Releases)                  │
└─────────────────────┬─────────────────────────────────┘
                      │
                      ▼
┌───────────────────────────────────────────────────────┐
│               KUBERNETES API SERVER                   │
├───────────────────────────────────────────────────────┤
│ • przechowuje dane o release'ach jako Secrets         │
│ • wykonuje deploymenty zasobów z szablonów YAML       │
│ • kontroluje dostęp za pomocą RBAC                    │
└───────────────────────────────────────────────────────┘
```

### 🆚 Różnice Helm 3 vs Helm 2

- ❌ Brak `Tiller` – wcześniej Helm wymagał osobnego komponentu w klastrze, teraz działa bezpośrednio z poziomu CLI.
- 🔐 Lepsze bezpieczeństwo dzięki RBAC – użytkownik używa własnych uprawnień, a nie konta `Tiller`.
- 📦 Release info przechowywane w **Secrets**, a nie w **ConfigMaps**.
- 🔍 Walidacja schemas przez JSON Schema.

---

## 📦 Helm Chart – Struktura i Składniki

> Helm Chart to folder zawierający wszystko, co potrzeba, żeby wdrożyć aplikację w Kubernetesie. To tak jakby projekt aplikacji z szablonami YAML.

### 📁 Przykładowa Struktura Chartu

```bash
moja-aplikacja/
├── Chart.yaml       # Informacje o pakiecie
├── values.yaml      # Domyślne ustawienia
├── templates/       # Szablony do renderowania YAML
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── _helpers.tpl  # Funkcje pomocnicze (makra)
│   └── NOTES.txt     # Porady po instalacji
├── charts/          # Wewnętrzne zależności (sub-charts)
├── .helmignore      # Pliki ignorowane przy pakowaniu
└── README.md        # Dokumentacja
```

Każdy z tych plików ma swoje **konkretne zastosowanie**, które dokładnie wyjaśniamy w kolejnych sekcjach...

🔽 *(ciąg dalszy poniżej w pełnym pliku .md)*  


---

## 🧾 Chart.yaml – Plik z Metadanymi

Plik `Chart.yaml` to jak "manifest" twojego pakietu – mówi Helmowi, **jak się nazywa**, **jaka jest wersja**, **co zawiera**, **od czego zależy** i **kto go utrzymuje**.

### 🔍 Przykład z komentarzami:

```yaml
apiVersion: v2                      # Wersja API Chartu (v2 = Helm 3+)
name: moja-aplikacja                # Nazwa twojego Chartu
description: "Aplikacja webowa z bazą danych"
type: application                   # 'application' = wdrażalna aplikacja, 'library' = zbiór funkcji/templatek
version: 1.2.3                      # Wersja chartu (dla Helm - np. 1.0.0)
appVersion: "2.1.0"                 # Wersja aplikacji (np. tag Dockera, łączona z obrazem)

keywords:
  - web                             # Słowa kluczowe do wyszukiwania chartu
  - backend
home: "https://github.com/firma/moja-aplikacja"  # Link do strony domowej lub repozytorium
sources:
  - "https://github.com/firma/moja-aplikacja"    # Linki do źródeł kodu

maintainers:                        # Lista osób utrzymujących ten chart
  - name: "Jan Kowalski"
    email: "jan.kowalski@firma.com"

dependencies:                       # Inne charty, które są potrzebne
  - name: mysql
    version: "9.4.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: mysql.enabled        # Instaluj tylko, jeśli w values.yaml ustawiono `mysql.enabled: true`
```

---

## ⚙️ values.yaml – Domyślna Konfiguracja

Plik `values.yaml` to miejsce, gdzie podajesz wszystkie ustawienia konfiguracyjne dla szablonów. Można je **nadpisać** podczas instalacji (`helm install -f custom-values.yaml`).

Ten plik to **kręgosłup personalizacji** twojej aplikacji.

### 📌 Przykład i omówienie

```yaml
image:
  repository: "nginx"               # Obraz Dockera do pobrania
  tag: "1.25-alpine"                # Konkretna wersja obrazu
  pullPolicy: IfNotPresent          # Strategia pobierania (np. Always / Never / IfNotPresent)

replicaCount: 2                     # Ile replik aplikacji uruchomić

service:
  type: ClusterIP                   # Typ usługi w Kubernetes (ClusterIP, NodePort, LoadBalancer)
  port: 80                          # Port udostępniany przez usługę
  targetPort: 8080                  # Port kontenera, do którego przekierowujemy

ingress:
  enabled: false                    # Czy tworzyć Ingress?
  className: "nginx"                # Klasa kontrolera Ingress
  hosts:
    - host: "api.example.com"
      paths:
        - path: /
          pathType: Prefix

resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

📌 **Warto wiedzieć:** W `values.yaml` możesz definiować **całą strukturę logiczną aplikacji** – od zmiennych środowiskowych po limity CPU/RAM, kontrolę dostępu, wolumeny, itp.

---

🔄 **Kolejna część** (szablony `deployment.yaml`, `helpers.tpl`, best practices) w kolejnym kroku.  
Zapisuję ten fragment do pliku `.md`…



---

## 🛠️ Templates – Szablony w Helm

Folder `templates/` zawiera pliki YAML z placeholderami (`{{ }}`), które Helm przetwarza na końcowe definicje Kubernetes (Deploymenty, Serwisy itd.).

> 🔧 To tu dzieje się „magia” – dynamiczne generowanie plików YAML na podstawie konfiguracji `values.yaml`.

Przykład `deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "moja-aplikacja.fullname" . }}
  labels:
    {{- include "moja-aplikacja.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "moja-aplikacja.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "moja-aplikacja.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: {{ .Values.service.targetPort }}
```

---

## 🔧 Go Template – Silnik Templatek

Helm używa silnika Go Templates, który umożliwia:

- 💬 Wstawianie zmiennych (`{{ .Values.coś }}`),
- 🧠 Warunki logiczne (`if`, `else`, `range`, `with`),
- 🔄 Iteracje i mapowanie,
- 🧪 Funkcje (np. `quote`, `default`, `toYaml`).

Przykład: iteracja po zmiennych środowiskowych

```yaml
env:
{{- range .Values.env }}
- name: {{ .name }}
  value: {{ .value | quote }}
{{- end }}
```

---

## 🧩 _helpers.tpl – Funkcje Pomocnicze

Plik `_helpers.tpl` pozwala definiować własne „makra” i funkcje, np. do generowania nazw, labeli, itp.

```yaml
{{- define "moja-aplikacja.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name }}
{{- end }}
{{- end }}
```

Można je potem używać np. tak:
```yaml
name: {{ include "moja-aplikacja.fullname" . }}
```

---

## ✅ Best Practices – Dobre Praktyki

🔹 **Nazwy przez helpers**:
```yaml
name: {{ include "moja-aplikacja.fullname" . }}
```

🔹 **Labelowanie spójne z K8s**:
```yaml
labels:
  {{- include "moja-aplikacja.labels" . | nindent 4 }}
```

🔹 **Wszystko konfigurowalne przez `values.yaml`**:
```yaml
replicas: {{ .Values.replicaCount | default 1 }}
```

🔹 **Blokowanie renderowania tylko jeśli coś ustawiono**:
```yaml
{{- if .Values.resources }}
resources:
  {{- toYaml .Values.resources | nindent 10 }}
{{- end }}
```

🔹 **Używaj `quote`, `default`, `toYaml` – to bezpieczniejsze i czytelniejsze**

---


