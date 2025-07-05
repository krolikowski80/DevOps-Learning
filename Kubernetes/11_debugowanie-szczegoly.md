# Kubernetes - Debugowanie i Rozwiązywanie Problemów

## 🔍 Podstawowe Komendy Diagnostyczne

### Szybki Przegląd Stanu Klastra
```bash
# Stan ogólny klastra
kubectl cluster-info                              # Podstawowe info o klastrze
kubectl cluster-info dump > cluster-dump.txt     # Pełny dump diagnostyczny
kubectl version --short                          # Wersje klienta i serwera

# Stan węzłów
kubectl get nodes                                 # Lista węzłów
kubectl get nodes -o wide                        # Szczegółowe info (IP, OS, runtime)
kubectl describe nodes                           # Pełne szczegóły wszystkich węzłów
kubectl describe node nazwa-wezla                # Szczegóły konkretnego węzła

# Stan namespace
kubectl get namespaces                           # Lista wszystkich namespace
kubectl get ns --show-labels                    # Namespace z etykietami

# Przegląd zasobów w namespace
kubectl get all -n produkcja                    # Wszystkie główne zasoby
kubectl get pods,svc,deploy,rs -n produkcja     # Konkretne typy zasobów
kubectl get pods -n produkcja -o wide           # Pody z dodatkowymi kolumnami
kubectl get pods --all-namespaces               # Pody ze wszystkich namespace

# Wydarzenia w klastrze (chronologicznie)
kubectl get events --sort-by='.lastTimestamp'                    # Wszystkie wydarzenia
kubectl get events --sort-by='.lastTimestamp' -n produkcja       # W konkretnym namespace
kubectl get events --field-selector type=Warning                 # Tylko ostrzeżenia
kubectl get events --field-selector type=Warning -n produkcja    # Ostrzeżenia w namespace
kubectl get events --watch                                       # Śledzenie na żywo

# Wykorzystanie zasobów
kubectl top nodes                               # CPU/Memory węzłów
kubectl top pods -n produkcja                  # CPU/Memory podów
kubectl top pods -n produkcja --sort-by=cpu    # Sortowanie po CPU
kubectl top pods -n produkcja --sort-by=memory # Sortowanie po pamięci
kubectl top pods --all-namespaces              # Wszystkie pody
```

## 🚨 Debugowanie Podów - Stany i Problemy

### Analiza Cyklu Życia Pod
```bash
# Sprawdzenie statusu pod
kubectl get pods -n produkcja
kubectl get pod nazwa-pod -n produkcja -o yaml     # Pełna konfiguracja YAML
kubectl describe pod nazwa-pod -n produkcja        # Szczegółowe info + wydarzenia

# Fazy pod (Pod Phase):
# - Pending    = Pod czeka na uruchomienie
# - Running    = Pod jest uruchomiony  
# - Succeeded  = Pod zakończył się sukcesem (Job)
# - Failed     = Pod zakończył się błędem
# - Unknown    = Stan nieznany (problem komunikacji z kubelet)

# Status kontenerów w pod:
# - Waiting    = Kontener czeka (np. na pobranie obrazu)
# - Running    = Kontener działa
# - Terminated = Kontener zakończył działanie
```

### Pod w Stanie "Pending" - Nie Może Się Uruchomić
```bash
# Sprawdź powody oczekiwania
kubectl describe pod nazwa-pod -n produkcja

# Najczęstsze przyczyny Pending:
# 1. Insufficient resources (za mało CPU/memory na węzłach)
# 2. Node selector nie pasuje do żadnego węzła
# 3. Pod affinity/anti-affinity rules
# 4. Taints na węzłach bez odpowiednich tolerations
# 5. PVC nie może zostać zamontowany
# 6. Image pull secrets brakujące

# Debug resource constraints:
kubectl describe nodes | grep -A 5 "Allocated resources"
kubectl top nodes                               # Rzeczywiste wykorzystanie
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.allocatable.cpu}{"\t"}{.status.allocatable.memory}{"\n"}{end}'

# Debug node selection:
kubectl get nodes --show-labels                 # Sprawdź etykiety węzłów
kubectl describe pod nazwa-pod -n produkcja | grep -A 10 "Node-Selectors\|Tolerations"

# Debug PVC issues:
kubectl get pvc -n produkcja                   # Status Persistent Volume Claims
kubectl describe pvc nazwa-pvc -n produkcja   # Szczegóły błędów PVC

# Debug taints and tolerations:
kubectl describe nodes | grep -A 3 "Taints"   # Sprawdź taints na węzłach
```

### Pod w Stanie "ImagePullBackOff" - Problem z Obrazem
```bash
# Sprawdź szczegóły błędu pobierania obrazu
kubectl describe pod nazwa-pod -n produkcja | grep -A 10 Events

# Najczęstsze przyczyny ImagePullBackOff:
# 1. Błędna nazwa obrazu lub tag
# 2. Brak uprawnień do prywatnego rejestru
# 3. Problemy sieciowe z rejestrem
# 4. Image nie istnieje w rejestrze
# 5. Rate limiting w Docker Hub

# Debug image name:
kubectl get pod nazwa-pod -n produkcja -o jsonpath='{.spec.containers[*].image}'

# Debug image pull secrets:
kubectl get secrets -n produkcja | grep docker
kubectl describe secret nazwa-registry-secret -n produkcja

# Test manual image pull:
kubectl run test-image --image=problematyczny-obraz:tag --rm -it --restart=Never
kubectl delete pod test-image  # Cleanup

# Debug registry connectivity:
kubectl run debug-registry --image=busybox --rm -it --restart=Never -- nslookup registry.gitlab.com
kubectl run debug-registry --image=busybox --rm -it --restart=Never -- wget -qO- https://registry.gitlab.com/v2/

# Sprawdź image pull policy:
kubectl get pod nazwa-pod -n produkcja -o jsonpath='{.spec.containers[*].imagePullPolicy}'
```

### Pod w Stanie "CrashLoopBackOff" - Kontener Ciągle Się Restartuje
```bash
# Sprawdź logi z obecnego kontenera
kubectl logs nazwa-pod -n produkcja
kubectl logs nazwa-pod -c nazwa-kontenera -n produkcja  # Multi-container pod

# Sprawdź logi z poprzedniej instancji (przed restart)
kubectl logs nazwa-pod -n produkcja --previous
kubectl logs nazwa-pod -c nazwa-kontenera -n produkcja --previous

# Sprawdź liczę restartów
kubectl get pod nazwa-pod -n produkcja | grep RESTARTS

# Najczęstsze przyczyny CrashLoopBackOff:
# 1. Aplikacja nie uruchamia się (błędy kodu, deps)
# 2. Health check zbyt agresywny
# 3. Brakujące zmienne środowiskowe
# 4. Problemy z konfiguracją (ConfigMap/Secret)
# 5. Niewystarczające uprawnienia filesystem
# 6. Out of Memory

# Debug health checks:
kubectl get pod nazwa-pod -n produkcja -o yaml | grep -A 15 "livenessProbe\|readinessProbe"

# Debug environment variables:
kubectl exec nazwa-pod -n produkcja -- env | sort
kubectl describe pod nazwa-pod -n produkcja | grep -A 20 "Environment"

# Debug exit codes:
kubectl describe pod nazwa-pod -n produkcja | grep "Exit Code"
# Exit Code 0   = Success
# Exit Code 1   = General error
# Exit Code 125 = Docker daemon error
# Exit Code 126 = Container command not executable
# Exit Code 127 = Container command not found
# Exit Code 137 = SIGKILL (OOMKilled)
# Exit Code 143 = SIGTERM (Graceful shutdown)

# Check OOMKilled:
kubectl describe pod nazwa-pod -n produkcja | grep -i "oomkilled\|out of memory"
dmesg | grep -i "killed process"  # Na węźle gdzie pod był uruchomiony
```

### Pod w Stanie "RunContainerError" - Błąd Uruchomienia Kontenera
```bash
# Sprawdź szczegółowy błąd
kubectl describe pod nazwa-pod -n produkcja | tail -20

# Najczęstsze przyczyny:
# 1. Błędna komenda lub argumenty w kontenerze
# 2. Problemy z volume mounts
# 3. Security context conflicts
# 4. Resource limits zbyt restrykcyjne

# Debug command/args:
kubectl get pod nazwa-pod -n produkcja -o jsonpath='{.spec.containers[*].command}'
kubectl get pod nazwa-pod -n produkcja -o jsonpath='{.spec.containers[*].args}'

# Debug volume mounts:
kubectl describe pod nazwa-pod -n produkcja | grep -A 10 "Mounts:"

# Debug security context:
kubectl get pod nazwa-pod -n produkcja -o yaml | grep -A 10 securityContext
```

## 📋 Analiza Logów - Kompleksowe Podejście

### Podstawowe Operacje na Logach
```bash
# Podstawowe pobieranie logów
kubectl logs nazwa-pod -n produkcja                    # Ostatnie logi
kubectl logs nazwa-pod -n produkcja --tail=100         # Ostatnie 100 linii
kubectl logs nazwa-pod -n produkcja --since=1h         # Ostatnia godzina
kubectl logs nazwa-pod -n produkcja --since=10m        # Ostatnie 10 minut
kubectl logs nazwa-pod -n produkcja --timestamps       # Z timestamps

# Follow logs (real-time)
kubectl logs -f nazwa-pod -n produkcja                 # Śledzenie na żywo
kubectl logs -f nazwa-pod -n produkcja --tail=50       # Ostatnie 50 + follow

# Logi z wielu podów
kubectl logs -l app=moja-aplikacja -n produkcja        # Wszystkie pody z etykietą
kubectl logs -l app=moja-aplikacja -n produkcja --all-containers=true  # Wszystkie kontenery

# Logi z konkretnego okresu
kubectl logs nazwa-pod -n produkcja --since-time=2024-06-29T10:00:00Z
kubectl logs nazwa-pod -n produkcja --since=2024-06-29T10:00:00Z --until=2024-06-29T11:00:00Z
```

### Zaawansowane Filtrowanie Logów
```bash
# Grep w logach
kubectl logs nazwa-pod -n produkcja | grep ERROR
kubectl logs nazwa-pod -n produkcja | grep -i "exception\|error\|fail"
kubectl logs nazwa-pod -n produkcja | grep -v INFO    # Wszystko OPRÓCZ INFO

# Ostatnie błędy
kubectl logs nazwa-pod -n produkcja --tail=1000 | grep -i error | tail -10

# Logi z poprzedniej instancji + filtrowanie
kubectl logs nazwa-pod -n produkcja --previous | grep -A 5 -B 5 "FATAL"

# Count error patterns
kubectl logs nazwa-pod -n produkcja | grep -c ERROR
kubectl logs nazwa-pod -n produkcja | grep ERROR | wc -l

# Structured logs (JSON) processing
kubectl logs nazwa-pod -n produkcja | jq '.level,.message'  # Jeśli logi są w JSON
```

### Multi-Container Pod Logs
```bash
# Lista kontenerów w pod
kubectl get pod nazwa-pod -n produkcja -o jsonpath='{.spec.containers[*].name}'

# Logi z konkretnego kontenera
kubectl logs nazwa-pod -c app-container -n produkcja
kubectl logs nazwa-pod -c sidecar-container -n produkcja

# Logi ze wszystkich kontenerów jednocześnie
kubectl logs nazwa-pod -n produkcja --all-containers=true
kubectl logs nazwa-pod -n produkcja --all-containers=true --prefix=true  # Z prefixem nazwy kontenera

# Follow logs z wielu kontenerów
kubectl logs -f nazwa-pod -n produkcja --all-containers=true --prefix=true
```

## 🌐 Debugowanie Sieci i Komunikacji

### Service Discovery Issues
```bash
# Sprawdź czy service istnieje
kubectl get svc -n produkcja
kubectl get svc nazwa-service -n produkcja -o yaml
kubectl describe svc nazwa-service -n produkcja

# Sprawdź endpoints (czy service ma pody)
kubectl get endpoints nazwa-service -n produkcja
kubectl describe endpoints nazwa-service -n produkcja

# Brak endpoints oznacza problem z selektor
kubectl get pods -n produkcja --show-labels                    # Etykiety podów
kubectl get svc nazwa-service -n produkcja -o yaml | grep selector  # Selektor service

# Sprawdź czy pody są Ready
kubectl get pods -n produkcja | grep nazwa-aplikacji
kubectl describe pod nazwa-pod -n produkcja | grep Conditions -A 10
```

### DNS Resolution Testing
```bash
# Test DNS resolution z wnętrza klastra
kubectl run dns-test --image=busybox --rm -it --restart=Never -- nslookup nazwa-service.produkcja.svc.cluster.local

# Test DNS z pod działającego w klastrze
kubectl exec -it nazwa-pod -n produkcja -- nslookup nazwa-service.produkcja.svc.cluster.local

# Sprawdź DNS config w pod
kubectl exec -it nazwa-pod -n produkcja -- cat /etc/resolv.conf

# Test różnych form DNS
kubectl exec -it nazwa-pod -n produkcja -- nslookup nazwa-service                      # Same namespace
kubectl exec -it nazwa-pod -n produkcja -- nslookup nazwa-service.produkcja           # Cross namespace short
kubectl exec -it nazwa-pod -n produkcja -- nslookup nazwa-service.produkcja.svc.cluster.local  # Full FQDN

# Test SRV records (dla portów)
kubectl exec -it nazwa-pod -n produkcja -- nslookup -type=srv _http._tcp.nazwa-service.produkcja.svc.cluster.local
```

### Network Connectivity Testing
```bash
# Basic connectivity test
kubectl exec -it nazwa-pod -n produkcja -- wget -qO- http://nazwa-service:80/
kubectl exec -it nazwa-pod -n produkcja -- curl -v http://nazwa-service:80/health

# Test z timeout
kubectl exec -it nazwa-pod -n produkcja -- timeout 10 wget -qO- http://nazwa-service:80/

# Test konkretnego portu
kubectl exec -it nazwa-pod -n produkcja -- telnet nazwa-service 80
kubectl exec -it nazwa-pod -n produkcja -- nc -zv nazwa-service 80

# Test z zewnętrznego pod debug
kubectl run netshoot --image=nicolaka/netshoot --rm -it --restart=Never -- bash
# W kontenerze netshoot:
# curl http://nazwa-service.produkcja:80/
# dig nazwa-service.produkcja.svc.cluster.local
# traceroute nazwa-service.produkcja.svc.cluster.local
# nmap -p 80 nazwa-service.produkcja
```

### Port Forwarding dla Local Access
```bash
# Forward service port do local machine
kubectl port-forward svc/nazwa-service 8080:80 -n produkcja
# Następnie: curl http://localhost:8080

# Forward pod port
kubectl port-forward pod/nazwa-pod 8080:8000 -n produkcja

# Forward deployment port
kubectl port-forward deployment/nazwa-deployment 8080:80 -n produkcja

# Port forward w tle
kubectl port-forward svc/nazwa-service 8080:80 -n produkcja &
# Test: curl http://localhost:8080
# Stop: kill %1
```

## 🔐 Debugowanie Secrets i ConfigMaps

### Secret Troubleshooting
```bash
# Sprawdź czy secret istnieje
kubectl get secrets -n produkcja
kubectl describe secret nazwa-secret -n produkcja

# Sprawdź zawartość secret (base64 decoded)
kubectl get secret nazwa-secret -n produkcja -o yaml
kubectl get secret nazwa-secret -n produkcja -o jsonpath='{.data.klucz}' | base64 -d

# Sprawdź czy pod używa secret
kubectl describe pod nazwa-pod -n produkcja | grep -A 10 "Environment:\|Mounts:"

# Test czy zmienne są dostępne w pod
kubectl exec -it nazwa-pod -n produkcja -- env | grep NAZWA_ZMIENNEJ
kubectl exec -it nazwa-pod -n produkcja -- printenv | sort

# Sprawdź mounted secret files
kubectl exec -it nazwa-pod -n produkcja -- ls -la /path/do/mounted/secret/
kubectl exec -it nazwa-pod -n produkcja -- cat /path/do/mounted/secret/klucz
```

### ConfigMap Troubleshooting
```bash
# Sprawdź ConfigMap
kubectl get configmaps -n produkcja
kubectl describe configmap nazwa-configmap -n produkcja
kubectl get configmap nazwa-configmap -n produkcja -o yaml

# Sprawdź czy pod używa ConfigMap
kubectl describe pod nazwa-pod -n produkcja | grep -A 15 "Environment:\|Mounts:"

# Test mounted ConfigMap files
kubectl exec -it nazwa-pod -n produkcja -- ls -la /etc/config/
kubectl exec -it nazwa-pod -n produkcja -- cat /etc/config/app.properties

# Sprawdź environment variables z ConfigMap
kubectl exec -it nazwa-pod -n produkcja -- env | grep CONFIG
```

### Volume Mount Issues
```bash
# Sprawdź volume mounts w pod
kubectl describe pod nazwa-pod -n produkcja | grep -A 10 "Mounts:"

# Sprawdź volume definitions
kubectl get pod nazwa-pod -n produkcja -o yaml | grep -A 20 volumes:

# Test filesystem w pod
kubectl exec -it nazwa-pod -n produkcja -- df -h           # Disk usage
kubectl exec -it nazwa-pod -n produkcja -- mount | grep volumes  # Mounted volumes
kubectl exec -it nazwa-pod -n produkcja -- ls -la /path/to/volume/

# Sprawdź uprawnienia
kubectl exec -it nazwa-pod -n produkcja -- ls -la /path/to/volume/
kubectl exec -it nazwa-pod -n produkcja -- id              # User/group info
```

## 📊 Debugowanie Zasobów i Performance

### Resource Utilization Analysis
```bash
# Current resource usage
kubectl top nodes
kubectl top pods -n produkcja
kubectl top pods -n produkcja --containers              # Per container usage

# Resource requests vs limits
kubectl describe pod nazwa-pod -n produkcja | grep -A 5 "Requests:\|Limits:"

# Resource quotas w namespace
kubectl describe quota -n produkcja
kubectl get resourcequota -n produkcja -o yaml

# Node capacity vs allocated
kubectl describe nodes | grep -A 5 "Capacity:\|Allocatable:\|Allocated resources:"

# OOM analysis
kubectl describe pod nazwa-pod -n produkcja | grep -i "oomkilled\|out of memory"
dmesg | tail -20  # Na węźle (jeśli masz dostęp)
```

### Performance Bottlenecks
```bash
# CPU/Memory trends
kubectl top pods -n produkcja --sort-by=cpu
kubectl top pods -n produkcja --sort-by=memory

# Pod restart analysis
kubectl get pods -n produkcja | grep RESTARTS

# Event timeline for performance issues
kubectl get events --sort-by='.lastTimestamp' -n produkcja | grep nazwa-pod

# Application-level metrics (jeśli endpoint dostępny)
kubectl port-forward pod/nazwa-pod 9090:9090 -n produkcja &
curl http://localhost:9090/metrics | grep -E "(cpu|memory|request)"
kill %1
```

## 🛠️ Narzędzia Debug - Interaktywne Troubleshooting

### Pod Debug Utilities
```bash
# BusyBox - podstawowe narzędzia Unix
kubectl run debug-busybox --image=busybox --rm -it --restart=Never -- sh
# W środku: wget, nslookup, telnet, ping, netstat

# Alpine z curl
kubectl run debug-alpine --image=alpine/curl --rm -it --restart=Never -- sh
# W środku: curl, wget, nslookup, dig

# Ubuntu - pełne środowisko
kubectl run debug-ubuntu --image=ubuntu --rm -it --restart=Never -- bash
# W środku: apt update && apt install -y [tools]

# Network debugging specialist
kubectl run netshoot --image=nicolaka/netshoot --rm -it --restart=Never -- bash
# W środku: tcpdump, wireshark, iperf, curl, dig, nmap, netstat, ss
```

### Debug Specific Pod Issues
```bash
# Debug pod with same spec as problematic pod
kubectl debug nazwa-pod -n produkcja -it --image=busybox --target=nazwa-kontenera

# Create debug copy of pod
kubectl debug nazwa-pod -n produkcja -it --image=ubuntu --share-processes --copy-to=debug-copy

# Debug with different image but same volumes/network
kubectl debug nazwa-pod -n produkcja -it --image=ubuntu --target=nazwa-kontenera

# Debug node issues
kubectl debug node/nazwa-node -it --image=ubuntu
```

## 🚨 Emergency Troubleshooting Playbook

### Aplikacja Nie Odpowiada - Quick Response
```bash
# 1. Sprawdź status podów
kubectl get pods -l app=nazwa-aplikacji -n produkcja

# 2. Sprawdź service endpoints  
kubectl get endpoints nazwa-service -n produkcja

# 3. Sprawdź ostatnie wydarzenia
kubectl get events --sort-by='.lastTimestamp' -n produkcja | tail -10

# 4. Sprawdź logi
kubectl logs -l app=nazwa-aplikacji -n produkcja --tail=50

# 5. Quick connectivity test
kubectl run test --image=busybox --rm -it --restart=Never -- wget -qO- http://nazwa-service/health
```

### Service Discovery Broken
```bash
# 1. DNS test
kubectl run dns-test --image=busybox --rm -it --restart=Never -- nslookup nazwa-service.namespace.svc.cluster.local

# 2. Sprawdź endpoints
kubectl get endpoints nazwa-service -n namespace

# 3. Sprawdź selector match
kubectl get pods -n namespace --show-labels | grep app=nazwa
kubectl get svc nazwa-service -n namespace -o yaml | grep selector

# 4. Sprawdź ready status
kubectl get pods -l app=nazwa -n namespace | grep Ready
```

### Network Policy Blocking Traffic
```bash
# 1. Sprawdź network policies
kubectl get networkpolicy -n namespace

# 2. Sprawdź czy policy blokuje
kubectl describe networkpolicy policy-name -n namespace

# 3. Test connectivity
kubectl exec -it source-pod -n namespace -- curl target-service:port

# 4. Temporary disable (emergency)
kubectl delete networkpolicy policy-name -n namespace  # OSTROŻNIE!
```

### Massive Pod Failures
```bash
# 1. Sprawdź status węzłów
kubectl get nodes

# 2. Sprawdź node resources
kubectl describe nodes | grep -A 10 "Conditions:\|Allocated resources:"

# 3. Sprawdź system pods
kubectl get pods -n kube-system

# 4. Check recent events cluster-wide
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20
```

---
*Systematyczne debugowanie Kubernetes - od basics do emergency response! 🔧*