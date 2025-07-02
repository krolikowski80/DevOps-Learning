# 12. DevOps

### 12.1 Własne Docker Registry

`docker run -d -p 5000:5000 --name registry -v /var/myregistry/data:/var/lib/registry --restart always registry:2`
* niezalecane do rozwiązań produkcyjnych

* wymagany wpis w `/etc/docker/daemon.json`
  ```json
  {
    "insecure-registries" : ["registry-fqdn:5000"]
  }
  ```
  ```bash
  docker login registry-fqdn:5000
  ```

```bash
# utworzenie lokalnego registry
sudo mkdir -p /var/myregistry/data
docker run -d -p 5000:5000 --name registry -v /var/myregistry/data:/var/lib/registry --restart always registry:2
docker container ls
curl http://localhost:5000/v2/_catalog

# dodanie obrazu do registry
docker image pull ubuntu:18.04
docker image tag ubuntu:18.04 localhost:5000/ubuntu:18.04
docker image push localhost:5000/ubuntu:18.04
curl http://localhost:5000/v2/_catalog

docker image rm localhost:5000/ubuntu:18.04
docker image rm ubuntu:18.04
docker image pull localhost:5000/ubuntu:18.04

sudo mkdir -p /var/myregistry/auth
docker run --entrypoint htpasswd registry:2.7.0 -Bbn user password123 >> /var/myregistry/auth/htpasswd
cat /var/myregistry/auth/htpasswd

docker container rm $(docker container ls -aq) --force
docker container ls

docker run -p 5000:5000 -d \
-e REGISTRY_AUTH=htpasswd \
-e REGISTRY_AUTH_HTPASSWD_PATH=auth/htpasswd \
-e REGISTRY_AUTH_HTPASSWD_REALM=realm \
-v /var/myregistry/data:/var/lib/registry \
-v /var/myregistry/auth:/auth \
--name myregistry --restart always registry:2
docker container ls

docker image pull localhost:5000/ubuntu:18.04 #error - no basic auth credentials
docker login -u user -p password123 localhost:5000
docker image pull localhost:5000/ubuntu:18.04 # działa
```

### 12.2 Bezpieczne Docker Registry

* [Run an externally-accessible registry](https://docs.docker.com/registry/deploying/#get-a-certificate)

### 12.3 Docker Registry storage driver

* Konfiguracja zdefiniowana w pliku YAML 
* Znajduje się wewnątrz kontenera w katalogu `etc/docker/registy/config.yml`
* Możliwość nadpisania poszczególnych zmiennych
* Możliwość nadpisania całej konfiguracji

### 12.4 Interfejs graficzny dla Docker Registry

* [Docker Registry Frontend](https://github.com/kwk/docker-registry-frontend)
* [Portus](http://port.us.org/)
* [GoGarbor](https://goharbor.io/)

### 12.8 Odśmiecanie systemu

* `docker system df` - sprawdzenie zajmowanego miejsca
* `docker system prune` - polecenie do manualnego czyszczenia całego środowiska
  * należy korzystać z niego świadomie
  * usuwa wszystkie nieużywane obrazy (w tym obrazy pośrednie), kontenery, sieci
  * nie usuwa nieużywanych volumenów

Usuwanie częściowe:
  * `docker volume prune`
  * `docker container prune`
  * `docker image prune`
  * `docker network prune`