
# Workloady: Pod, Deployment, StatefulSet

## Pod

To najmniejszy obiekt w Kubernetes. Może zawierać kilka kontenerów (współdzielą IP i storage).
Najczęściej używamy jednego kontenera na Pod.

## Deployment

To kontroler, który:
- zarządza replikacją Podów,
- pozwala na rolling update,
- dba o dostępność aplikacji.

Przykład:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
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
        image: nginx
```

## StatefulSet

Podobny do Deployment, ale:
- każdy Pod ma unikalną nazwę (np. `mysql-0`, `mysql-1`),
- zachowuje dane między restartami (PVC),
- używany w bazach danych.
