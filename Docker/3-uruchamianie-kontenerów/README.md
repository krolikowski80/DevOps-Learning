# 3. Uruchamianie kontenerów jak prawdziwy maestro


* `docker container run`
  * `docker container run hello-world`
  * `docker container run ubuntu:latest`
  * `docker container run ubuntu:latest ls -l` 
    * `ls -l` wyświetlenie listy plików
  * `docker container run -it -d ubuntu:latest bash`
    * `it` - tryb interaktywny
    * `d` - detach, działanie w tle
    * `bash` - uruchomienie procesu bash
  * `docker container exec -it <CONTAINER_ID/NAME>` - zalogowanie się do kontenera
  * `docker container run -d -p 8080:80 --name mynginx nginx:latest`
    * `-p 8080:80` - przekierowanie portu 8080 na port 80 w kontenerze
  * `docker container run -d -e POSTGRESS_USER=user1 -e POSTGRESS_PASS=Password -p 8080:80 --name mynginx nginx:latest`
    * `-e POSTGRESS_USER=user1` - ustawia zmienne środowiskowe w kontenerze
  * `docker container run -d -p 8080:80 --name mynginx3 nginx:latest nginx -T`
    * `nginx -T` - nadpisuje podstawową komendę (CMD) przy uruchomieniu kontenera - wyświetlenie konfiguracji

* `docker container create -p 8081:80 --name mynginx2 nginx:latest` - tworzy kontener, nie jest uruchamiany (status Created)
* `docker container start mynginx2` - uruchamia kontener

* `docker container ls`
* `docker container ls -a`

* `docker container stop <CONTAINER_ID/NAME>`
* `docker container rm <CONTAINER_ID/NAME> --force`
  * `force` - wymusza usunięcie uruchomionego kontenera
* `docker container stop $(docker container ls -q)` - wstrzyknięcie uruchomionych kontenerów
* `docker container rm $(docker container ls -aq) --force` - usuwa wszystkie kontenery

* `docker container logs <CONTAINER_ID/NAME>` - logi kontenera

* `docker image pull nginx:latest`
* `docker image pull postgress`

```bash
docker container run -itd --name myubuntu ubuntu:latest bash
docker container ls
docker container top myubuntu #główny proces kontenera
ps -aux | grep bash #wyszukanie działających procesów
docker container run -d --name mymongo mongo:latest
docker container top mymongo
docker container exec -it mumongo bash # wejście w kontener
  ps -aux
  exit
ps -aux | grep mongo
cat /proc/1/cgroup #sprawdzenie czy znajdujemy się w kontenerze
```

```bash
docker container create -e TEST_ENV=test -it --name myalpine1 alpine:latest sh
docker container inspect myalpine1 #wyświetlanie konfiguracji kontenera
docker container inspect --format='{{.Config.Image}}' myalpine1 #obraz kontenera
docker container inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' myalpine1 #adresy IP contenera
docker container ls
docker container start myalpine1
docker container ls
docker container inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
docker container logs myalpine1
docker container run -d -p 8088:80 --name mynginx1 nginx
curl http://localhost:8088
docker container logs mynginx1
docker container logs -f mynginx1 #stream logów
docker container stats mynginx1 #statystyki zużycia zasobów przez kontener
docker container stats --no-stream mynginx1
docker container stats --all --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" mynginx1
docker container stats --all mynginx1
docker container stats --no-stream #infomarcje zużycia zasobów przez wszystkie kontenery
```

```bash
docker container run --rm -d --name myapache -p 8000:80 httpd:2.4 #rm - automatycznie usunięty
docker container ls
curl localhost:8000
docker container run --name db -e MYSQL_ROOT_PASSWORD=Password --restart always -d -p 3306:3306 mysql:5.7 #automatyczny restart w pprzypadku błędu
docker container logs db
docker container ls
docker container stop $(docker container ls -q)
docker container start db
docker container ls
```



