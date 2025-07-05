
# Networking: Service, Ingress

## Service

`Service` umożliwia trwały dostęp do Podów – nawet jeśli Pod zostanie zrestartowany.
Rodzaje Service:
- **ClusterIP** (domyślny): tylko wewnątrz klastra.
- **NodePort**: dostęp z zewnątrz przez port węzła (np. 30000–32767).
- **LoadBalancer**: integruje się z chmurą i tworzy publiczny adres IP.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: moja-usluga
spec:
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 8080
```

## Ingress

Ingress to kontroler HTTP, który mapuje żądania (np. `mojadomena.pl/api`) do odpowiedniego serwisu.
Wymaga zainstalowanego Ingress Controller (np. NGINX).

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
spec:
  rules:
  - host: mojadomena.pl
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: moja-usluga
            port:
              number: 80
```
