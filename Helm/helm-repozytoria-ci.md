# Helm - Repozytoria i CI/CD Integration

## 📦 Helm Repositories - Zarządzanie Pakietami

### Publiczne Repozytoria Helm
```bash
# Dodawanie popularnych repozytoriów
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://charts.helm.sh/stable
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts

# Aktualizacja repozytoriów
helm repo update

# Lista dodanych repozytoriów
helm repo list

# Wyszukiwanie chart w repozytoriach
helm search repo mysql
helm search repo nginx
helm search repo prometheus

# Informacje o konkretnym chart
helm show chart bitnami/mysql
helm show values bitnami/mysql
helm show readme bitnami/mysql

# Instalacja z repozytorium
helm install my-mysql bitnami/mysql \
  --version 9.4.0 \
  --namespace database \
  --create-namespace \
  -f mysql-values.yaml
```

### GitLab Package Registry - Private Helm Repository
```yaml
# .gitlab-ci.yml - publikowanie chart do GitLab Package Registry
stages:
  - build
  - package
  - deploy

variables:
  CHART_NAME: "microservice"
  CHART_VERSION: "${CI_PIPELINE_ID}"
  REGISTRY_URL: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/helm/stable"

# Build i package chart
package-chart:
  stage: package
  image: alpine/helm:latest
  before_script:
    # Instalacja curl dla GitLab API
    - apk add --no-cache curl
  script:
    # Update chart version z CI pipeline ID
    - sed -i "s/version: .*/version: ${CHART_VERSION}/" Chart.yaml
    
    # Lint chart przed package
    - helm lint .
    
    # Package chart
    - helm package .
    
    # Upload do GitLab Package Registry
    - |
      curl --request POST \
           --form "chart=@${CHART_NAME}-${CHART_VERSION}.tgz" \
           --user gitlab-ci-token:${CI_JOB_TOKEN} \
           "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/helm/api/stable/charts"
  
  artifacts:
    paths:
      - "*.tgz"
    expire_in: 1 week
  
  only:
    - main
    - develop

# Deployment używający chart z Package Registry
deploy-service:
  stage: deploy
  image: alpine/helm:latest
  before_script:
    # Dodaj GitLab Package Registry jako repo
    - helm repo add --username gitlab-ci-token --password ${CI_JOB_TOKEN} 
        microservices-charts "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/helm/stable"
    - helm repo update
  script:
    # Deploy używając chart z registry
    - helm upgrade --install ${SERVICE_NAME} microservices-charts/microservice \
        --version ${CHART_VERSION} \
        --namespace ${NAMESPACE} \
        --create-namespace \
        -f values-${SERVICE_NAME}.yaml \
        --set image.repository="${CI_REGISTRY_IMAGE}" \
        --set image.tag="${CI_COMMIT_SHORT_SHA}"
  environment:
    name: production
    url: https://api.krolikowski.cloud
  only:
    - main
```

### ChartMuseum - Self-Hosted Repository
```bash
# Instalacja ChartMuseum (self-hosted Helm repo)
helm repo add chartmuseum https://chartmuseum.github.io/charts
helm install chartmuseum chartmuseum/chartmuseum \
  --set env.open.DISABLE_API=false \
  --set env.open.ALLOW_OVERWRITE=true \
  --set persistence.enabled=true \
  --set persistence.size=10Gi

# Upload chart do ChartMuseum
curl --data-binary "@mychart-1.0.0.tgz" http://chartmuseum-url/api/charts

# Helm push plugin (alternatywnie)
helm plugin install https://github.com/chartmuseum/helm-push
helm cm-push mychart-1.0.0.tgz chartmuseum
```

## 🚀 GitLab CI/CD Integration - Production Patterns

### Multi-Service Architecture (BajkoBoot Pattern)
```yaml
# .gitlab-ci.yml dla microservice z shared chart
stages:
  - build
  - test  
  - deploy

variables:
  SERVICE_NAME: "user-api"                   # Nazwa serwisu
  NAMESPACE: "bajkoboot"                     # Target namespace
  CHART_PROJECT_ID: "12345"                 # ID projektu z universal chart
  CHART_NAME: "microservice"                # Nazwa universal chart
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

# Build Docker image
build-image:
  stage: build
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    # Multi-stage Docker build dla Python FastAPI
    - docker build 
        --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') 
        --build-arg VCS_REF=$CI_COMMIT_SHORT_SHA 
        --build-arg VERSION=$CI_COMMIT_REF_NAME 
        -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA 
        -t $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main
    - develop

# Security scan
scan-image:
  stage: test
  image: aquasec/trivy:latest
  script:
    # Scan Docker image for vulnerabilities
    - trivy image --exit-code 0 --severity HIGH,CRITICAL $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
  allow_failure: true
  only:
    - main
    - develop

# Deploy do Kubernetes
deploy:
  stage: deploy
  image: alpine/helm:3.12.0
  before_script:
    # Konfiguracja kubectl
    - echo $KUBECONFIG_FILE | base64 -d > kubeconfig
    - export KUBECONFIG=kubeconfig
    - kubectl config current-context
    
    # Dodaj GitLab Helm repository
    - helm repo add --username gitlab-ci-token --password $CI_JOB_TOKEN 
        microservices-charts "${CI_API_V4_URL}/projects/${CHART_PROJECT_ID}/packages/helm/stable"
    - helm repo update
    
    # Debug: sprawdź dostępne charts
    - helm search repo microservices-charts
    
  script:
    # Ensure namespace exists
    - kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    
    # Create Docker registry secret
    - kubectl create secret docker-registry gitlabregistry-secret 
        --docker-server=$CI_REGISTRY 
        --docker-username=$CI_DEPLOY_USER 
        --docker-password=$CI_DEPLOY_PASSWORD 
        --namespace=${NAMESPACE} 
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Pull i extract chart (fallback method)
    - helm pull microservices-charts/${CHART_NAME} --untar || {
        echo "Failed to pull from registry, trying git clone fallback...";
        apk add --no-cache git;
        git clone https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/group/microservices-charts.git;
        cd microservices-charts;
      }
    
    # Deploy aplikacji z Helm
    - helm upgrade --install ${SERVICE_NAME} ./${CHART_NAME} 
        --namespace=${NAMESPACE} 
        -f values-${SERVICE_NAME}.yaml 
        --set image.repository="${CI_REGISTRY_IMAGE}" 
        --set image.tag="${CI_COMMIT_SHORT_SHA}"
        --set fullnameOverride="${SERVICE_NAME}"
        --wait 
        --timeout=600s
    
    # Verify deployment
    - kubectl get pods -l app=${SERVICE_NAME} -n ${NAMESPACE}
    - kubectl rollout status deployment/${SERVICE_NAME} -n ${NAMESPACE}
    
  environment:
    name: production
    url: https://api.k3s.krolikowski.cloud:7443
  
  only:
    - main

# Rollback job (manual)
rollback:
  stage: deploy
  image: alpine/helm:3.12.0
  before_script:
    - echo $KUBECONFIG_FILE | base64 -d > kubeconfig
    - export KUBECONFIG=kubeconfig
  script:
    # Show release history
    - helm history ${SERVICE_NAME} -n ${NAMESPACE}
    
    # Rollback to previous version
    - helm rollback ${SERVICE_NAME} -n ${NAMESPACE}
    
    # Verify rollback
    - kubectl rollout status deployment/${SERVICE_NAME} -n ${NAMESPACE}
    
  when: manual
  environment:
    name: production
  only:
    - main
```

### Values per Environment Pattern
```yaml
# values-user-api.yaml (production values dla user-api)
# Derived from BajkoBoot experience

serviceName: "user-api"
fullnameOverride: "user-api"

# Image configuration
image:
  repository: registry.gitlab.com/vnettechnologies/bajkobot/user-api
  tag: latest                               # Override w CI/CD
  pullPolicy: Always

# Scaling configuration  
replicaCount: 2                             # Production HA
autoscaling:
  enabled: false                            # Możliwość włączenia w przyszłości
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70

# Service configuration
service:
  type: ClusterIP
  port: 80                                  # External port
  targetPort: 8000                          # FastAPI port
  
# Health checks dla FastAPI
healthCheck:
  enabled: true
  path: "/"                                 # Health endpoint
  port: 8000
  livenessProbe:
    initialDelaySeconds: 30                 # Wait for FastAPI startup
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
  readinessProbe:
    initialDelaySeconds: 10
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 2

# Environment variables
env:
  - name: PYTHONUNBUFFERED
    value: "1"
  - name: ENVIRONMENT
    value: "production"
  - name: SERVICE_NAME
    value: "user-api"
  - name: PORT
    value: "8000"

# Environment variables from secrets
envFrom:
  - secretRef:
      name: app-secrets                     # Database credentials

# Resources for production
resources:
  requests:
    cpu: "200m"
    memory: "256Mi"
  limits:
    cpu: "1000m"
    memory: "512Mi"

# Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 2001

# Pod annotations dla monitoring
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8000"
  prometheus.io/path: "/metrics"

# Image pull secrets
imagePullSecrets:
  - name: gitlabregistry-secret

# Node selection (opcjonalne)
nodeSelector: {}
tolerations: []
affinity: {}

---
# values-notifier-api.yaml (production values dla notifier-api)
serviceName: "notifier-api"
fullnameOverride: "notifier-api"

image:
  repository: registry.gitlab.com/vnettechnologies/bajkobot/notifier-api
  tag: latest
  pullPolicy: Always

replicaCount: 2

service:
  type: ClusterIP
  port: 80
  targetPort: 8000

# Environment variables specificzne dla notifier
env:
  - name: PYTHONUNBUFFERED
    value: "1"
  - name: SERVICE_NAME
    value: "notifier-api"
  - name: USER_API_SECURE_ENDPOINT
    value: "http://user-api.bajkoboot.svc.cluster.local:80/users/changePassword"

envFrom:
  - secretRef:
      name: notifier-secrets               # SMTP, OneSignal credentials

healthCheck:
  enabled: true
  path: "/"
  port: 8000
  livenessProbe:
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
  readinessProbe:
    initialDelaySeconds: 10
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 2

resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"

securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 2001

imagePullSecrets:
  - name: gitlabregistry-secret
```

## 🔄 Advanced CI/CD Patterns

### Multi-Environment Deployment Strategy
```yaml
# .gitlab-ci.yml - Advanced deployment z multiple environments
stages:
  - build
  - test
  - deploy-dev
  - deploy-staging
  - deploy-production

variables:
  SERVICE_NAME: "user-api"
  CHART_PROJECT_ID: "12345"
  CHART_NAME: "microservice"

# Build stage (jak wcześniej)
build-image:
  stage: build
  # ... build script

# Deploy Development (automatyczny)
deploy-dev:
  stage: deploy-dev
  extends: .deploy-template
  variables:
    ENVIRONMENT: "development"
    NAMESPACE: "dev-bajkoboot"
    VALUES_FILE: "values-${SERVICE_NAME}-dev.yaml"
  environment:
    name: development
    url: https://dev-api.krolikowski.cloud
  only:
    - develop

# Deploy Staging (automatyczny na main)
deploy-staging:
  stage: deploy-staging
  extends: .deploy-template
  variables:
    ENVIRONMENT: "staging"
    NAMESPACE: "staging-bajkoboot"
    VALUES_FILE: "values-${SERVICE_NAME}-staging.yaml"
  environment:
    name: staging
    url: https://staging-api.krolikowski.cloud
  only:
    - main

# Deploy Production (manual)
deploy-production:
  stage: deploy-production
  extends: .deploy-template
  variables:
    ENVIRONMENT: "production"
    NAMESPACE: "bajkoboot"
    VALUES_FILE: "values-${SERVICE_NAME}.yaml"
  environment:
    name: production
    url: https://api.k3s.krolikowski.cloud:7443
  when: manual                              # Manual approval required
  only:
    - main

# Template dla deployment
.deploy-template:
  image: alpine/helm:3.12.0
  before_script:
    # Setup kubectl
    - echo $KUBECONFIG_FILE | base64 -d > kubeconfig
    - export KUBECONFIG=kubeconfig
    
    # Add Helm repo
    - helm repo add --username gitlab-ci-token --password $CI_JOB_TOKEN 
        microservices-charts "${CI_API_V4_URL}/projects/${CHART_PROJECT_ID}/packages/helm/stable"
    - helm repo update
    
  script:
    # Pre-deployment checks
    - kubectl cluster-info
    - kubectl get nodes
    
    # Namespace setup
    - kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    
    # Registry secret
    - kubectl create secret docker-registry gitlabregistry-secret 
        --docker-server=$CI_REGISTRY 
        --docker-username=$CI_DEPLOY_USER 
        --docker-password=$CI_DEPLOY_PASSWORD 
        --namespace=${NAMESPACE} 
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Pull chart
    - helm pull microservices-charts/${CHART_NAME} --untar
    
    # Deploy
    - helm upgrade --install ${SERVICE_NAME} ./${CHART_NAME} 
        --namespace=${NAMESPACE} 
        -f ${VALUES_FILE}
        --set image.repository="${CI_REGISTRY_IMAGE}" 
        --set image.tag="${CI_COMMIT_SHORT_SHA}"
        --set environment="${ENVIRONMENT}"
        --wait 
        --timeout=600s
    
    # Post-deployment verification
    - kubectl get pods -l app=${SERVICE_NAME} -n ${NAMESPACE}
    - kubectl rollout status deployment/${SERVICE_NAME} -n ${NAMESPACE}
    
    # Health check
    - sleep 30  # Wait for app startup
    - kubectl exec -n ${NAMESPACE} deployment/${SERVICE_NAME} -- curl -f http://localhost:8000/ || echo "Health check failed"
```

### Blue-Green Deployment z Helm
```yaml
# Blue-Green deployment strategy
deploy-blue-green:
  stage: deploy
  image: alpine/helm:3.12.0
  script:
    # Determine current and next environment
    - CURRENT_ENV=$(kubectl get service ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "blue")
    - if [ "$CURRENT_ENV" = "blue" ]; then NEXT_ENV="green"; else NEXT_ENV="blue"; fi
    - echo "Current environment: $CURRENT_ENV, Deploying to: $NEXT_ENV"
    
    # Deploy to next environment
    - helm upgrade --install ${SERVICE_NAME}-${NEXT_ENV} ./${CHART_NAME} 
        --namespace=${NAMESPACE} 
        -f ${VALUES_FILE}
        --set image.tag="${CI_COMMIT_SHORT_SHA}"
        --set version="${NEXT_ENV}"
        --set fullnameOverride="${SERVICE_NAME}-${NEXT_ENV}"
        --wait
    
    # Health check new deployment
    - kubectl wait --for=condition=ready pod -l app=${SERVICE_NAME},version=${NEXT_ENV} -n ${NAMESPACE} --timeout=300s
    
    # Switch traffic (update main service selector)
    - kubectl patch service ${SERVICE_NAME} -n ${NAMESPACE} -p '{"spec":{"selector":{"version":"'${NEXT_ENV}'"}}}'
    
    # Cleanup old deployment (after verification)
    - sleep 60  # Grace period
    - helm uninstall ${SERVICE_NAME}-${CURRENT_ENV} -n ${NAMESPACE} || echo "Old deployment not found"
  
  when: manual
  environment:
    name: production
```

### Canary Deployment Pattern
```yaml
# Canary deployment z traffic splitting
deploy-canary:
  stage: deploy
  script:
    # Deploy canary version (10% traffic)
    - helm upgrade --install ${SERVICE_NAME}-canary ./${CHART_NAME} 
        --namespace=${NAMESPACE} 
        -f ${VALUES_FILE}
        --set image.tag="${CI_COMMIT_SHORT_SHA}"
        --set replicaCount=1                # Fewer replicas for canary
        --set fullnameOverride="${SERVICE_NAME}-canary"
        --set version="canary"
        --wait
    
    # Update Istio VirtualService dla traffic splitting (jeśli używasz Istio)
    - kubectl apply -f - <<EOF
      apiVersion: networking.istio.io/v1beta1
      kind: VirtualService
      metadata:
        name: ${SERVICE_NAME}-vs
        namespace: ${NAMESPACE}
      spec:
        hosts:
        - ${SERVICE_NAME}
        http:
        - match:
          - headers:
              canary:
                exact: "true"
          route:
          - destination:
              host: ${SERVICE_NAME}-canary
              port:
                number: 80
        - route:
          - destination:
              host: ${SERVICE_NAME}
              port:
                number: 80
            weight: 90
          - destination:
              host: ${SERVICE_NAME}-canary
              port:
                number: 80
            weight: 10
      EOF
  
  when: manual

# Promote canary to production
promote-canary:
  stage: deploy
  script:
    # Update main deployment with canary image
    - helm upgrade ${SERVICE_NAME} ./${CHART_NAME} 
        --namespace=${NAMESPACE} 
        --reuse-values
        --set image.tag="${CI_COMMIT_SHORT_SHA}"
        --wait
    
    # Remove canary deployment
    - helm uninstall ${SERVICE_NAME}-canary -n ${NAMESPACE}
    
    # Update VirtualService (100% traffic to main)
    - kubectl delete virtualservice ${SERVICE_NAME}-vs -n ${NAMESPACE}
  
  when: manual
  needs: ["deploy-canary"]
```

## 🔧 Monitoring i Observability Integration

### Prometheus Monitoring Setup
```yaml
# templates/servicemonitor.yaml - Prometheus integration
{{- if .Values.monitoring.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "moja-aplikacja.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "moja-aplikacja.labels" . | nindent 4 }}
    {{- with .Values.monitoring.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  selector:
    matchLabels:
      {{- include "moja-aplikacja.selectorLabels" . | nindent 6 }}
  endpoints:
  - port: http
    path: {{ .Values.monitoring.path | default "/metrics" }}
    interval: {{ .Values.monitoring.interval | default "30s" }}
    scrapeTimeout: {{ .Values.monitoring.scrapeTimeout | default "10s" }}
    {{- if .Values.monitoring.metricRelabelings }}
    metricRelabelings:
    {{- toYaml .Values.monitoring.metricRelabelings | nindent 4 }}
    {{- end }}
{{- end }}

---
# values.yaml - monitoring configuration
monitoring:
  enabled: true                             # Włącz Prometheus monitoring
  path: "/metrics"                          # Metrics endpoint
  interval: "30s"                           # Scraping interval
  scrapeTimeout: "10s"                      # Scraping timeout
  labels:                                   # Dodatkowe labels dla ServiceMonitor
    release: prometheus
  metricRelabelings: []                     # Metric relabeling rules
```

### Grafana Dashboard jako Code
```yaml
# templates/grafana-dashboard.yaml
{{- if .Values.grafana.dashboard.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "moja-aplikacja.fullname" . }}-dashboard
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "moja-aplikacja.labels" . | nindent 4 }}
    grafana_dashboard: "1"                  # Label for Grafana discovery
data:
  dashboard.json: |
    {
      "dashboard": {
        "id": null,
        "title": "{{ .Values.serviceName | title }} - Application Metrics",
        "tags": ["kubernetes", "{{ .Values.serviceName }}"],
        "timezone": "UTC",
        "panels": [
          {
            "title": "Request Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(http_requests_total{job=\"{{ include \"moja-aplikacja.fullname\" . }}\"}[5m])",
                "legendFormat": "{{ "{{" }}method{{ "}}" }} {{ "{{" }}status{{ "}}" }}"
              }
            ]
          },
          {
            "title": "Response Time",
            "type": "graph", 
            "targets": [
              {
                "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job=\"{{ include \"moja-aplikacja.fullname\" . }}\"}[5m]))",
                "legendFormat": "95th percentile"
              }
            ]
          },
          {
            "title": "Error Rate",
            "type": "singlestat",
            "targets": [
              {
                "expr": "rate(http_requests_total{job=\"{{ include \"moja-aplikacja.fullname\" . }}\",status=~\"5..\"}[5m]) / rate(http_requests_total{job=\"{{ include \"moja-aplikacja.fullname\" . }}\"}[5m]) * 100",
                "legendFormat": "Error Rate %"
              }
            ]
          }
        ],
        "time": {
          "from": "now-1h",
          "to": "now"
        },
        "refresh": "30s"
      }
    }
{{- end }}

---
# values.yaml
grafana:
  dashboard:
    enabled: true                           # Create Grafana dashboard
```

## 🚨 Troubleshooting Helm w CI/CD

### Common CI/CD Issues i Solutions
```bash
# 1. Helm repo authentication issues
# Solution: Sprawdź CI/CD variables
echo "Registry URL: ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/helm/stable"
echo "Token available: $(echo $CI_JOB_TOKEN | wc -c)"

# 2. Chart not found in registry
# Debug commands w CI/CD:
helm search repo microservices-charts --debug
curl -H "Authorization: Bearer ${CI_JOB_TOKEN}" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages"

# 3. Kubernetes context issues
# Verify kubectl configuration:
kubectl config current-context
kubectl cluster-info
kubectl auth can-i create pods --namespace=${NAMESPACE}

# 4. Timeout podczas deployment
# Zwiększ timeout i dodaj debug:
helm upgrade --install ${SERVICE_NAME} ./chart \
  --timeout=900s \
  --wait \
  --debug \
  --atomic                                  # Rollback on failure

# 5. Image pull errors
# Sprawdź registry secret:
kubectl get secret gitlabregistry-secret -n ${NAMESPACE} -o yaml
kubectl describe pod failing-pod -n ${NAMESPACE}

# 6. Values file not found
# Debug values files w CI/CD:
ls -la values-*.yaml
cat values-${SERVICE_NAME}.yaml
```

### Helm Deployment Verification Script
```bash
# scripts/verify-deployment.sh - verification script dla CI/CD
#!/bin/bash
set -e

NAMESPACE=${1:-default}
SERVICE_NAME=${2:-app}
TIMEOUT=${3:-300}

echo "Verifying deployment: ${SERVICE_NAME} in namespace: ${NAMESPACE}"

# 1. Check deployment status
echo "Checking deployment rollout status..."
kubectl rollout status deployment/${SERVICE_NAME} -n ${NAMESPACE} --timeout=${TIMEOUT}s

# 2. Check pod health
echo "Checking pod health..."
kubectl wait --for=condition=ready pod -l app=${SERVICE_NAME} -n ${NAMESPACE} --timeout=${TIMEOUT}s

# 3. Check service endpoints
echo "Checking service endpoints..."
ENDPOINTS=$(kubectl get endpoints ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.subsets[0].addresses[*].ip}' 2>/dev/null || echo "")
if [ -z "$ENDPOINTS" ]; then
    echo "ERROR: No endpoints found for service ${SERVICE_NAME}"
    exit 1
fi
echo "Service endpoints: $ENDPOINTS"

# 4. Health check via service
echo "Performing health check..."
kubectl run health-check-${RANDOM} \
  --image=curlimages/curl:8.0.1 \
  --rm -i --restart=Never \
  --namespace=${NAMESPACE} \
  -- curl -f -m 10 http://${SERVICE_NAME}:80/health

echo "Deployment verification completed successfully!"

# Użycie w CI/CD:
# script:
#   - ./scripts/verify-deployment.sh ${NAMESPACE} ${SERVICE_NAME} 600
```

## 💡 Best Practices dla Production

### ✅ Security Best Practices
```yaml
# 1. Use specific image tags (nie :latest w production)
image:
  tag: "v1.2.3"                            # Specific version

# 2. Resource limits zawsze
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"

# 3. Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false

# 4. Network policies
networkPolicy:
  enabled: true
  ingress:
    - from:
      - podSelector:
          matchLabels:
            app: frontend
      ports:
      - protocol: TCP
        port: 8080
```

### ✅ Operational Best Practices
```yaml
# 1. Zawsze używaj health checks
healthCheck:
  enabled: true
  path: "/health"
  livenessProbe:
    initialDelaySeconds: 30
    failureThreshold: 3
  readinessProbe:
    initialDelaySeconds: 5
    failureThreshold: 2

# 2. Monitoring i observability
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"

# 3. Graceful shutdown
terminationGracePeriodSeconds: 30

# 4. Pod disruption budgets dla HA
podDisruptionBudget:
  enabled: true
  minAvailable: 1
```

### ✅ CI/CD Best Practices
```bash
# 1. Zawsze używaj --wait i --timeout
helm upgrade --install app ./chart --wait --timeout=600s

# 2. Atomic deployments (rollback on failure)
helm upgrade --install app ./chart --atomic

# 3. Dry run przed production
helm upgrade --install app ./chart --dry-run

# 4. Backup przed major updates
helm get values app > backup-values.yaml

# 5. Verify po deployment
kubectl rollout status deployment/app
kubectl get pods -l app=myapp
```

---
*Production-ready Helm z GitLab CI/CD - od repozytoriów do advanced deployment strategies! 🚀*