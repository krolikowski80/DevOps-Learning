# Kubernetes - Obiekty Sieciowe

## 🌐 Service - Udostępnianie Aplikacji

### ClusterIP - Komunikacja Wewnętrzna
```yaml
# ClusterIP to domyślny typ Service
# Zapewnia:
# - Stały adres IP wewnątrz klastra
# - Load balancing między podami
# - Service discovery przez DNS
# - Dostęp TYLKO z wnętrza klastra

apiVersion: v1
kind: Service
metadata:
  name: backend-service             # Nazwa serwisu (DNS name)
  namespace: produkcja              # Namespace
  labels:
    app: backend                    # Etykiety serwisu
    tier: application
  annotations:
    service.alpha.kubernetes.io/tolerate-unready-endpoints: "true"  # Toleruj niegotowe pody
spec:
  type: ClusterIP                   # Typ serwisu (domyślny)
  
  # Selector - które pody obsługuje ten serwis
  selector:
    app: backend                    # Musi pasować do etykiet podów
    tier: application               # Można użyć wielu selektorów
  
  # Porty serwisu
  ports:
  - name: http                      # Nazwa portu (opcjonalna, ale zalecana)
    port: 80                        # Port serwisu (na który łączą się klienci)
    targetPort: 8080                # Port kontenera (może być nazwa portu z pod)
    protocol: TCP                   # TCP lub UDP
  
  - name: https                     # Drugi port (serwis może mieć wiele portów)
    port: 443
    targetPort: 8443
    protocol: TCP
  
  # Session affinity - sticky sessions
  sessionAffinity: None             # None lub ClientIP
  sessionAffinityConfig:            # Konfiguracja dla ClientIP
    clientIP:
      timeoutSeconds: 10800         # 3 godziny (domyślnie)

# DNS name dla tego serwisu:
# backend-service.produkcja.svc.cluster.local:80
# backend-service.produkcja:80 (skrócona forma)
# backend-service:80 (z tego samego namespace)
```

### NodePort - Dostęp Zewnętrzny przez Węzły
```yaml
# NodePort udostępnia serwis na porcie każdego węzła
# Używane do:
# - Testowego dostępu zewnętrznego
# - Środowisk bez load balancera
# - Integracji z zewnętrznymi load balancerami

apiVersion: v1
kind: Service
metadata:
  name: frontend-nodeport
  namespace: produkcja
spec:
  type: NodePort                    # Typ serwisu
  
  selector:
    app: frontend
  
  ports:
  - name: http
    port: 80                        # Port ClusterIP (wewnętrzny)
    targetPort: 3000                # Port kontenera
    nodePort: 30080                 # Port na każdym węźle (30000-32767)
    protocol: TCP
  
  # Polityka ruchu zewnętrznego
  externalTrafficPolicy: Local      # Local lub Cluster
  # Local = zachowuje source IP, tylko lokalne pody
  # Cluster = load balancing na wszystkie pody (może zmienić source IP)

# Dostęp przez:
# http://ADRES-WĘZŁA:30080
# http://10.0.1.5:30080 (przykład)
```

### LoadBalancer - Cloud Provider Integration
```yaml
# LoadBalancer tworzy zewnętrzny load balancer (AWS ELB, GCP LB, etc.)
# Najlepszy sposób na production external access

apiVersion: v1
kind: Service
metadata:
  name: api-loadbalancer
  namespace: produkcja
  annotations:
    # AWS specific annotations
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"                    # Network Load Balancer
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-internal: "false"              # Public LB
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    
    # Azure specific annotations  
    service.beta.kubernetes.io/azure-load-balancer-internal: "false"
    service.beta.kubernetes.io/azure-dns-label-name: "moja-aplikacja"
    
    # GCP specific annotations
    cloud.google.com/neg: '{"ingress": true}'
    cloud.google.com/backend-config: '{"default": "moja-aplikacja-backendconfig"}'
spec:
  type: LoadBalancer
  
  selector:
    app: api
  
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  
  - name: https  
    port: 443
    targetPort: 8443
    protocol: TCP
  
  # Ograniczenie dostępu do konkretnych IP
  loadBalancerSourceRanges:         # Whitelist IP ranges
  - "10.0.0.0/8"                   # Prywatne sieci
  - "192.168.0.0/16"
  - "203.0.113.0/24"               # Konkretny zakres publiczny
  
  # Polityka ruchu
  externalTrafficPolicy: Local      # Zachowaj source IP

# Po utworzeniu otrzymasz External IP:
# kubectl get service api-loadbalancer
# EXTERNAL-IP: a1b2c3d4e5f6-123456789.us-west-2.elb.amazonaws.com
```

### ExternalName - Mapowanie Zewnętrznych Serwisów
```yaml
# ExternalName mapuje serwis na zewnętrzną nazwę DNS
# Używane do:
# - Integracji z zewnętrznymi bazami danych
# - Mapowania zewnętrznych API
# - Abstrakcji zewnętrznych zależności

apiVersion: v1
kind: Service
metadata:
  name: zewnetrzna-baza             # Nazwa używana w aplikacjach
  namespace: produkcja
spec:
  type: ExternalName
  externalName: rds.us-west-2.amazonaws.com  # Rzeczywista nazwa zewnętrzna
  ports:                            # Opcjonalne - dla dokumentacji
  - port: 5432
    targetPort: 5432
    name: postgresql

# Aplikacje mogą używać:
# postgresql://zewnetrzna-baza.produkcja.svc.cluster.local:5432
# Kubernetes przekieruje to na:
# postgresql://rds.us-west-2.amazonaws.com:5432
```

### Headless Service - Bezpośredni Dostęp do Podów
```yaml
# Headless Service nie ma Cluster IP
# DNS zwraca bezpośrednio adresy IP podów
# Używane z StatefulSet dla stable network identity

apiVersion: v1
kind: Service
metadata:
  name: database-headless
  namespace: dane
spec:
  clusterIP: None                   # Headless = brak cluster IP
  
  selector:
    app: mysql-cluster
  
  ports:
  - port: 3306
    targetPort: 3306
    name: mysql

# DNS query zwraca IP wszystkich podów:
# nslookup database-headless.dane.svc.cluster.local
# -> 10.244.1.5, 10.244.2.3, 10.244.3.7

# StatefulSet pody mają stable DNS names:
# mysql-cluster-0.database-headless.dane.svc.cluster.local
# mysql-cluster-1.database-headless.dane.svc.cluster.local
# mysql-cluster-2.database-headless.dane.svc.cluster.local
```

## 🚪 Ingress - HTTP/HTTPS Routing

### Podstawowy Ingress
```yaml
# Ingress zarządza dostępem HTTP/HTTPS z zewnątrz klastra
# Zapewnia:
# - Virtual hosting (wiele domen na jednym IP)
# - Path-based routing
# - SSL termination
# - Load balancing L7

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: aplikacja-ingress           # Nazwa ingress
  namespace: produkcja
  annotations:
    # Ingress controller specific annotations
    kubernetes.io/ingress.class: "nginx"                         # Controller type
    nginx.ingress.kubernetes.io/rewrite-target: /               # URL rewriting
    nginx.ingress.kubernetes.io/ssl-redirect: "true"            # Wymuszenie HTTPS
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    
    # Rate limiting
    nginx.ingress.kubernetes.io/rate-limit: "100"               # 100 req/min per IP
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    
    # CORS headers
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://moja-domena.com"
    
    # SSL certificate management (cert-manager)
    cert-manager.io/cluster-issuer: "letsencrypt-prod"          # Auto SSL cert
    acme.cert-manager.io/http01-edit-in-place: "true"
spec:
  # TLS configuration
  tls:
  - hosts:
    - api.moja-firma.com           # Domeny dla certyfikatu
    - www.moja-firma.com
    secretName: api-tls-secret     # Secret gdzie będzie certyfikat
  
  # Routing rules
  rules:
  - host: api.moja-firma.com       # Virtual host
    http:
      paths:
      # API endpoints
      - path: /api/v1/users        # Ścieżka URL
        pathType: Prefix           # Prefix/Exact/ImplementationSpecific
        backend:
          service:
            name: user-service     # Docelowy serwis
            port:
              number: 80           # Port serwisu
      
      - path: /api/v1/orders
        pathType: Prefix
        backend:
          service:
            name: order-service
            port:
              number: 80
      
      # Default backend dla nierozpoznanych ścieżek
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
  
  # Druga domena
  - host: www.moja-firma.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: website-service
            port:
              number: 80
```

### Zaawansowany Ingress z Annotations
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: zaawansowany-ingress
  namespace: produkcja
  annotations:
    # Basic settings
    kubernetes.io/ingress.class: "nginx"
    
    # SSL i Security
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-protocols: "TLSv1.2 TLSv1.3"
    nginx.ingress.kubernetes.io/ssl-ciphers: "ECDHE-RSA-AES128-GCM-SHA256,ECDHE-RSA-AES256-GCM-SHA384"
    
    # Security headers
    nginx.ingress.kubernetes.io/server-snippet: |
      add_header X-Frame-Options "SAMEORIGIN" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header X-XSS-Protection "1; mode=block" always;
      add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Rate limiting
    nginx.ingress.kubernetes.io/rate-limit: "200"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    nginx.ingress.kubernetes.io/rate-limit-connections: "10"
    
    # Client body size
    nginx.ingress.kubernetes.io/proxy-body-size: "8m"           # Max upload size
    
    # Timeouts
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    
    # Custom error pages
    nginx.ingress.kubernetes.io/custom-http-errors: "404,503"
    nginx.ingress.kubernetes.io/default-backend: "error-page-service"
    
    # Whitelist IP addresses
    nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8,192.168.0.0/16,203.0.113.0/24"
    
    # Basic auth (jeśli potrzebne)
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth-secret
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
    
    # Sticky sessions
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/affinity-mode: "persistent"
    nginx.ingress.kubernetes.io/session-cookie-name: "route"
    nginx.ingress.kubernetes.io/session-cookie-expires: "86400"
    nginx.ingress.kubernetes.io/session-cookie-max-age: "86400"
    nginx.ingress.kubernetes.io/session-cookie-path: "/"
spec:
  tls:
  - hosts:
    - secure-api.moja-firma.com
    secretName: secure-api-tls
  
  rules:
  - host: secure-api.moja-firma.com
    http:
      paths:
      - path: /api/v1
        pathType: Prefix
        backend:
          service:
            name: secure-api-service
            port:
              number: 80
```

### Ingress Class - Wybór Controllera
```yaml
# IngressClass definiuje który controller obsługuje ingress
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx-public               # Nazwa klasy
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"  # Domyślna klasa
spec:
  controller: k8s.io/ingress-nginx # Controller identifier

---
# Użycie konkretnej klasy w Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: moj-ingress
spec:
  ingressClassName: nginx-public   # Użyj tej klasy zamiast annotation
  # ... reszta konfiguracji
```

## 🔒 NetworkPolicy - Kontrola Ruchu Sieciowego

### Default Deny All - Zabezpieczenie Podstawowe
```yaml
# NetworkPolicy kontroluje ruch sieciowy między podami
# Domyślnie Kubernetes pozwala na wszystko
# NetworkPolicy implementuje "default deny" + explicit allow

# Zablokuj cały ruch w namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all           # Nazwa policy
  namespace: produkcja             # Namespace gdzie obowiązuje
spec:
  podSelector: {}                  # Pusty selector = wszystkie pody
  policyTypes:                     # Typy ruchu do kontroli
  - Ingress                        # Ruch przychodzący
  - Egress                         # Ruch wychodzący
  
  # Brak sekcji ingress/egress = deny all
```

### Allow Specific Communication
```yaml
# Pozwól tylko na komunikację API -> Database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-database
  namespace: produkcja
spec:
  # Target: pody bazy danych
  podSelector:
    matchLabels:
      app: mysql                   # Dotyczy podów z etykietą app=mysql
      tier: database
  
  policyTypes:
  - Ingress                        # Kontrolujemy ruch przychodzący
  
  ingress:                         # Reguły przychodzące
  - from:                          # Źródła ruchu
    # Tylko z podów API
    - podSelector:
        matchLabels:
          app: api                 # Tylko pody z app=api
          tier: backend
    
    # Tylko na porcie bazy danych
    ports:
    - protocol: TCP
      port: 3306                   # Port MySQL
  
  # Dodatkowo: pozwól na wychodzący ruch DNS
  - from:
    - namespaceSelector:
        matchLabels:
          name: kube-system        # Z namespace kube-system
    ports:
    - protocol: UDP
      port: 53                     # DNS queries
```

### Namespace Isolation
```yaml
# Izolacja między namespace - tylko wybrane komunikują się
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: namespace-isolation
  namespace: produkcja
spec:
  podSelector: {}                  # Wszystkie pody w namespace
  
  policyTypes:
  - Ingress
  - Egress
  
  ingress:
  # Pozwól z tego samego namespace
  - from:
    - podSelector: {}              # Wszystkie pody z tego namespace
  
  # Pozwól z namespace "shared-services"
  - from:
    - namespaceSelector:
        matchLabels:
          name: shared-services    # Namespace z etykietą name=shared-services
  
  # Pozwól z Ingress Controller
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
  
  egress:
  # Pozwól do tego samego namespace
  - to:
    - podSelector: {}
  
  # Pozwól do namespace "shared-services" (bazy danych, cache)
  - to:
    - namespaceSelector:
        matchLabels:
          name: shared-services
  
  # Pozwól DNS queries
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  
  # Pozwól HTTPS na zewnątrz (dla API calls)
  - to: []                         # Wszystkie destynacje
    ports:
    - protocol: TCP
      port: 443
```

### Web Application Security Policy
```yaml
# Typowa polityka dla aplikacji webowej
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: webapp-security-policy
  namespace: produkcja
spec:
  podSelector:
    matchLabels:
      tier: frontend               # Dotyczy podów frontend
  
  policyTypes:
  - Ingress
  - Egress
  
  ingress:
  # Pozwól ruch z Ingress Controller
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP  
      port: 443
  
  egress:
  # Pozwól komunikację z backend API
  - to:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 8080
  
  # Pozwól komunikację z bazą danych
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432                   # PostgreSQL
    - protocol: TCP
      port: 3306                   # MySQL
  
  # Pozwól DNS queries
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  
  # Pozwól zewnętrzne API calls (HTTPS)
  - to: []                         # Wszystkie external destynacje
    ports:
    - protocol: TCP
      port: 443
```

## 🔍 Endpoints - Mapowanie Service na Pody

### Automatyczne Endpoints
```yaml
# Endpoints są tworzone automatycznie przez Service
# Mapują Service na IP i porty podów

# Sprawdzenie endpoints:
# kubectl get endpoints nazwa-service -n namespace
# kubectl describe endpoints nazwa-service -n namespace

# Przykład automatycznych endpoints dla Service:
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend                   # Service automatycznie znajdzie pody
  ports:
  - port: 80
    targetPort: 8080

# Kubernetes automatycznie tworzy:
# Endpoints z IP podów które pasują do selektora
# i są w stanie Ready (przechodzą readiness probe)
```

### Ręczne Endpoints (bez selektora)
```yaml
# Service bez selektora + ręczne Endpoints
# Używane dla zewnętrznych serwisów z stałymi IP

apiVersion: v1
kind: Service
metadata:
  name: zewnetrzny-serwis
  namespace: produkcja
spec:
  # Brak selektora = ręczne zarządzanie endpoints
  ports:
  - port: 80
    targetPort: 80
    name: http

---
# Ręczne Endpoints
apiVersion: v1
kind: Endpoints
metadata:
  name: zewnetrzny-serwis          # Musi pasować do nazwy Service
  namespace: produkcja
subsets:
- addresses:                       # IP addresses serwerów
  - ip: "203.0.113.10"            # Pierwszy serwer
  - ip: "203.0.113.11"            # Drugi serwer
  - ip: "203.0.113.12"            # Trzeci serwer
  ports:
  - port: 80                       # Port na serwerach
    name: http
    protocol: TCP
```

## 🌐 EndpointSlice - Nowoczesne Endpoints

### EndpointSlice vs Endpoints
```yaml
# EndpointSlice to nowsza wersja Endpoints (Kubernetes 1.17+)
# Korzyści:
# - Lepsza skalowalność (można dzielić na kawałki)
# - Więcej metadanych (topology, conditions)
# - Lepsze performance dla dużych klastrów

apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: backend-service-abc123      # Auto-generated name
  namespace: produkcja
  labels:
    kubernetes.io/service-name: backend-service  # Link do Service
addressType: IPv4                   # IPv4, IPv6, FQDN
endpoints:
- addresses:
  - "10.244.1.5"                   # IP poda
  conditions:
    ready: true                     # Czy endpoint jest gotowy
    serving: true                   # Czy obsługuje ruch
    terminating: false              # Czy się kończy
  hostname: "backend-pod-1"         # Hostname poda
  targetRef:                        # Referencja do obiektu
    kind: Pod
    name: backend-deployment-abc123
    namespace: produkcja
  topology:                         # Informacje o topologii
    kubernetes.io/hostname: "worker-node-1"
    topology.kubernetes.io/zone: "us-west-2a"
- addresses:
  - "10.244.2.3"
  conditions:
    ready: true
    serving: true
    terminating: false
  hostname: "backend-pod-2"
  targetRef:
    kind: Pod
    name: backend-deployment-def456
    namespace: produkcja
  topology:
    kubernetes.io/hostname: "worker-node-2"
    topology.kubernetes.io/zone: "us-west-2b"
ports:
- port: 8080                        # Port docelowy
  name: http
  protocol: TCP
```

## 🛠️ Service Mesh - Zaawansowana Komunikacja

### Service Mesh Concepts
```yaml
# Service Mesh dodaje dodatkową warstwę komunikacji
# Popularne rozwiązania: Istio, Linkerd, Consul Connect

# Korzyści:
# - mTLS między serwisami
# - Advanced routing (canary, blue-green)
# - Observability (metrics, tracing)
# - Traffic policies (retry, circuit breaker)
# - Security policies

# Przykład Istio VirtualService:
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend-routing
  namespace: produkcja
spec:
  hosts:
  - backend-service                 # Service name
  http:
  - match:
    - headers:                      # Routing based on headers
        canary:
          exact: "true"
    route:
    - destination:
        host: backend-service
        subset: canary              # Route to canary version
      weight: 100
  - route:
    - destination:
        host: backend-service
        subset: stable              # Default to stable version
      weight: 100
```

## 📊 Service Discovery Patterns

### DNS-Based Discovery
```bash
# Kubernetes automatic DNS records:

# Service DNS format:
# service-name.namespace.svc.cluster.local

# Examples:
backend-service.produkcja.svc.cluster.local      # Full FQDN
backend-service.produkcja                        # Short form
backend-service                                  # Same namespace

# Headless Service DNS (StatefulSet):
pod-0.headless-service.namespace.svc.cluster.local
pod-1.headless-service.namespace.svc.cluster.local

# SRV records for port discovery:
_http._tcp.backend-service.produkcja.svc.cluster.local
```

### Environment Variables Discovery
```bash
# Kubernetes automatycznie tworzy zmienne środowiskowe
# Format: {SERVICE_NAME}_SERVICE_HOST i {SERVICE_NAME}_SERVICE_PORT

# Dla Service o nazwie "backend-service":
BACKEND_SERVICE_SERVICE_HOST=10.96.55.123
BACKEND_SERVICE_SERVICE_PORT=80
BACKEND_SERVICE_SERVICE_PORT_HTTP=80
BACKEND_SERVICE_PORT=tcp://10.96.55.123:80
BACKEND_SERVICE_PORT_80_TCP=tcp://10.96.55.123:80
BACKEND_SERVICE_PORT_80_TCP_PROTO=tcp
BACKEND_SERVICE_PORT_80_TCP_PORT=80
BACKEND_SERVICE_PORT_80_TCP_ADDR=10.96.55.123
```

## 🔧 Troubleshooting Networking

### Service Debug Commands
```bash
# Sprawdź Service i Endpoints
kubectl get svc backend-service -n produkcja
kubectl describe svc backend-service -n produkcja
kubectl get endpoints backend-service -n produkcja
kubectl describe endpoints backend-service -n produkcja

# Sprawdź czy pody mają właściwe etykiety
kubectl get pods -n produkcja --show-labels
kubectl get pods -l app=backend -n produkcja

# Test DNS resolution z pod
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup backend-service.produkcja.svc.cluster.local

# Test connectivity
kubectl run test-connect --image=busybox --rm -it --restart=Never -- wget -qO- http://backend-service.produkcja:80/
```

### NetworkPolicy Debug
```bash
# Lista NetworkPolicy w namespace
kubectl get networkpolicy -n produkcja
kubectl describe networkpolicy nazwa-policy -n produkcja

# Test connectivity między podami
kubectl exec -it frontend-pod -n produkcja -- curl http://backend-service:80/

# Sprawdź logi network plugin (Calico/Cilium/etc)
kubectl logs -n kube-system -l k8s-app=calico-node

# Sprawdź czy CNI obsługuje NetworkPolicy
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
```

### Ingress Debug
```bash
# Sprawdź Ingress status
kubectl get ingress -n produkcja
kubectl describe ingress aplikacja-ingress -n produkcja

# Sprawdź Ingress Controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Test zewnętrznego dostępu
curl -H "Host: api.moja-firma.com" http://EXTERNAL-IP/api/v1/test

# Sprawdź certyfikaty SSL
kubectl get secret api-tls-secret -n produkcja -o yaml
openssl x509 -in cert.pem -text -noout
```

## 💡 Best Practices Networking

### ✅ Service Design
- Używaj nazw portów w Service (łatwiejsze zarządzanie)
- Ustaw odpowiednią sessionAffinity dla aplikacji stanowych
- Używaj headless Service dla StatefulSet
- Ograniczaj loadBalancerSourceRanges dla bezpieczeństwa

### ✅ Ingress Configuration
- Zawsze konfiguruj TLS/SSL dla external endpoints
- Używaj path-based routing żeby zmniejszyć liczbę load balancerów
- Konfiguruj rate limiting i security headers
- Monitoruj Ingress Controller metrics

### ✅ Network Security
- Implementuj NetworkPolicy w production environments
- Zacznij od "default deny" i explicit allow
- Separuj ruch między namespace i labels
- Regularnie audytuj network policy effectiveness

### ✅ Performance
- Używaj Local externalTrafficPolicy gdy potrzebujesz source IP
- Konfiguruj odpowiednie timeouts w Ingress annotations
- Monitoruj latency między serwisami
- Używaj Service Mesh dla advanced routing i observability

---
*Kompletna sieć w Kubernetes - od podstaw do zaawansowanych! 🌐*