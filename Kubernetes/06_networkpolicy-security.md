
# NetworkPolicy i Bezpieczeństwo

## NetworkPolicy

Kontroluje który Pod może komunikować się z którym (domyślnie wszystko jest otwarte).

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

## Bezpieczeństwo

- `SecurityContext`: definiuje ograniczenia kontenera.
- `PodSecurityPolicy` (deprecated), lepiej używać `OPA Gatekeeper`.
