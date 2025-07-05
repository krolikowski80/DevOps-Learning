
# Skalowanie: HPA, VPA

## Horizontal Pod Autoscaler (HPA)

Automatycznie zwiększa liczbę replik w zależności od CPU/RAM.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
```

## Vertical Pod Autoscaler (VPA)

Automatycznie dobiera CPU/memory dla pojedynczego Poda.
