
# Architektura i Podstawy

## Co to jest Kubernetes?

Kubernetes to system orkiestracji kontenerów. Jego zadaniem jest automatyzacja:
- uruchamiania aplikacji w kontenerach,
- skalowania ich w górę i w dół,
- utrzymywania ich stanu (self-healing),
- zarządzania siecią i konfiguracją.

## Główne komponenty klastra

- **Control Plane** – mózg klastra:
  - `kube-apiserver`: przyjmuje i przetwarza wszystkie żądania.
  - `etcd`: klucz-wartość baza danych – przechowuje konfigurację klastra.
  - `kube-scheduler`: decyduje, na którym nodzie uruchomić Pod.
  - `kube-controller-manager`: nadzoruje stan klastra i reaguje na zmiany.

- **Node (węzeł roboczy)**:
  - `kubelet`: agent monitorujący Pody.
  - `kube-proxy`: zarządza ruchem sieciowym.
  - `container runtime`: np. containerd, odpowiada za uruchamianie kontenerów.

## Obiekty w Kubernetes

- **Pod**: najmniejsza jednostka – grupa jednego lub więcej kontenerów.
- **Deployment**: deklaruje jak Pod ma być replikowany i zarządzany.
- **Service**: stały punkt dostępu do Poda – nawet jeśli ten się restartuje.
