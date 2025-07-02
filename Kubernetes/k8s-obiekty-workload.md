# Kubernetes - Obiekty Workload

## 📦 Pod - Podstawowa Jednostka

### Czym Jest Pod
```yaml
# Pod to:
# - Najmniejsza jednostka w Kubernetes
# - Grupa 1 lub więcej kontenerów
# - Kontenery w podzie dzielą IP, volumes, cykl życia
# - Zazwyczaj 1 kontener = 1 pod (najczęstszy pattern)

apiVersion: v1
kind: Pod
metadata:
  name: prostynginx-pod               # Nazwa poda
  namespace: moje-testy               # Namespace
  labels:
    app: nginx                        # Etykieta aplikacji
    typ: webserver                    # Typ komponentu
  annotations:
    opis: "Prosty pod z nginx"        # Dodatkowe informacje
spec:
  # Restart policy - co robić gdy kontener się zatrzyma
  restartPolicy: Always               # Always/OnFailure/Never
  
  # DNS policy - jak rozwiązywać nazwy DNS
  dnsPolicy: ClusterFirst            # ClusterFirst/Default/None
  
  # Czas na graceful shutdown
  terminationGracePeriodSeconds: 30  # Sekundy na zamknięcie aplikacji
  
  containers:                        # Lista kontenerów w podzie
  - name: nginx-container             # Nazwa kontenera
    image: nginx:1.25-alpine          # Obraz kontenera
    
    # Porty które kontener udostępnia
    ports:
    - containerPort: 80               # Port wewnętrzny kontenera
      name: http                      # Nazwa portu (do referencji)
      protocol: TCP                   # TCP lub UDP
    
    # Zmienne środowiskowe
    env:
    - name: NGINX_PORT               # Nazwa zmiennej
      value: "80"                    # Wartość (zawsze string)
    - name: ENVIRONMENT
      value: "development"
    
    # Zasoby - requests (minimum) i limits (maksimum)
    resources:
      requests:                      # Minimum gwarantowane
        cpu: "100m"                  # 100 milicores (0.1 CPU)
        memory: "128Mi"              # 128 megabajtów RAM
      limits:                        # Maksimum dozwolone
        cpu: "500m"                  # 500 milicores (0.5 CPU)  
        memory: "256Mi"              # 256 megabajtów RAM
    
    # Health checks - sprawdzanie stanu kontenera
    livenessProbe:                   # Czy kontener żyje?
      httpGet:                       # HTTP request check
        path: /                      # Ścieżka do sprawdzenia
        port: 80                     # Port do sprawdzenia
      initialDelaySeconds: 10        # Czekaj 10s przed pierwszym check
      periodSeconds: 30              # Sprawdzaj co 30s
      timeoutSeconds: 5              # Timeout po 5s
      failureThreshold: 3            # Restart po 3 niepowodzeniach
    
    readinessProbe:                  # Czy kontener jest gotowy?
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5         # Szybsze dla readiness
      periodSeconds: 10              # Częstsze sprawdzanie
      timeoutSeconds: 3
      failureThreshold: 2            # Szybsze wykluczenie z serwisu
```

### Pod z Wieloma Kontenerami
```yaml
# Rzadko używany pattern - main container + helper (sidecar)
apiVersion: v1
kind: Pod
metadata:
  name: app-z-sidecar
spec:
  containers:
  # Główny kontener aplikacji
  - name: aplikacja-glowna
    image: moja-aplikacja:v1.0
    ports:
    - containerPort: 8080
    volumeMounts:                    # Montowanie volumes
    - name: shared-logs              # Nazwa volume
      mountPath: /var/log/app        # Ścieżka w kontenerze
  
  # Sidecar kontener (helper)  
  - name: log-collector
    image: fluent/fluent-bit:latest
    volumeMounts:
    - name: shared-logs              # Ten sam volume
      mountPath: /var/log            # Różna ścieżka
  
  # Wspólne volumes dla kontenerów
  volumes:
  - name: shared-logs                # Nazwa volume
    emptyDir: {}                     # Pusty katalog (tymczasowy)
```

## 🚀 Deployment - Zarządzanie Aplikacjami

### Podstawowy Deployment
```yaml
# Deployment to kontroler zarządzający podami
# Zapewnia:
# - Określoną liczbę replik
# - Rolling updates (aktualizacje bez przestojów)
# - Rollback do poprzedniej wersji
# - Self-healing (automatyczne odtwarzanie)

apiVersion: apps/v1
kind: Deployment
metadata:
  name: moja-aplikacja-deployment    # Nazwa deployment
  namespace: produkcja
  labels:
    app: moja-aplikacja
    wersja: v2.1.0
  annotations:
    deployment.kubernetes.io/revision: "1"  # Numer rewizji
spec:
  # Liczba identycznych podów
  replicas: 3                        # 3 kopie aplikacji
  
  # Strategia aktualizacji
  strategy:
    type: RollingUpdate              # RollingUpdate lub Recreate
    rollingUpdate:
      maxUnavailable: 1              # Max 1 pod niedostępny podczas update
      maxSurge: 1                    # Max 1 dodatkowy pod podczas update
  
  # Selektor - które pody należą do tego deployment
  selector:
    matchLabels:                     # Musi pasować do template.labels
      app: moja-aplikacja
      tier: frontend
  
  # Szablon dla tworzonych podów
  template:
    metadata:
      labels:                        # Etykiety dla podów
        app: moja-aplikacja          # Musi pasować do selector
        tier: frontend
        wersja: v2.1.0
      annotations:
        prometheus.io/scrape: "true" # Włącz monitorowanie
    spec:
      # Bezpieczeństwo - nie uruchamiaj jako root
      securityContext:
        runAsNonRoot: true           # Nie uruchamiaj jako root user
        runAsUser: 1001              # Konkretny user ID
        fsGroup: 2001                # Group ID dla plików
      
      containers:
      - name: aplikacja
        image: nginx:1.25-alpine
        
        # Image pull policy
        imagePullPolicy: IfNotPresent # Always/IfNotPresent/Never
        
        ports:
        - containerPort: 80
          name: http
        
        # Zmienne środowiskowe z różnych źródeł
        env:
        - name: APP_ENV
          value: "production"
        - name: DB_HOST               # Ze secret
          valueFrom:
            secretKeyRef:
              name: db-secret         # Nazwa secret
              key: hostname           # Klucz w secret
        - name: CONFIG_VALUE          # Z configmap
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: setting
        
        # Import całych configmap/secret jako zmienne
        envFrom:
        - configMapRef:               # Wszystkie klucze z configmap
            name: app-config
        - secretRef:                  # Wszystkie klucze z secret
            name: app-secrets
        
        # Zasoby i limity
        resources:
          requests:
            cpu: "200m"               # 0.2 CPU
            memory: "256Mi"           # 256 MB
          limits:
            cpu: "1000m"              # 1.0 CPU max
            memory: "512Mi"           # 512 MB max
        
        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
          successThreshold: 1
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
          successThreshold: 1
      
      # Image pull secrets dla prywatnych rejestrów
      imagePullSecrets:
      - name: registry-secret
```

### Deployment Operations
```bash
# Tworzenie deployment
kubectl apply -f deployment.yaml

# Sprawdzanie statusu
kubectl get deployments -n produkcja
kubectl rollout status deployment/moja-aplikacja-deployment -n produkcja

# Skalowanie (zmiana liczby replik)
kubectl scale deployment moja-aplikacja-deployment --replicas=5 -n produkcja

# Aktualizacja obrazu (rolling update)
kubectl set image deployment/moja-aplikacja-deployment aplikacja=nginx:1.26-alpine -n produkcja

# Historia wdrożeń
kubectl rollout history deployment/moja-aplikacja-deployment -n produkcja

# Rollback do poprzedniej wersji
kubectl rollout undo deployment/moja-aplikacja-deployment -n produkcja

# Rollback do konkretnej rewizji
kubectl rollout undo deployment/moja-aplikacja-deployment --to-revision=2 -n produkcja

# Pauzowanie/wznawianie rollout
kubectl rollout pause deployment/moja-aplikacja-deployment -n produkcja
kubectl rollout resume deployment/moja-aplikacja-deployment -n produkcja
```

## 📊 StatefulSet - Aplikacje Stanowe

### Kiedy Używać StatefulSet
```yaml
# StatefulSet dla aplikacji które potrzebują:
# - Stałych nazw podów (app-0, app-1, app-2)
# - Stałych adresów sieciowych
# - Trwałego przechowywania danych
# - Uporządkowanego wdrażania/skalowania

# Przykłady: bazy danych, kolejki wiadomości, systemy plików

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database-cluster             # Nazwa StatefulSet
  namespace: dane
spec:
  serviceName: "database-headless"   # Nazwa headless service (WYMAGANE)
  replicas: 3                        # Liczba instancji
  
  # Pod Management Policy
  podManagementPolicy: OrderedReady  # OrderedReady lub Parallel
  
  # Update Strategy
  updateStrategy:
    type: RollingUpdate              # OnDelete lub RollingUpdate
    rollingUpdate:
      partition: 0                   # Aktualizuj pody >= partition
  
  selector:
    matchLabels:
      app: database
  
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
        
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: root-password
        
        # Volume mount dla trwałych danych
        volumeMounts:
        - name: mysql-storage          # Nazwa volume claim template
          mountPath: /var/lib/mysql    # Ścieżka w kontenerze
        
        resources:
          requests:
            cpu: "500m"
            memory: "1Gi"
          limits:
            cpu: "2000m"
            memory: "4Gi"
  
  # Template dla Persistent Volume Claims
  volumeClaimTemplates:              # Każdy pod dostaje własny PVC
  - metadata:
      name: mysql-storage            # Nazwa volume (używana w volumeMounts)
    spec:
      accessModes: ["ReadWriteOnce"] # RWO - jeden pod na raz
      storageClassName: "fast-ssd"   # Klasa storage
      resources:
        requests:
          storage: 20Gi              # Rozmiar dysku dla każdego poda
```

### Headless Service dla StatefulSet
```yaml
# StatefulSet wymaga headless service dla stable network identity
apiVersion: v1
kind: Service
metadata:
  name: database-headless            # Musi pasować do serviceName w StatefulSet
  namespace: dane
spec:
  clusterIP: None                    # Headless = brak cluster IP
  selector:
    app: database
  ports:
  - port: 3306
    targetPort: 3306
    name: mysql

# Pody otrzymują DNS names:
# database-cluster-0.database-headless.dane.svc.cluster.local
# database-cluster-1.database-headless.dane.svc.cluster.local  
# database-cluster-2.database-headless.dane.svc.cluster.local
```

## 🔄 DaemonSet - Pod na Każdym Węźle

### Zastosowania DaemonSet
```yaml
# DaemonSet zapewnia że określony pod działa na każdym węźle
# Używane do:
# - Agentów monitorowania (Prometheus node-exporter)
# - Logów systemowych (Fluentd, Filebeat)
# - Networking (kube-proxy, CNI)
# - Security agents

apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector                # Nazwa DaemonSet
  namespace: monitoring
  labels:
    app: log-collector
spec:
  selector:
    matchLabels:
      app: log-collector
  
  # Update Strategy dla DaemonSet
  updateStrategy:
    type: RollingUpdate              # OnDelete lub RollingUpdate
    rollingUpdate:
      maxUnavailable: 1              # Max węzłów aktualizowanych jednocześnie
  
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      # Tolerations - pozwala działać na węzłach z taint
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists             # Może działać na master nodes
        effect: NoSchedule
      
      # Node Selector - tylko na konkretnych węzłach
      nodeSelector:
        kubernetes.io/os: linux      # Tylko na Linux nodes
      
      # Host networking dla dostępu do resources węzła
      hostNetwork: true              # Używa sieci węzła zamiast pod network
      hostPID: true                  # Dostęp do procesów węzła
      
      containers:
      - name: log-agent
        image: fluent/fluent-bit:latest
        
        # Security context z dostępem do host
        securityContext:
          privileged: true           # Pełny dostęp do węzła (ostrożnie!)
        
        # Volume mounts do host paths
        volumeMounts:
        - name: varlog               # Logi systemowe
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers  # Logi kontenerów
          mountPath: /var/lib/docker/containers
          readOnly: true
        
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
      
      # Volumes z host paths
      volumes:
      - name: varlog
        hostPath:                    # Katalog z węzła hosta
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

## ⏰ Job - Zadania Jednorazowe

### Job dla Zadań Batch
```yaml
# Job uruchamia pod do wykonania konkretnego zadania
# Po zakończeniu zadania pod się kończy
# Używane do:
# - Migracji bazy danych
# - Backup/restore
# - Przetwarzania batch
# - Zadań maintenance

apiVersion: batch/v1
kind: Job
metadata:
  name: migracja-bazy               # Nazwa job
  namespace: produkcja
  labels:
    app: migracja
    typ: maintenance
spec:
  # Ile razy próbować w przypadku niepowodzenia
  backoffLimit: 3                  # Maksymalnie 3 próby
  
  # Timeout dla całego job
  activeDeadlineSeconds: 1800      # 30 minut maksymalnie
  
  # Ile podów ma działać jednocześnie
  parallelism: 1                   # Jeden pod na raz
  
  # Ile podów musi się zakończyć sukcesem
  completions: 1                   # Jeden sukces wystarczy
  
  # TTL po zakończeniu (automatyczne czyszczenie)
  ttlSecondsAfterFinished: 86400   # Usuń po 24 godzinach
  
  template:
    metadata:
      labels:
        app: migracja
    spec:
      # Job pods nie powinny się restartować
      restartPolicy: OnFailure      # OnFailure lub Never (NIE Always)
      
      containers:
      - name: migrator
        image: migrate/migrate:latest
        command:                    # Komenda do wykonania
        - "/bin/sh"
        - "-c"
        - |
          echo "Rozpoczynam migrację bazy danych..."
          migrate -path /migrations -database "$DATABASE_URL" up
          echo "Migracja zakończona pomyślnie"
        
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        
        resources:
          requests:
            cpu: "100m"
            memory: "256Mi"
          limits:
            cpu: "500m" 
            memory: "512Mi"
```

### Job Operations
```bash
# Tworzenie job
kubectl apply -f job.yaml

# Sprawdzanie statusu job
kubectl get jobs -n produkcja
kubectl describe job migracja-bazy -n produkcja

# Sprawdzanie podów job
kubectl get pods -l job-name=migracja-bazy -n produkcja

# Logi z job
kubectl logs job/migracja-bazy -n produkcja

# Usuwanie job (i związanych podów)
kubectl delete job migracja-bazy -n produkcja
```

## 🕐 CronJob - Zadania Cykliczne

### CronJob dla Scheduled Tasks
```yaml
# CronJob tworzy Job według harmonogramu (jak cron w Linux)
# Używane do:
# - Backup bazy danych
# - Czyszczenie logów
# - Raporty okresowe
# - Health checks zewnętrznych systemów

apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-bazy-danych          # Nazwa CronJob
  namespace: produkcja
spec:
  # Harmonogram w formacie cron (minuta godzina dzień miesiąc dzień_tygodnia)
  schedule: "0 2 * * *"             # Codziennie o 2:00 rano
  # schedule: "*/15 * * * *"        # Co 15 minut
  # schedule: "0 */6 * * *"         # Co 6 godzin
  # schedule: "0 9 * * 1-5"         # Dni robocze o 9:00
  
  # Timezone (domyślnie UTC)
  timeZone: "Europe/Warsaw"         # Strefa czasowa
  
  # Polityka współbieżności
  concurrencyPolicy: Forbid         # Forbid/Allow/Replace
  # Forbid = nie uruchamiaj jeśli poprzedni job jeszcze działa
  # Allow = pozwól na równoległe wykonanie
  # Replace = zastąp działający job nowym
  
  # Historia przechowywania
  successfulJobsHistoryLimit: 3     # Zostaw 3 udane job
  failedJobsHistoryLimit: 1         # Zostaw 1 nieudany job
  
  # Deadline dla uruchomienia
  startingDeadlineSeconds: 300      # Jeśli nie uruchomi się w 5min = skip
  
  # Czy wstrzymać harmonogram
  suspend: false                    # true = wstrzymaj wykonywanie
  
  # Template dla Job (taki sam jak Job)
  jobTemplate:
    spec:
      backoffLimit: 2
      activeDeadlineSeconds: 3600   # 1 godzina na backup
      template:
        metadata:
          labels:
            app: backup
            typ: scheduled
        spec:
          restartPolicy: OnFailure
          
          containers:
          - name: backup-container
            image: mysql:8.0
            command:
            - "/bin/bash"
            - "-c"
            - |
              echo "Rozpoczynam backup bazy danych $(date)"
              
              # Backup bazy danych
              mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > /backup/backup-$(date +%Y%m%d-%H%M%S).sql
              
              # Upload do S3 (przykład)
              aws s3 cp /backup/backup-$(date +%Y%m%d-%H%M%S).sql s3://moje-backupy/
              
              echo "Backup zakończony pomyślnie $(date)"
            
            env:
            - name: DB_HOST
              value: "mysql-service"
            - name: DB_NAME
              value: "produkcja_db"
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: mysql-credentials
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-credentials
                  key: password
            
            # Volume dla tymczasowych plików backup
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
            
            resources:
              requests:
                cpu: "200m"
                memory: "512Mi"
              limits:
                cpu: "1000m"
                memory: "1Gi"
          
          volumes:
          - name: backup-storage
            emptyDir:               # Tymczasowy storage
              sizeLimit: 5Gi        # Maksymalnie 5GB
```

### CronJob Operations
```bash
# Tworzenie CronJob
kubectl apply -f cronjob.yaml

# Lista CronJob
kubectl get cronjobs -n produkcja
kubectl get cj -n produkcja        # Skrót

# Szczegóły CronJob
kubectl describe cronjob backup-bazy-danych -n produkcja

# Historia Job stworzonych przez CronJob
kubectl get jobs -l app=backup -n produkcja

# Ręczne uruchomienie job z CronJob
kubectl create job manual-backup --from=cronjob/backup-bazy-danych -n produkcja

# Wstrzymywanie/wznawianie CronJob
kubectl patch cronjob backup-bazy-danych -p '{"spec":{"suspend":true}}' -n produkcja
kubectl patch cronjob backup-bazy-danych -p '{"spec":{"suspend":false}}' -n produkcja

# Logi z ostatniego job
kubectl logs job/backup-bazy-danych-28123456 -n produkcja
```

## 📋 Porównanie Obiektów Workload

### Kiedy Użyć Którego Obiektu

| Obiekt | Kiedy Używać | Przykłady |
|--------|-------------|-----------|
| **Pod** | Prawie nigdy bezpośrednio | Debug, testy jednorazowe |
| **Deployment** | Aplikacje bezstanowe | Web serwery, API, frontend |
| **StatefulSet** | Aplikacje stanowe | Bazy danych, kolejki, storage |
| **DaemonSet** | Po jednym na węzeł | Monitorowanie, logi, networking |
| **Job** | Zadania jednorazowe | Migracje, backupy, przetwarzanie |
| **CronJob** | Zadania cykliczne | Scheduled backupy, raporty |

### Restart Policies

| RestartPolicy | Pod | Deployment | StatefulSet | DaemonSet | Job | CronJob |
|---------------|-----|------------|-------------|-----------|-----|---------|
| **Always** | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **OnFailure** | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Never** | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ |

### Scaling Capabilities

| Obiekt | Auto Scaling | Manual Scaling | Rolling Updates |
|--------|-------------|----------------|-----------------|
| **Deployment** | ✅ HPA/VPA | ✅ | ✅ |
| **StatefulSet** | ✅ HPA/VPA | ✅ | ✅ |
| **DaemonSet** | ❌ | ❌ | ✅ |
| **Job** | ❌ | ❌ | ❌ |
| **CronJob** | ❌ | ❌ | ❌ |

---
*Kompletny przegląd obiektów workload w Kubernetes! 🚀*