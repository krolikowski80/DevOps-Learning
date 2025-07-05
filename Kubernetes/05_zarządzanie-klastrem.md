
# Zarządzanie Klasterem

## Namespace

Umożliwia izolację zasobów (np. dev, staging, prod)

```bash
kubectl create namespace dev
kubectl config set-context --current --namespace=dev
```

## ConfigMap i Secret

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: moja-konfiguracja
data:
  LOG_LEVEL: debug
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: moje-sekrety
type: Opaque
data:
  PASSWORD: cGFzc3dvcmQ=  # base64
```
