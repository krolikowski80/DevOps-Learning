# Helm - Podstawy i Architektura

## 🎯 Czym Jest Helm

### Definicja i Zastosowanie
```bash
# Helm to "package manager" dla Kubernetes
# Pozwala na:
# - Pakietowanie aplikacji Kubernetes (Charts)
# - Wersjonowanie deploymentów (Releases)
# - Zarządzanie konfiguracją (Values)
# - Udostępnianie gotowych rozwiązań (Repositories)

# Główne komponenty:
# Chart    = Pakiet plików YAML + szablonów
# Release  = Konkretna instancja Chart w klastrze  
# Values   = Konfiguracja dla Chart
# Template = YAML z placeholderami {{ }}
```

### Architektura Helm 3
```
┌─────────────────────────────────────────────────────────┐
│                    HELM KLIENT                         │
├─────────────────────────────────────────────────────────┤
│ • helm CLI                                              │
│ • Chart management                                      │
│ • Template rendering                                    │
│ • Release tracking                                      │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│               KUBERNETES API                            │
├─────────────────────────────────────────────────────────┤
│ • Secret storage (release info)                         │
│ • Resource management                                   │
│ • RBAC enforcement                                      │
└─────────────────────────────────────────────────────────┘

# Helm 3 różnice od Helm 2:
# - Brak Tiller (server component)
# - Release info w Secrets (nie ConfigMaps)
# - Lepsze bezpieczeństwo (RBAC)
# - Library charts
# - JSON Schema validation
```

## 📦 Chart - Struktura i Komponenty

### Podstawowa Struktura Chart
```
moja-aplikacja/                    # Nazwa chart
├── Chart.yaml                     # Metadane chart
├── values.yaml                    # Domyślne wartości
├── charts/                        # Sub-charts (zależności)
├── templates/                     # Szablony Kubernetes YAML
│   ├── deployment.yaml            # Template deployment
│   ├── service.yaml               # Template service
│   ├── ingress.yaml               # Template ingress
│   ├── configmap.yaml             # Template configmap
│   ├── secret.yaml                # Template secret
│   ├── _helpers.tpl               # Template helpers (funkcje)
│   ├── NOTES.txt                  # Informacje po instalacji
│   └── tests/                     # Helm tests
│       └── test-connection.yaml
├── .helmignore                    # Pliki do ignorowania
└── README.md                      # Dokumentacja chart
```

### Chart.yaml - Metadane
```yaml
# Plik Chart.yaml definiuje chart
apiVersion: v2                      # API version (v2 dla Helm 3)
name: moja-aplikacja                # Nazwa chart (musi być unikalna)
description: "Aplikacja webowa z bazą danych"  # Opis chart
type: application                   # application lub library
version: 1.2.3                     # Wersja chart (SemVer)
appVersion: "2.1.0"                # Wersja aplikacji (opcjonalne)

# Metadane dodatkowe
keywords:                           # Słowa kluczowe dla wyszukiwania
  - web
  - api
  - backend
home: "https://github.com/firma/moja-aplikacja"  # Homepage
sources:                            # Źródła kodu
  - "https://github.com/firma/moja-aplikacja"
maintainers:                        # Opiekunowie chart
  - name: "Jan Kowalski"
    email: "jan.kowalski@firma.com"
    url: "https://github.com/jkowalski"

# Zależności od innych charts
dependencies:
  - name: mysql                     # Nazwa zależności
    version: "9.4.0"               # Wersja chart zależności
    repository: "https://charts.bitnami.com/bitnami"  # Repo
    condition: mysql.enabled        # Warunek włączenia
  - name: redis
    version: "17.3.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled

# Annotations - dodatkowe metadane
annotations:
  category: "WebApplication"        # Kategoria aplikacji
  licenses: "Apache-2.0"           # Licencja
```

### values.yaml - Konfiguracja Domyślna
```yaml
# Plik values.yaml zawiera domyślne wartości dla chart
# Użytkownicy mogą override te wartości

# Podstawowa konfiguracja aplikacji
serviceName: "moja-aplikacja"       # Nazwa serwisu
image:
  repository: "nginx"               # Repository obrazu
  tag: "1.25-alpine"               # Tag obrazu  
  pullPolicy: IfNotPresent         # Image pull policy

# Replicas i scaling
replicaCount: 2                     # Liczba replik
autoscaling:
  enabled: false                    # Czy włączyć HPA
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

# Networking
service:
  type: ClusterIP                   # Typ serwisu
  port: 80                          # Port serwisu
  targetPort: 8080                  # Port kontenera

ingress:
  enabled: false                    # Czy tworzyć Ingress
  className: "nginx"                # Ingress class
  annotations: {}                   # Annotations dla Ingress
  hosts:
    - host: "api.example.com"
      paths:
        - path: /
          pathType: Prefix
  tls: []                          # TLS configuration

# Resources i limits
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"

# Health checks
healthCheck:
  enabled: true                     # Czy dodać health checks
  path: "/health"                   # Ścieżka health check
  port: 8080                        # Port health check
  livenessProbe:
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
  readinessProbe:
    initialDelaySeconds: 5
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 2

# Environment variables
env:
  - name: ENVIRONMENT
    value: "production"
  - name: LOG_LEVEL
    value: "INFO"

# Environment variables z ConfigMap/Secret
envFrom: []
  # - configMapRef:
  #     name: app-config
  # - secretRef:
  #     name: app-secrets

# Volumes
volumes: []
volumeMounts: []

# Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 2001

# Pod annotations i labels
podAnnotations: {}
podLabels: {}

# Node selection
nodeSelector: {}
tolerations: []
affinity: {}

# Service Account
serviceAccount:
  create: true                      # Czy tworzyć ServiceAccount
  name: ""                          # Nazwa (domyślnie: chart name)
  annotations: {}

# Zależności (sub-charts)
mysql:
  enabled: false                    # Czy włączyć MySQL
  auth:
    rootPassword: "secretpassword"
    database: "myapp"

redis:
  enabled: false                    # Czy włączyć Redis
  auth:
    enabled: false
```

## 🛠️ Template Engine - Go Templates

### Podstawowe Funkcje Template
```yaml
# Plik templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.serviceName }}           # Wstawienie wartości z values.yaml
  namespace: {{ .Release.Namespace }}       # Namespace release
  labels:
    app: {{ .Values.serviceName }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version }}     # Nazwa i wersja chart
    release: {{ .Release.Name }}            # Nazwa release
    heritage: {{ .Release.Service }}        # Zawsze "Helm"
spec:
  replicas: {{ .Values.replicaCount }}      # Liczba replik z values
  selector:
    matchLabels:
      app: {{ .Values.serviceName }}
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Values.serviceName }}
        release: {{ .Release.Name }}
    spec:
      containers:
      - name: {{ .Values.serviceName }}
        image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
```

### Wbudowane Obiekty Helm
```yaml
# Obiekty dostępne w każdym template:

# .Release - informacje o release
{{ .Release.Name }}                 # Nazwa release (podana przez użytkownika)
{{ .Release.Namespace }}            # Namespace gdzie instalowany
{{ .Release.IsUpgrade }}            # true jeśli to upgrade
{{ .Release.IsInstall }}            # true jeśli to pierwsza instalacja
{{ .Release.Revision }}             # Numer rewizji release
{{ .Release.Service }}              # Zawsze "Helm"

# .Chart - informacje z Chart.yaml
{{ .Chart.Name }}                   # Nazwa chart
{{ .Chart.Version }}                # Wersja chart
{{ .Chart.Description }}            # Opis chart
{{ .Chart.Keywords }}               # Lista słów kluczowych
{{ .Chart.Maintainers }}            # Lista maintainerów

# .Values - wartości z values.yaml i override
{{ .Values.serviceName }}           # Wartość z values.yaml
{{ .Values.image.repository }}      # Nested value

# .Files - dostęp do plików w chart
{{ .Files.Get "config/app.properties" }}    # Zawartość pliku
{{ .Files.Glob "config/*.yaml" }}           # Lista plików matching pattern

# .Capabilities - informacje o klastrze
{{ .Capabilities.KubeVersion }}     # Wersja Kubernetes
{{ .Capabilities.APIVersions }}     # Dostępne API versions
```

### Funkcje Template - Kontrola Przepływu
```yaml
# If/Else - warunkowe renderowanie
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.serviceName }}-ingress
spec:
  # ... konfiguracja ingress
{{- end }}

# If/Else/Else if
{{- if eq .Values.service.type "ClusterIP" }}
  type: ClusterIP
{{- else if eq .Values.service.type "NodePort" }}
  type: NodePort
  nodePort: {{ .Values.service.nodePort }}
{{- else }}
  type: LoadBalancer
{{- end }}

# Range - iteracja po listach
env:
{{- range .Values.env }}
- name: {{ .name }}
  value: {{ .value | quote }}
{{- end }}

# Range z mapami
annotations:
{{- range $key, $value := .Values.podAnnotations }}
  {{ $key }}: {{ $value | quote }}
{{- end }}

# With - zmiana kontekstu
{{- with .Values.securityContext }}
securityContext:
  runAsNonRoot: {{ .runAsNonRoot }}
  runAsUser: {{ .runAsUser }}
  fsGroup: {{ .fsGroup }}
{{- end }}
```

### Funkcje Template - Manipulacja Danych
```yaml
# String functions
name: {{ .Values.serviceName | upper }}     # UPPERCASE
name: {{ .Values.serviceName | lower }}     # lowercase
name: {{ .Values.serviceName | title }}     # Title Case

# Quote/Unquote
value: {{ .Values.setting | quote }}        # "value"
value: {{ .Values.setting | squote }}       # 'value'

# Default values
replicas: {{ .Values.replicaCount | default 1 }}        # Domyślnie 1
image: {{ .Values.image.tag | default "latest" }}       # Domyślnie latest

# Type conversion
port: {{ .Values.service.port | int }}      # Convert to integer
enabled: {{ .Values.feature | bool }}       # Convert to boolean

# Encoding
data:
  config: {{ .Files.Get "config.yaml" | b64enc }}       # Base64 encode

# JSON/YAML output
data: {{ .Values.config | toYaml | nindent 2 }}         # YAML output z wcięciem
data: {{ .Values.config | toJson }}                     # JSON output

# List functions
{{- if has "production" .Values.environments }}         # Sprawdź czy lista zawiera
env: production
{{- end }}

# Date functions
timestamp: {{ now | date "2006-01-02T15:04:05Z" }}      # Current timestamp

# Math functions
cpu: {{ add .Values.baseCPU .Values.extraCPU }}m        # Dodawanie
memory: {{ mul .Values.baseMemory 2 }}Mi                # Mnożenie
```

## 🔧 Template Helpers - _helpers.tpl

### Standardowe Helper Functions
```yaml
# Plik templates/_helpers.tpl
# Zawiera funkcje pomocnicze używane w wielu templates

{{/*
Expand the name of the chart.
*/}}
{{- define "moja-aplikacja.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "moja-aplikacja.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "moja-aplikacja.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "moja-aplikacja.labels" -}}
helm.sh/chart: {{ include "moja-aplikacja.chart" . }}
{{ include "moja-aplikacja.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "moja-aplikacja.selectorLabels" -}}
app.kubernetes.io/name: {{ include "moja-aplikacja.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "moja-aplikacja.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "moja-aplikacja.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

### Użycie Helpers w Templates
```yaml
# templates/deployment.yaml z użyciem helpers
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
      serviceAccountName: {{ include "moja-aplikacja.serviceAccountName" . }}
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        # ... reszta konfiguracji
```

## 📋 Best Practices Template Design

### ✅ Naming Conventions
```yaml
# Używaj helpers dla nazw
name: {{ include "chart.fullname" . }}       # NIE: {{ .Release.Name }}-app

# Consistent labeling
labels:
  {{- include "chart.labels" . | nindent 4 }}

# Używaj quote dla string values
value: {{ .Values.setting | quote }}

# Default values dla wszystkiego
replicas: {{ .Values.replicaCount | default 1 }}
```

### ✅ Resource Management
```yaml
# Zawsze umożliw konfigurację resources
{{- if .Values.resources }}
resources:
  {{- toYaml .Values.resources | nindent 10 }}
{{- end }}

# Security context jako opcja
{{- if .Values.securityContext }}
securityContext:
  {{- toYaml .Values.securityContext | nindent 10 }}
{{- end }}
```

### ✅ Flexibility Patterns
```yaml
# Environment variables - różne źródła
env:
{{- range .Values.env }}
- name: {{ .name }}
  value: {{ .value | quote }}
{{- end }}

{{- if .Values.envFrom }}
envFrom:
{{- range .Values.envFrom }}
- {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}

# Volumes - opcjonalne
{{- if .Values.volumes }}
volumes:
{{- toYaml .Values.volumes | nindent 0 }}
{{- end }}
```

---
*Solidne fundamenty Helm - od podstaw do zaawansowanych templates! 📦*