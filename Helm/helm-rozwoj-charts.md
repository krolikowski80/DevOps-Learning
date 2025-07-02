# Helm - Rozwój Charts i Praktyczne Użycie

## 🛠️ Tworzenie Nowego Chart

### Inicjalizacja Chart
```bash
# Tworzenie nowego chart
helm create moja-aplikacja              # Tworzy strukturę chart

# Struktura utworzona przez helm create:
tree moja-aplikacja/
# moja-aplikacja/
# ├── Chart.yaml                        # Metadane
# ├── values.yaml                       # Domyślne wartości
# ├── charts/                           # Sub-charts
# ├── templates/
# │   ├── deployment.yaml
# │   ├── service.yaml
# │   ├── ingress.yaml
# │   ├── serviceaccount.yaml
# │   ├── _helpers.tpl
# │   ├── NOTES.txt
# │   └── tests/
# │       └── test-connection.yaml
# └── .helmignore

# Cleanup domyślnych plików (opcjonalne)
cd moja-aplikacja/
rm -f templates/ingress.yaml            # Jeśli nie potrzebujemy
rm -f templates/serviceaccount.yaml     # Jeśli nie potrzebujemy
rm -rf templates/tests/                 # Jeśli nie robimy testów
```

### Podstawowy Template Deployment
```yaml
# templates/deployment.yaml - praktyczny przykład
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "moja-aplikacja.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "moja-aplikacja.labels" . | nindent 4 }}
  {{- with .Values.deploymentAnnotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  
  # Strategia aktualizacji
  strategy:
    type: {{ .Values.updateStrategy.type | default "RollingUpdate" }}
    {{- if eq .Values.updateStrategy.type "RollingUpdate" }}
    rollingUpdate:
      maxUnavailable: {{ .Values.updateStrategy.maxUnavailable | default 0 }}
      maxSurge: {{ .Values.updateStrategy.maxSurge | default 1 }}
    {{- end }}
  
  selector:
    matchLabels:
      {{- include "moja-aplikacja.selectorLabels" . | nindent 6 }}
  
  template:
    metadata:
      labels:
        {{- include "moja-aplikacja.selectorLabels" . | nindent 8 }}
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      
      {{- if .Values.serviceAccount.create }}
      serviceAccountName: {{ include "moja-aplikacja.serviceAccountName" . }}
      {{- end }}
      
      {{- with .Values.securityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        
        # Porty
        ports:
        - name: http
          containerPort: {{ .Values.containerPort | default 8080 }}
          protocol: TCP
        {{- range .Values.additionalPorts }}
        - name: {{ .name }}
          containerPort: {{ .port }}
          protocol: {{ .protocol | default "TCP" }}
        {{- end }}
        
        # Environment variables
        {{- if or .Values.env .Values.envFrom }}
        {{- if .Values.env }}
        env:
        {{- range .Values.env }}
        - name: {{ .name }}
          {{- if .value }}
          value: {{ .value | quote }}
          {{- else if .valueFrom }}
          valueFrom:
            {{- toYaml .valueFrom | nindent 12 }}
          {{- end }}
        {{- end }}
        {{- end }}
        
        {{- if .Values.envFrom }}
        envFrom:
        {{- range .Values.envFrom }}
        - {{ toYaml . | nindent 10 }}
        {{- end }}
        {{- end }}
        {{- end }}
        
        # Health checks
        {{- if .Values.healthCheck.enabled }}
        livenessProbe:
          httpGet:
            path: {{ .Values.healthCheck.path }}
            port: {{ .Values.healthCheck.port | default "http" }}
          initialDelaySeconds: {{ .Values.healthCheck.livenessProbe.initialDelaySeconds }}
          periodSeconds: {{ .Values.healthCheck.livenessProbe.periodSeconds }}
          timeoutSeconds: {{ .Values.healthCheck.livenessProbe.timeoutSeconds }}
          failureThreshold: {{ .Values.healthCheck.livenessProbe.failureThreshold }}
          successThreshold: {{ .Values.healthCheck.livenessProbe.successThreshold | default 1 }}
        
        readinessProbe:
          httpGet:
            path: {{ .Values.healthCheck.path }}
            port: {{ .Values.healthCheck.port | default "http" }}
          initialDelaySeconds: {{ .Values.healthCheck.readinessProbe.initialDelaySeconds }}
          periodSeconds: {{ .Values.healthCheck.readinessProbe.periodSeconds }}
          timeoutSeconds: {{ .Values.healthCheck.readinessProbe.timeoutSeconds }}
          failureThreshold: {{ .Values.healthCheck.readinessProbe.failureThreshold }}
          successThreshold: {{ .Values.healthCheck.readinessProbe.successThreshold | default 1 }}
        {{- end }}
        
        # Resources
        {{- if .Values.resources }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        {{- end }}
        
        # Volume mounts
        {{- if .Values.volumeMounts }}
        volumeMounts:
        {{- toYaml .Values.volumeMounts | nindent 8 }}
        {{- end }}
        
        # Security context kontenera
        {{- if .Values.containerSecurityContext }}
        securityContext:
          {{- toYaml .Values.containerSecurityContext | nindent 10 }}
        {{- end }}
      
      # Volumes
      {{- if .Values.volumes }}
      volumes:
      {{- toYaml .Values.volumes | nindent 6 }}
      {{- end }}
      
      # Node selection
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      
      # Graceful shutdown
      terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds | default 30 }}
```

### Service Template z Flexibility
```yaml
# templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "moja-aplikacja.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "moja-aplikacja.labels" . | nindent 4 }}
  {{- with .Values.service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .Values.service.type }}
  
  {{- if and (eq .Values.service.type "LoadBalancer") .Values.service.loadBalancerIP }}
  loadBalancerIP: {{ .Values.service.loadBalancerIP }}
  {{- end }}
  
  {{- if and (eq .Values.service.type "LoadBalancer") .Values.service.loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
  {{- range .Values.service.loadBalancerSourceRanges }}
  - {{ . }}
  {{- end }}
  {{- end }}
  
  {{- if .Values.service.externalTrafficPolicy }}
  externalTrafficPolicy: {{ .Values.service.externalTrafficPolicy }}
  {{- end }}
  
  {{- if .Values.service.sessionAffinity }}
  sessionAffinity: {{ .Values.service.sessionAffinity }}
  {{- if .Values.service.sessionAffinityConfig }}
  sessionAffinityConfig:
    {{- toYaml .Values.service.sessionAffinityConfig | nindent 4 }}
  {{- end }}
  {{- end }}
  
  ports:
  - port: {{ .Values.service.port }}
    targetPort: {{ .Values.service.targetPort | default "http" }}
    protocol: {{ .Values.service.protocol | default "TCP" }}
    name: http
    {{- if and (eq .Values.service.type "NodePort") .Values.service.nodePort }}
    nodePort: {{ .Values.service.nodePort }}
    {{- end }}
  
  # Dodatkowe porty
  {{- range .Values.service.additionalPorts }}
  - port: {{ .port }}
    targetPort: {{ .targetPort | default .port }}
    protocol: {{ .protocol | default "TCP" }}
    name: {{ .name }}
    {{- if and (eq $.Values.service.type "NodePort") .nodePort }}
    nodePort: {{ .nodePort }}
    {{- end }}
  {{- end }}
  
  selector:
    {{- include "moja-aplikacja.selectorLabels" . | nindent 4 }}
```

## 🔄 Testing i Validation

### Helm Template Rendering
```bash
# Renderowanie templates lokalnie (bez instalacji)
helm template moja-aplikacja ./moja-aplikacja/

# Renderowanie z custom values
helm template moja-aplikacja ./moja-aplikacja/ -f custom-values.yaml

# Renderowanie konkretnego template
helm template moja-aplikacja ./moja-aplikacja/ -s templates/deployment.yaml

# Debug mode - więcej informacji
helm template moja-aplikacja ./moja-aplikacja/ --debug

# Dry run z validation przeciwko API server
helm install moja-aplikacja ./moja-aplikacja/ --dry-run --debug

# Lint - sprawdzenie poprawności chart
helm lint ./moja-aplikacja/

# Sprawdzenie z custom values
helm lint ./moja-aplikacja/ -f production-values.yaml
```

### Helm Test Framework
```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "moja-aplikacja.fullname" . }}-test"
  labels:
    {{- include "moja-aplikacja.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test                    # Hook type: test
    "helm.sh/hook-weight": "1"              # Kolejność wykonania
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded  # Kiedy usunąć
spec:
  restartPolicy: Never                      # Test pod nie restartuje się
  containers:
  - name: wget
    image: busybox:1.35
    command: ['wget']
    args: 
    - '--spider'                            # Tylko sprawdź connectivity
    - '--timeout=10'                        # Timeout 10 sekund
    - '{{ include "moja-aplikacja.fullname" . }}:{{ .Values.service.port }}'
  
  # Test z curl dla bardziej złożonych przypadków
  - name: curl-test
    image: curlimages/curl:8.0.1
    command: 
    - '/bin/sh'
    - '-c'
    - |
      set -e
      echo "Testing application health endpoint..."
      curl -f http://{{ include "moja-aplikacja.fullname" . }}:{{ .Values.service.port }}/health
      echo "Health check passed!"
      
      echo "Testing application ready endpoint..."  
      curl -f http://{{ include "moja-aplikacja.fullname" . }}:{{ .Values.service.port }}/ready
      echo "Ready check passed!"
```

### Uruchamianie Testów
```bash
# Instalacja chart
helm install test-release ./moja-aplikacja/

# Uruchomienie testów
helm test test-release

# Uruchomienie testów z logami
helm test test-release --logs

# Sprawdzenie rezultatów testów
kubectl get pods -l app.kubernetes.io/name=moja-aplikacja
kubectl logs test-release-moja-aplikacja-test

# Cleanup po testach
helm delete test-release
```

## 📦 Dependencies i Sub-Charts

### Dodawanie Dependencies
```yaml
# Chart.yaml - definicja zależności
dependencies:
- name: mysql                               # Nazwa chart dependency
  version: "9.4.0"                         # Wersja chart
  repository: "https://charts.bitnami.com/bitnami"  # Helm repository
  condition: mysql.enabled                  # Warunek włączenia
  alias: database                           # Alias dla values (opcjonalne)

- name: redis
  version: "17.3.0"
  repository: "https://charts.bitnami.com/bitnami"
  condition: redis.enabled
  
- name: postgresql
  version: "12.1.0"
  repository: "https://charts.bitnami.com/bitnami"
  condition: postgresql.enabled
  tags:                                     # Grupowanie dependencies
    - database
```

### Zarządzanie Dependencies
```bash
# Pobranie dependencies
helm dependency update ./moja-aplikacja/

# Sprawdzenie dependencies
helm dependency list ./moja-aplikacja/

# Dependencies są pobrane do charts/
ls -la ./moja-aplikacja/charts/
# mysql-9.4.0.tgz
# redis-17.3.0.tgz
# postgresql-12.1.0.tgz

# Build dependencies (alternatywnie do update)
helm dependency build ./moja-aplikacja/
```

### Konfiguracja Sub-Charts w Values
```yaml
# values.yaml - konfiguracja dependencies
# Główna aplikacja
serviceName: "moja-aplikacja"
image:
  repository: "my-app"
  tag: "1.0.0"

# MySQL sub-chart configuration
mysql:
  enabled: true                             # Włącz MySQL
  auth:
    rootPassword: "supersecret"
    database: "myapp_production"
    username: "myapp_user"
    password: "myapp_password"
  primary:
    persistence:
      enabled: true
      size: 20Gi
      storageClass: "fast-ssd"
  metrics:
    enabled: true                           # Włącz MySQL metrics

# Redis sub-chart configuration  
redis:
  enabled: true                             # Włącz Redis
  auth:
    enabled: false                          # Bez hasła (dev environment)
  master:
    persistence:
      enabled: false                        # Bez persistence (cache only)
  replica:
    replicaCount: 1

# PostgreSQL sub-chart (alternative do MySQL)
postgresql:
  enabled: false                            # Wyłączone domyślnie
  auth:
    postgresPassword: "postgres_secret"
    database: "myapp_production"
    username: "myapp_user"
    password: "myapp_password"
```

### Używanie Dependencies w Templates
```yaml
# templates/deployment.yaml - połączenie z database
apiVersion: apps/v1
kind: Deployment
# ... metadata i spec
spec:
  template:
    spec:
      containers:
      - name: {{ .Chart.Name }}
        # ... image i porty
        
        env:
        # Database connection dla MySQL
        {{- if .Values.mysql.enabled }}
        - name: DATABASE_TYPE
          value: "mysql"
        - name: DATABASE_HOST
          value: {{ include "moja-aplikacja.fullname" . }}-mysql
        - name: DATABASE_PORT
          value: "3306"
        - name: DATABASE_NAME
          value: {{ .Values.mysql.auth.database }}
        - name: DATABASE_USERNAME
          value: {{ .Values.mysql.auth.username }}
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "moja-aplikacja.fullname" . }}-mysql
              key: mysql-password
        {{- end }}
        
        # Database connection dla PostgreSQL  
        {{- if .Values.postgresql.enabled }}
        - name: DATABASE_TYPE
          value: "postgresql"
        - name: DATABASE_HOST
          value: {{ include "moja-aplikacja.fullname" . }}-postgresql
        - name: DATABASE_PORT
          value: "5432"
        - name: DATABASE_NAME
          value: {{ .Values.postgresql.auth.database }}
        - name: DATABASE_USERNAME
          value: {{ .Values.postgresql.auth.username }}
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "moja-aplikacja.fullname" . }}-postgresql
              key: postgres-password
        {{- end }}
        
        # Redis connection
        {{- if .Values.redis.enabled }}
        - name: REDIS_HOST
          value: {{ include "moja-aplikacja.fullname" . }}-redis-master
        - name: REDIS_PORT
          value: "6379"
        {{- if .Values.redis.auth.enabled }}
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "moja-aplikacja.fullname" . }}-redis
              key: redis-password
        {{- end }}
        {{- end }}
```

## 🚀 Chart Lifecycle Management

### Install, Upgrade, Rollback
```bash
# Instalacja chart
helm install moj-release ./moja-aplikacja/ \
  --namespace produkcja \
  --create-namespace \
  -f values-production.yaml

# Upgrade z nowymi wartościami
helm upgrade moj-release ./moja-aplikacja/ \
  --namespace produkcja \
  -f values-production.yaml \
  --set image.tag=v2.0.0

# Upgrade z wait (czekaj na ready)
helm upgrade moj-release ./moja-aplikacja/ \
  --wait \
  --timeout=300s \
  --namespace produkcja

# Historia release
helm history moj-release --namespace produkcja

# Rollback do poprzedniej wersji
helm rollback moj-release --namespace produkcja

# Rollback do konkretnej rewizji
helm rollback moj-release 3 --namespace produkcja

# Status release
helm status moj-release --namespace produkcja

# Lista values używanych w release
helm get values moj-release --namespace produkcja
helm get values moj-release --all --namespace produkcja  # Wszystkie values (+ domyślne)

# Uninstall
helm uninstall moj-release --namespace produkcja
```

### Hooks - Lifecycle Events
```yaml
# templates/job-migration.yaml - Job z hooks
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "moja-aplikacja.fullname" . }}-migration
  labels:
    {{- include "moja-aplikacja.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": pre-upgrade,pre-install     # Kiedy uruchomić
    "helm.sh/hook-weight": "-5"                 # Kolejność (-5 = wcześnie)
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded  # Kiedy usunąć
spec:
  template:
    metadata:
      labels:
        {{- include "moja-aplikacja.selectorLabels" . | nindent 8 }}
        job-type: migration
    spec:
      restartPolicy: Never
      containers:
      - name: migration
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        command:
        - "/bin/sh"
        - "-c"
        - |
          echo "Running database migration..."
          ./migrate.sh
          echo "Migration completed successfully"
        
        env:
        # Database connection (same as main app)
        {{- if .Values.mysql.enabled }}
        - name: DATABASE_URL
          value: "mysql://{{ .Values.mysql.auth.username }}:$(DATABASE_PASSWORD)@{{ include "moja-aplikacja.fullname" . }}-mysql:3306/{{ .Values.mysql.auth.database }}"
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "moja-aplikacja.fullname" . }}-mysql
              key: mysql-password
        {{- end }}
```

### Hook Types i Weights
```yaml
# Dostępne hook types:
# pre-install     - przed instalacją
# post-install    - po instalacji
# pre-delete      - przed usunięciem
# post-delete     - po usunięciu  
# pre-upgrade     - przed upgrade
# post-upgrade    - po upgrade
# pre-rollback    - przed rollback
# post-rollback   - po rollback

# Hook weights (kolejność wykonania):
# -10, -5, -1, 0, 1, 5, 10
# Niższe liczby = wcześniejsze wykonanie

# Hook delete policies:
# before-hook-creation  - usuń przed utworzeniem nowego hook
# hook-succeeded        - usuń po udanym wykonaniu
# hook-failed          - usuń po nieudanym wykonaniu

# Przykład complex hook:
annotations:
  "helm.sh/hook": pre-upgrade,pre-install
  "helm.sh/hook-weight": "-10"              # Pierwszy do wykonania
  "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
```

## 📊 Values Strategies - Environment Management

### Multi-Environment Values
```bash
# Struktura plików values dla różnych środowisk
moja-aplikacja/
├── values.yaml                    # Domyślne values (development)
├── values-staging.yaml            # Staging overrides
├── values-production.yaml         # Production overrides
└── values-local.yaml              # Local development

# values.yaml (base/development)
serviceName: "moja-aplikacja"
replicaCount: 1                     # Dev = 1 replica
image:
  tag: "latest"                     # Dev = latest tag
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
mysql:
  enabled: true
  auth:
    database: "myapp_dev"

# values-staging.yaml (staging overrides)
replicaCount: 2                     # Staging = 2 replicas
image:
  tag: "v1.2.3-staging"            # Staging = specific tag
resources:
  requests:
    cpu: "200m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
mysql:
  auth:
    database: "myapp_staging"
  primary:
    persistence:
      enabled: true                 # Staging = persistence

# values-production.yaml (production overrides)
replicaCount: 3                     # Production = 3 replicas  
image:
  tag: "v1.2.3"                    # Production = release tag
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "2000m"
    memory: "2Gi"
autoscaling:
  enabled: true                     # Production = autoscaling
  minReplicas: 3
  maxReplicas: 10
mysql:
  auth:
    database: "myapp_production"
  primary:
    persistence:
      enabled: true
      size: 100Gi                   # Production = bigger storage
      storageClass: "fast-ssd"
  metrics:
    enabled: true                   # Production = monitoring
```

### Environment-Specific Deployments
```bash
# Development
helm install dev-release ./moja-aplikacja/ \
  --namespace development \
  --create-namespace

# Staging  
helm install staging-release ./moja-aplikacja/ \
  --namespace staging \
  --create-namespace \
  -f values-staging.yaml

# Production
helm install prod-release ./moja-aplikacja/ \
  --namespace production \
  --create-namespace \
  -f values-production.yaml

# Upgrade production z nową wersją
helm upgrade prod-release ./moja-aplikacja/ \
  --namespace production \
  -f values-production.yaml \
  --set image.tag=v1.3.0 \
  --wait
```

## 🔐 Secrets Management w Helm

### External Secrets Integration
```yaml
# templates/external-secret.yaml - używanie External Secrets Operator
{{- if .Values.externalSecrets.enabled }}
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "moja-aplikacja.fullname" . }}-secrets
  namespace: {{ .Release.Namespace }}
spec:
  refreshInterval: {{ .Values.externalSecrets.refreshInterval | default "1h" }}
  secretStoreRef:
    name: {{ .Values.externalSecrets.secretStore }}
    kind: SecretStore               # lub ClusterSecretStore
  
  target:
    name: {{ include "moja-aplikacja.fullname" . }}-app-secrets
    creationPolicy: Owner
  
  data:
  {{- range .Values.externalSecrets.secrets }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .remoteKey }}
      {{- if .property }}
      property: {{ .property }}
      {{- end }}
  {{- end }}
{{- end }}
```

### Sealed Secrets Pattern
```yaml
# templates/sealed-secret.yaml - używanie Sealed Secrets
{{- if .Values.sealedSecrets.enabled }}
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: {{ include "moja-aplikacja.fullname" . }}-sealed-secrets
  namespace: {{ .Release.Namespace }}
spec:
  encryptedData:
    # Te wartości są zaszyfrowane przez kubeseal
    database-password: {{ .Values.sealedSecrets.databasePassword }}
    api-key: {{ .Values.sealedSecrets.apiKey }}
  template:
    metadata:
      name: {{ include "moja-aplikacja.fullname" . }}-app-secrets
      labels:
        {{- include "moja-aplikacja.labels" . | nindent 8 }}
{{- end }}
```

## 💡 Advanced Patterns i Best Practices

### Library Charts
```yaml
# Chart.yaml dla library chart
apiVersion: v2
name: common-templates                      # Nazwa library chart
description: "Wspólne templates dla aplikacji"
type: library                               # Type: library (nie application)
version: 1.0.0

# templates/_common-deployment.tpl w library chart
{{- define "common.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount | default 1 }}
  # ... wspólny template dla deployment
{{- end }}

# Użycie library chart w application chart
# Chart.yaml
dependencies:
- name: common-templates
  version: "1.0.0"
  repository: "file://../common-templates"

# templates/deployment.yaml w application chart
{{- include "common.deployment" . }}
```

### Conditional Templates z Complex Logic
```yaml
# templates/ingress.yaml - zaawansowana logika warunkowa
{{- if .Values.ingress.enabled -}}
{{- $fullName := include "moja-aplikacja.fullname" . -}}
{{- $svcPort := .Values.service.port -}}
{{- if and .Values.ingress.className (not (hasKey .Values.ingress.annotations "kubernetes.io/ingress.class")) }}
  {{- $_ := set .Values.ingress.annotations "kubernetes.io/ingress.class" .Values.ingress.className}}
{{- end }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $fullName }}
  labels:
    {{- include "moja-aplikacja.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if and .Values.ingress.className (semverCompare ">=1.18-0" .Capabilities.KubeVersion.GitVersion) }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            {{- if and .pathType (semverCompare ">=1.18-0" $.Capabilities.KubeVersion.GitVersion) }}
            pathType: {{ .pathType }}
            {{- end }}
            backend:
              {{- if semverCompare ">=1.19-0" $.Capabilities.KubeVersion.GitVersion }}
              service:
                name: {{ $fullName }}
                port:
                  number: {{ $svcPort }}
              {{- else }}
              serviceName: {{ $fullName }}
              servicePort: {{ $svcPort }}
              {{- end }}
          {{- end }}
    {{- end }}
{{- end }}
```

---
*Praktyczne wzorce rozwoju Helm Charts - od podstaw do advanced patterns! 🛠️*