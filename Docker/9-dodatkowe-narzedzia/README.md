# 9. Dodatkowe narzędzia

### 9.1 Narzędzie z graficznym interfejsem 1

* [Portainer](https://www.portainer.io/)

```bash
# Utworzenie folderu P:\Docker oraz udostępnienie go w ustawieniach Docker Desktop
docker container run -d -p 9000:9000 -p 8000:8000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v P:\Docker\Portainer:/data portainer/portainer
docker container run -d nginx
```

### 9.2 Narzędzie z graficznym interfejsem 2

> [Dockstation](https://dockstation.io/)

### 9.3 Narzędzie dostępne w terminalu 1

> Dry

```bash
docker container run --rm -it -v /var/run/docker.sock:/var/run/docker.sock moncho/dry
```

### 9.4 Narzędzie dostępne w terminalu 2

> Lazy Docker

```bash
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
```