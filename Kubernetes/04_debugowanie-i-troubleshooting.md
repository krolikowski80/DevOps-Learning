
# Debugowanie i Troubleshooting

## Sprawdzanie stanu

```bash
kubectl get pods -A
kubectl describe pod <nazwa>
kubectl logs <pod>
```

## Restart i test

```bash
kubectl delete pod <nazwa>    # wymusi restart
kubectl exec -it <pod> -- bash
```

## Częste błędy

- CrashLoopBackOff: aplikacja się restartuje – sprawdź `logs`.
- Pending: brak zasobów lub problem z PVC.
- ImagePullBackOff: błędna nazwa obrazu lub brak dostępu do registry.
