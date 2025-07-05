# Kubernetes - Zarządzanie i Operacje

## 🔄 Zarządzanie Klastrem

### Cykl Życia Klastra
```bash
# Sprawdzenie wersji i stanu klastra
kubectl version --short                        # Wersje klienta i serwera API
kubectl cluster-info                           # Podstawowe informacje o klastrze
kubectl get componentstatuses                  # Status komponentów systemu (deprecated w 1.19+)

# Informacje o węzłach
kubectl get nodes                              # Lista węzłów
kubectl get nodes -o wide                     # Szczegółowe informacje (IP, OS, runtime)
kubectl describe nodes                        # Pełny opis wszystkich węzłów
kubectl describe node nazwa-wezla             # Szczegóły konkretnego węzła

# Zasoby systemowe
kubectl get pods -n kube-system               # Pody systemowe
kubectl get all -n kube-system               # Wszystkie zasoby systemowe
kubectl top nodes                            # Wykorzystanie CPU/memory węzłów
```

### Aktualizacja Klastra
```bash
# Planowanie aktualizacji (dla kubeadm)
sudo kubeadm upgrade plan                     # Sprawdź dostępne wersje

# Aktualizacja węzła sterującego
sudo kubeadm upgrade apply v1.28.0           # Konkretna wersja
sudo systemctl restart kubelet               # Restart kubelet po aktualizacji

# Aktualizacja węzłów roboczych (jeden na raz)
kubectl drain nazwa-wezla --ignore-daemonsets --delete-emptydir-data --force
# Na węźle:
sudo kubeadm upgrade node
sudo systemctl restart kubelet
# Powrót do klastra:
kubectl uncordon nazwa-wezla

# Sprawdzenie po aktualizacji
kubectl get nodes                            # Sprawdź wersje węzłów
kubectl get pods -n kube-system             # Sprawdź czy system pods działają
```

### Maintenance Węzłów
```bash
# Przygotowanie węzła do maintenance
kubectl cordon nazwa-wezla                   # Zablokuj nowe pody na węźle
kubectl get nodes                           # Sprawdź status SchedulingDisabled

# Przeniesienie podów z węzła
kubectl drain nazwa-wezla \
  --ignore-daemonsets \                      # Ignoruj DaemonSet pods (pozostaną)
  --delete-emptydir-data \                   # Usuń pody z emptyDir volumes
  --force \                                  # Wymuś usunięcie "orphaned" pods
  --grace-period=300                         # Czas na graceful shutdown (sekundy)

# Sprawdzenie czy węzeł jest pusty
kubectl get pods --all-namespaces -o wide | grep nazwa-wezla

# Po maintenance - przywróć węzeł
kubectl uncordon nazwa-wezla                # Zezwól na nowe pody

# Sprawdzenie czy węzeł przyjmuje nowe pody
kubectl get nodes                           # Status powinien być Ready
```

## 🎯 Skalowanie Aplikacji

### Manualne Skalowanie
```bash
# Skalowanie Deployment
kubectl scale deployment nazwa-deployment --replicas=5 -n produkcja
kubectl scale deployment nazwa-deployment --replicas=0 -n produkcja  # "Wyłączenie" aplikacji

# Skalowanie StatefulSet
kubectl scale statefulset nazwa-statefulset --replicas=3 -n dane

# Skalowanie ReplicaSet (rzadko używane bezpośrednio)
kubectl scale replicaset nazwa-rs --replicas=2 -n produkcja

# Sprawdzenie statusu skalowania
kubectl get deployment nazwa-deployment -n produkcja
kubectl rollout status deployment/nazwa-deployment -n produkcja

# Informacje o replicas
kubectl get rs -n produkcja                 # ReplicaSets i ich replicas
kubectl describe deployment nazwa-deployment -n produkcja | grep Replicas
```

### Horizontal Pod Autoscaler (HPA)
```yaml
# HPA automatycznie skaluje na podstawie metryk
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: aplikacja-hpa                       # Nazwa HPA
  namespace: produkcja
spec:
  scaleTargetRef:                           # Cel skalowania
    apiVersion: apps/v1
    kind: Deployment                        # Typ obiektu (Deployment/StatefulSet)
    name: nazwa-deployment                  # Nazwa deployment do skalowania
  
  minReplicas: 2                            # Minimum replik (zawsze)
  maxReplicas: 10                           # Maksimum replik
  
  metrics:                                  # Metryki do monitorowania
  # CPU utilization
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70              # Skaluj gdy CPU > 70%
  
  # Memory utilization  
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80              # Skaluj gdy Memory > 80%
  
  # Custom metrics (jeśli masz metrics server z custom metrics)
  - type: Pods
    pods:
      metric:
        name: requests_per_second           # Custom metrika
      target:
        type: AverageValue
        averageValue: "100"                 # 100 requests/second per pod
  
  # External metrics (np. SQS queue length)
  - type: External
    external:
      metric:
        name: queue_length
        selector:
          matchLabels:
            queue: "work-queue"
      target:
        type: Value
        value: "10"                         # Skaluj gdy kolejka > 10 messages
  
  # Behavior - kontrola jak szybko skalować
  behavior:
    scaleUp:                                # Skalowanie w górę
      stabilizationWindowSeconds: 60       # Czekaj 60s przed kolejnym scale up
      policies:
      - type: Percent
        value: 100                          # Maksymalnie 100% więcej pods na raz
        periodSeconds: 15                   # Co 15 sekund
      - type: Pods
        value: 2                            # Lub maksymalnie 2 nowe pods na raz
        periodSeconds: 60                   # Co minutę
      selectPolicy: Min                     # Wybierz mniejszą wartość
    
    scaleDown:                              # Skalowanie w dół
      stabilizationWindowSeconds: 300      # Czekaj 5 minut przed scale down
      policies:
      - type: Percent
        value: 10                           # Maksymalnie 10% mniej pods na raz
        periodSeconds: 60                   # Co minutę
      - type: Pods
        value: 1                            # Lub maksymalnie 1 pod mniej na raz
        periodSeconds: 60
      selectPolicy: Min                     # Wybierz mniejszą wartość (bezpieczniej)
```

### HPA Operations
```bash
# Tworzenie HPA z kubectl
kubectl autoscale deployment nazwa-deployment \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n produkcja

# Sprawdzenie statusu HPA
kubectl get hpa -n produkcja
kubectl describe hpa aplikacja-hpa -n produkcja

# Szczegółowe metryki HPA
kubectl get hpa aplikacja-hpa -n produkcja -o yaml

# Historia skalowania
kubectl get events --sort-by='.lastTimestamp' -n produkcja | grep HorizontalPodAutoscaler

# Debug HPA issues
kubectl describe hpa aplikacja-hpa -n produkcja | grep -A 10 Conditions
kubectl top pods -n produkcja               # Sprawdź obecne wykorzystanie CPU/memory

# Usunięcie HPA
kubectl delete hpa aplikacja-hpa -n produkcja
```

### Vertical Pod Autoscaler (VPA)
```yaml
# VPA automatycznie dostosowuje resource requests/limits
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: aplikacja-vpa
  namespace: produkcja
spec:
  targetRef:                                # Cel VPA
    apiVersion: apps/v1
    kind: Deployment
    name: nazwa-deployment
  
  updatePolicy:
    updateMode: "Auto"                      # Auto/Initial/Off
    # Auto = automatycznie aktualizuj running pods
    # Initial = ustaw tylko przy tworzeniu nowych pods
    # Off = tylko rekomendacje, nie aktualizuj
  
  resourcePolicy:                           # Ograniczenia VPA
    containerPolicies:
    - containerName: app-container          # Nazwa kontenera
      maxAllowed:                           # Maksymalne wartości
        cpu: 2                              # Max 2 CPU cores
        memory: 4Gi                         # Max 4GB RAM
      minAllowed:                           # Minimalne wartości
        cpu: 100m                           # Min 100 millicores
        memory: 128Mi                       # Min 128MB RAM
      controlledResources:                  # Co kontrolować
      - cpu
      - memory
      controlledValues: RequestsAndLimits   # RequestsOnly/RequestsAndLimits
```

### VPA Operations
```bash
# Sprawdzenie VPA
kubectl get vpa -n produkcja
kubectl describe vpa aplikacja-vpa -n produkcja

# Rekomendacje VPA
kubectl get vpa aplikacja-vpa -n produkcja -o yaml | grep -A 20 recommendation

# Historia zmian VPA
kubectl get events --sort-by='.lastTimestamp' -n produkcja | grep VerticalPodAutoscaler
```

## 📊 Monitoring i Observability

### Podstawowe Metryki Kubernetes
```bash
# Resource utilization overview
kubectl top nodes                           # CPU/Memory węzłów
kubectl top pods --all-namespaces          # CPU/Memory wszystkich pods
kubectl top pods -n produkcja --sort-by=cpu    # Top CPU consumers
kubectl top pods -n produkcja --sort-by=memory # Top memory consumers

# Detailed resource info
kubectl describe nodes | grep -A 5 "Allocated resources"
kubectl describe quota --all-namespaces    # Resource quotas usage

# Cluster capacity analysis
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.capacity.cpu}{"\t"}{.status.capacity.memory}{"\n"}{end}'
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.allocatable.cpu}{"\t"}{.status.allocatable.memory}{"\n"}{end}'
```

### Prometheus Integration
```yaml
# ServiceMonitor dla aplikacji (jeśli używasz Prometheus Operator)
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: aplikacja-metrics
  namespace: produkcja
  labels:
    app: moja-aplikacja
spec:
  selector:
    matchLabels:
      app: moja-aplikacja                   # Selektor service z metrykami
  endpoints:
  - port: metrics                           # Port name w service
    path: /metrics                          # Ścieżka do metryk
    interval: 30s                           # Częstotliwość scraping
    scrapeTimeout: 10s                      # Timeout dla scraping
  namespaceSelector:
    matchNames:
    - produkcja                             # Namespace gdzie szukać services
```

### Health Checks Configuration
```yaml
# Zaawansowana konfiguracja health checks
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aplikacja-z-health-checks
spec:
  replicas: 3
  selector:
    matchLabels:
      app: moja-aplikacja
  template:
    metadata:
      labels:
        app: moja-aplikacja
    spec:
      containers:
      - name: app
        image: nginx:1.25-alpine
        
        # Startup Probe - sprawdza czy aplikacja się uruchomiła
        startupProbe:
          httpGet:
            path: /startup                  # Endpoint dla startup check
            port: 8080
          initialDelaySeconds: 10           # Czekaj 10s przed pierwszym check
          periodSeconds: 5                  # Sprawdzaj co 5s
          timeoutSeconds: 3                 # Timeout po 3s
          failureThreshold: 30              # 30 failures = 150s na startup
          successThreshold: 1               # 1 success = aplikacja gotowa
        
        # Liveness Probe - czy aplikacja nadal żyje
        livenessProbe:
          httpGet:
            path: /health                   # Health endpoint
            port: 8080
            httpHeaders:                    # Custom headers
            - name: User-Agent
              value: "k8s-liveness-probe"
          initialDelaySeconds: 30           # Pierwszy check po 30s
          periodSeconds: 10                 # Co 10 sekund
          timeoutSeconds: 5                 # Timeout 5s
          failureThreshold: 3               # 3 failures = restart
          successThreshold: 1               # 1 success = healthy
        
        # Readiness Probe - czy aplikacja gotowa na ruch
        readinessProbe:
          httpGet:
            path: /ready                    # Readiness endpoint  
            port: 8080
          initialDelaySeconds: 5            # Szybsze niż liveness
          periodSeconds: 5                  # Częściej niż liveness
          timeoutSeconds: 3                 # Krótszy timeout
          failureThreshold: 2               # Szybciej usuń z service
          successThreshold: 1               # 1 success = ready for traffic
        
        # Alternative probe types:
        # TCP Socket probe
        # livenessProbe:
        #   tcpSocket:
        #     port: 8080
        #   initialDelaySeconds: 30
        #   periodSeconds: 10
        
        # Command/script probe  
        # livenessProbe:
        #   exec:
        #     command:
        #     - /bin/sh
        #     - -c
        #     - "curl -f http://localhost:8080/health || exit 1"
        #   initialDelaySeconds: 30
        #   periodSeconds: 10
```

### Application Performance Monitoring
```bash
# Custom metrics exposure (jeśli aplikacja exportuje metryki)
kubectl port-forward svc/moja-aplikacja 9090:9090 -n produkcja &

# Pobierz metryki aplikacji
curl http://localhost:9090/metrics

# Filtruj konkretne metryki
curl http://localhost:9090/metrics | grep -E "(http_requests|response_time|error_rate)"

# Sprawdź health endpoints
curl http://localhost:8080/health
curl http://localhost:8080/ready
curl http://localhost:8080/metrics

kill %1  # Stop port forwarding
```

## 💾 Backup i Disaster Recovery

### ETCD Backup (dla kubeadm klastrów)
```bash
# Backup ETCD database
sudo ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot-$(date +%Y%m%d-%H%M%S).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Weryfikacja snapshot
sudo ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot-latest.db \
  --write-out=table

# Automated backup script (cron job)
cat > /usr/local/bin/etcd-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/etcd"
DATE=$(date +%Y%m%d-%H%M%S)
SNAPSHOT_FILE="$BACKUP_DIR/etcd-snapshot-$DATE.db"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Create snapshot
ETCDCTL_API=3 etcdctl snapshot save "$SNAPSHOT_FILE" \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "etcd-snapshot-*.db" -mtime +7 -delete

# Log result
if [ $? -eq 0 ]; then
    echo "$(date): ETCD backup successful: $SNAPSHOT_FILE" >> /var/log/etcd-backup.log
else
    echo "$(date): ETCD backup failed" >> /var/log/etcd-backup.log
    exit 1
fi
EOF

chmod +x /usr/local/bin/etcd-backup.sh

# Cron job - codziennie o 2:00
echo "0 2 * * * root /usr/local/bin/etcd-backup.sh" >> /etc/crontab
```

### Application Data Backup
```yaml
# CronJob dla backup bazy danych
apiVersion: batch/v1
kind: CronJob
metadata:
  name: database-backup
  namespace: produkcja
spec:
  schedule: "0 1 * * *"                     # Codziennie o 1:00
  timeZone: "Europe/Warsaw"
  concurrencyPolicy: Forbid                 # Nie pozwól na równoległe backupy
  successfulJobsHistoryLimit: 7            # Zachowaj 7 udanych job
  failedJobsHistoryLimit: 3                # Zachowaj 3 nieudane job
  jobTemplate:
    spec:
      backoffLimit: 2                       # 2 próby w przypadku błędu
      activeDeadlineSeconds: 3600           # Maksymalnie 1 godzina
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: backup-container
            image: postgres:15-alpine       # Obraz z narzędziami DB
            command:
            - "/bin/bash"
            - "-c"
            - |
              set -e
              echo "Rozpoczynam backup bazy danych: $(date)"
              
              # Database backup
              pg_dump \
                --host="$DB_HOST" \
                --port="$DB_PORT" \
                --username="$DB_USER" \
                --dbname="$DB_NAME" \
                --format=custom \
                --compress=9 \
                --file="/backup/backup-$(date +%Y%m%d-%H%M%S).dump"
              
              # Upload to S3 (przykład)
              aws s3 cp /backup/ s3://my-backups/database/ --recursive
              
              # Cleanup local files older than 3 days
              find /backup -name "*.dump" -mtime +3 -delete
              
              echo "Backup zakończony pomyślnie: $(date)"
            
            env:
            - name: DB_HOST
              value: "postgres-service"
            - name: DB_PORT  
              value: "5432"
            - name: DB_NAME
              value: "production_db"
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: postgres-credentials
                  key: username
            - name: PGPASSWORD                # PostgreSQL password env var
              valueFrom:
                secretKeyRef:
                  name: postgres-credentials
                  key: password
            - name: AWS_ACCESS_KEY_ID         # S3 credentials
              valueFrom:
                secretKeyRef:
                  name: s3-credentials
                  key: access-key
            - name: AWS_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: s3-credentials
                  key: secret-key
            
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
            
            resources:
              requests:
                cpu: "200m"
                memory: "512Mi"
              limits:
                cpu: "1000m"
                memory: "2Gi"
          
          volumes:
          - name: backup-storage
            emptyDir:
              sizeLimit: 10Gi               # Tymczasowy storage dla backup
```

### Disaster Recovery Procedures
```bash
# ETCD Restore (TYLKO w emergency!)
# UWAGA: To zatrzyma cały klaster!

# 1. Zatrzymaj wszystkie komponenty control plane
sudo systemctl stop kubelet
sudo systemctl stop docker  # lub containerd

# 2. Restore ETCD z backup
sudo ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot-YYYYMMDD-HHMMSS.db \
  --data-dir="/var/lib/etcd-restore" \
  --initial-cluster="master=https://master-ip:2380" \
  --initial-advertise-peer-urls="https://master-ip:2380"

# 3. Przenieś restored data
sudo mv /var/lib/etcd /var/lib/etcd-backup
sudo mv /var/lib/etcd-restore /var/lib/etcd

# 4. Restart services
sudo systemctl start docker  # lub containerd
sudo systemctl start kubelet

# 5. Sprawdź czy klaster działa
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🔒 Security i Compliance

### RBAC - Role Based Access Control
```yaml
# ServiceAccount dla aplikacji
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aplikacja-sa
  namespace: produkcja
automountServiceAccountToken: true          # Automatycznie montuj token

---
# Role - uprawnienia w namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: aplikacja-role
  namespace: produkcja
rules:
# Dostęp do ConfigMaps
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]             # Read-only
  resourceNames: ["app-config"]               # Tylko konkretny ConfigMap

# Dostęp do Secrets
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
  resourceNames: ["app-secrets"]              # Tylko konkretny Secret

# Dostęp do własnych Pods (dla health checks itp.)
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

---
# RoleBinding - przypisanie Role do ServiceAccount
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: aplikacja-binding
  namespace: produkcja
subjects:
- kind: ServiceAccount
  name: aplikacja-sa                          # ServiceAccount
  namespace: produkcja
roleRef:
  kind: Role
  name: aplikacja-role                        # Role do przypisania
  apiGroup: rbac.authorization.k8s.io

---
# ClusterRole - uprawnienia cluster-wide (jeśli potrzebne)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]             # Read nodes cluster-wide

---
# ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: aplikacja-node-reader
subjects:
- kind: ServiceAccount
  name: aplikacja-sa
  namespace: produkcja
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

### Security Context Best Practices
```yaml
# Deployment z security hardening
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-application
  namespace: produkcja
spec:
  replicas: 3
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      # Pod-level security context
      securityContext:
        runAsNonRoot: true                    # Nie uruchamiaj jako root
        runAsUser: 1001                       # Konkretny user ID
        runAsGroup: 2001                      # Konkretny group ID
        fsGroup: 2001                         # Group dla volumes
        seccompProfile:                       # Seccomp profile
          type: RuntimeDefault
        supplementalGroups: [3001]            # Dodatkowe grupy
      
      # ServiceAccount z ograniczonymi uprawnieniami
      serviceAccountName: aplikacja-sa
      automountServiceAccountToken: true     # Czy montować token
      
      containers:
      - name: app
        image: nginx:1.25-alpine
        
        # Container-level security context
        securityContext:
          allowPrivilegeEscalation: false     # Brak privilege escalation
          readOnlyRootFilesystem: true        # Read-only filesystem
          capabilities:                       # Linux capabilities
            drop:
            - ALL                             # Usuń wszystkie capabilities
            add:
            - NET_BIND_SERVICE                # Tylko potrzebne capabilities
          runAsNonRoot: true
          runAsUser: 1001                     # Override pod setting jeśli potrzebne
        
        # Volume mounts dla writable directories
        volumeMounts:
        - name: tmp-volume                    # /tmp jako writable
          mountPath: /tmp
        - name: cache-volume                  # Cache jako writable
          mountPath: /var/cache/nginx
        - name: run-volume                    # Runtime files
          mountPath: /var/run
        
        # Ports (non-privileged)
        ports:
        - containerPort: 8080                 # Port > 1024 (non-privileged)
          name: http
        
        # Resource limits (security aspect)
        resources:
          limits:
            cpu: "500m"
            memory: "256Mi"
            ephemeral-storage: "1Gi"          # Ograniczenie storage
          requests:
            cpu: "100m"
            memory: "128Mi"
            ephemeral-storage: "500Mi"
      
      # Volumes dla writable directories
      volumes:
      - name: tmp-volume
        emptyDir: {}
      - name: cache-volume
        emptyDir: {}
      - name: run-volume
        emptyDir: {}
```

### Pod Security Standards
```yaml
# PodSecurityPolicy (deprecated) lub Pod Security Standards
# Namespace z Pod Security Standards enforcement
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    # Pod Security Standards levels:
    # - privileged: brak ograniczeń
    # - baseline: minimalne ograniczenia  
    # - restricted: silne ograniczenia bezpieczeństwa
    pod-security.kubernetes.io/enforce: restricted       # Wymuś restricted level
    pod-security.kubernetes.io/audit: restricted         # Audit violations
    pod-security.kubernetes.io/warn: restricted          # Warning dla violations
```

## 📋 Maintenance i Best Practices

### Resource Management
```yaml
# LimitRange - ograniczenia zasobów w namespace
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: produkcja
spec:
  limits:
  # Container limits
  - type: Container
    default:                                # Default limits
      cpu: "200m"
      memory: "256Mi"
    defaultRequest:                         # Default requests
      cpu: "100m"
      memory: "128Mi"
    max:                                    # Maximum per container
      cpu: "2000m"
      memory: "2Gi"
    min:                                    # Minimum per container
      cpu: "50m"
      memory: "64Mi"
  
  # Pod limits (suma wszystkich kontenerów)
  - type: Pod
    max:
      cpu: "4000m"
      memory: "4Gi"
  
  # PVC limits
  - type: PersistentVolumeClaim
    max:
      storage: "100Gi"
    min:
      storage: "1Gi"

---
# ResourceQuota - ograniczenia na poziomie namespace
apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
  namespace: produkcja
spec:
  hard:
    # Compute resources
    requests.cpu: "10"                      # Total CPU requests w namespace
    requests.memory: "20Gi"                 # Total memory requests
    limits.cpu: "20"                        # Total CPU limits
    limits.memory: "40Gi"                   # Total memory limits
    
    # Storage
    requests.storage: "500Gi"               # Total storage requests
    persistentvolumeclaims: "20"            # Max liczba PVC
    
    # Object counts
    pods: "50"                              # Max liczba pods
    replicationcontrollers: "10"            # Max RCs
    services: "20"                          # Max services  
    secrets: "30"                           # Max secrets
    configmaps: "30"                        # Max configmaps
    
    # LoadBalancer services (może kosztować!)
    services.loadbalancers: "3"             # Max LoadBalancer services
    
    # NodePort services
    services.nodeports: "5"                 # Max NodePort services
```

### Cleanup i Maintenance Tasks
```bash
# Cleanup completed Jobs starszych niż 7 dni
kubectl get jobs --all-namespaces -o jsonpath='{range .items[?(@.status.conditions[0].type=="Complete")]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' | \
while read namespace job; do
  if [ "$(kubectl get job $job -n $namespace -o jsonpath='{.status.completionTime}' | xargs -I {} date -d {} +%s)" -lt "$(date -d '7 days ago' +%s)" ]; then
    echo "Deleting completed job: $namespace/$job"
    kubectl delete job $job -n $namespace
  fi
done

# Cleanup failed Pods starszych niż 24 godziny
kubectl get pods --all-namespaces --field-selector=status.phase=Failed -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{.metadata.creationTimestamp}{"\n"}{end}' | \
while read namespace pod timestamp; do
  if [ "$(date -d $timestamp +%s)" -lt "$(date -d '24 hours ago' +%s)" ]; then
    echo "Deleting failed pod: $namespace/$pod"
    kubectl delete pod $pod -n $namespace
  fi
done

# Cleanup unused ConfigMaps (ostrożnie!)
# Sprawdź które ConfigMaps nie są używane przez żadne pody
for ns in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
  echo "Checking namespace: $ns"
  kubectl get configmaps -n $ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | \
  while read cm; do
    if ! kubectl get pods -n $ns -o yaml | grep -q "configMapRef:\|configMap:" | grep -q "$cm"; then
      echo "Potentially unused ConfigMap: $ns/$cm"
    fi
  done
done

# Docker image cleanup na węzłach (jeśli używasz Docker)
# Na każdym węźle:
# docker system prune -f
# docker image prune -a -f
```

### Monitoring i Alerting Setup
```bash
# Sprawdzenie czy metrics server działa
kubectl get deployment metrics-server -n kube-system
kubectl top nodes  # Jeśli działa to zwróci metryki

# Sprawdzenie API server metrics
kubectl get --raw /metrics | head -20

# Custom monitoring checks
# 1. Sprawdź czy critical pods działają
kubectl get pods -n kube-system | grep -E "(coredns|kube-proxy|metrics-server)" | grep -v Running

# 2. Sprawdź certificate expiration
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.conditions[?(@.type=="Ready")].lastHeartbeatTime}{"\n"}{end}'

# 3. Sprawdź używanie dysków na węzłach
kubectl describe nodes | grep -A 5 "Capacity:\|Allocatable:"

# 4. Sprawdź PV storage usage
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,STATUS:.status.phase,CLAIM:.spec.claimRef.name
```

---
*Kompleksowe zarządzanie Kubernetes - od skalowania do disaster recovery! 🔧*