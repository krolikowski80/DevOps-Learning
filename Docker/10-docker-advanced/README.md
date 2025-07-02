# 10. Docker Advanced

### 10.2 Konfiguracja Docker Engine

Konfiguracja:
* Linux: /etc/docker/daemon.json
* Windows: Settings -> Docker Engine
* MacOS: Preferences -> Daemon -> Advanced

### 10.3 Komunikacja z Docker Daemon po HTTP

* Domyślnie komunikacja Docker Daemona z DockerCLI odbywa się przez Unix Sockets (/var/run/docker.sock) i wymaga uprawnień dla grupy ,,docker"
* Istnieje możliwośc komunikacji po TCP: Domyślnie komunikacja nie jest szyfrowana oraz nie posiada uwierzytelniania

#### Komunikacja z Docker Engine po HTTP
1. Dodajemy w pliku /etc/docker/daemon.json wpis:
```json
"hosts":["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]
```

2. Debian/Ubuntu należy stworzyć plik /etc/systemd/system/socker.service.d/docker.conf
```
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
```

3. Uruchamiamy polecenie: sudo systemctl daemon-reload
4. Korzystamy z Dockera po HTTP: docker -H tcp://0.0.0.0:2375 ps

```bash
cat /etc/docker/daemon.json
sudo nano /etc/docker/daemon.json
# dodanie wpisu "hosts":["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo nano /etc/systemd/system/docker.service.d/docker.conf
#[Service]
#ExecStart=
#ExecStart=/usr/bin/dockerd
cat /etc/systemd/system/docker.service.d/docker.conf
sudo systemctl daemon-reload
sudo systemctl restart docker

sudo docker ps
docker -H tcp://0.0.0.0:2375 ps

sudo docker image pull nginx:latest
curl -X POST -H "Content-Type: application/json" \
    -d '{"Image": "nginx:latest", "PortBindings": {"80/tcp" : [{ "HostPort": "8080" }]}}' \
    localhost:2375/v1.40/containers/create?name=create-by-api4
```

### 10.5 Logowanie
```bash
docker info --format '{{.LoggingDriver}}'
docker container run --name redis-json redis
cd /var/lib/docker/containers
ls -lah
cd ./3b812d71f61e0ddb210b3c5bc5732cbf9bbf6d726ef02a3d57e736979afb2db2
ls -lah
cat 3b812d71f61e0ddb210b3c5bc5732cbf9bbf6d726ef02a3d57e736979afb2db2-json.log
cd /

nano /etc/docker/daemon.json
# dodanie wpisu "log-driver": "local"
sudo systemctl restart docker
docker info --format '{{.LoggingDriver}}'
docker container run --name redis-local redis
cd /var/lib/docker/containers
ls -lah
cd ./f1d2df27951bd4d2c20958b94dafac3b95d0687e050bf3ab594fcc417d1da789
ls -lah
cd local-logs
ls -lah
cat container.log
cd /

# nano /etc/docker/daemon.json
# zmiana sterownika na journald 
# "log-driver": "local"
# lub
docker container run --name redis-journald --log-driver=journald redis
docker container logs redis-journald
journalctl -xe | grep edis

journalctl -fu docker.service #logi całego Docker Engine
journalctl -u docker.service #logi całego Docker Engine
```

### 10.6 Debugowanie Docker Engine
```bash
nano /etc/docker/daemon.json
# dodanie "debug": true
# {
#     "log-driver": "local",
#     "debug": true
# }

sudo kill -SIGHUP $(pidof dockerd)
docker info
docker container run -d --name redis-debug redis
journalctl --no-pager -u docker.service --since "1 minute ago"

docker container rm redis-debug --force
journalctl --no-pager -u docker.service --since "1 minute ago"
```

### 10.7 Debugowanie kontenerów

Container PID mode:
* możemy pozwolić na dostęp do procesów hosta wewnątrz kontenera `--pid=host`
* w obrębie jednego kontenera możemy pozwolić na dostep do procesów innego kontenara `--pid=container:<name|id>`

Container Network mode:
* możemy pozwolić na dostęp do interfejsów hosta wewnątz kontenera `--net=host`
* w obrębie jednego kontenera możemy pozwolić na dostęp do procesów innego kontenera `--net=container:<id|name>`

```bash
docker image pull jonbaldie/htop

docker run -it --rm --pid=host jonbaldie/htop #podgląd wszystkich procesów działających na hoście

docker run -d -p 9000:80 --name nginx nginx
docker run -it --rm --pid=container:nginx jonbaldie/htop #podgląd wszystkich procesów działających w kontenerze nginx

docker run -it --rm --pid=container:nginx --cap-add sys_admin --cap-add sys_ptrace dnaprawa/strace #podgląd stacktrace kontenera

docker run -it --rm --pid=container:nginx --cap-add sys_admin --cap-add sys_ptrace dnaprawa/strace sh
    ls -l /proc/1/root
    ls -l /proc/1/root/usr/share/nginx/html
    vi /proc/1/root/usr/share/nginx/html/index.html
    exit
curl localhost:9000

docker run -it --net container:nginx nicolaka/netshoot ngrep -d eth0 -x -q
docker run -it --net container:nginx nicolaka/netshoot tcpdump -i eth0 port 80 -c 1 -Xvv # nasługiwanie ruchu sieciowego na porcie 80
# otwarcie 2 konsoli i wywołanie curl localhost:9000
```

### 10.8 Komunikacja z Dockerem na serwerze

Skonfigurowanie połączenia po SSH z wykorzystaniem pary kluczy:

1. Bezpośrednie połączenie przez SSH
> docker -H "ssh://user@host" container ls

2. Wskazanie połączenia za pomocą zmiennej środowiskowej
Linux:
> export DOCKER_HOST=ssh://user@host

Windows:
> $dockerHost="ssh://user@host"

> $Env:DOCKER_HOST=$dockerHost

> docker container ls

3. Wykorzystanie context w Dockerze
> docker context create context1 --docker "host=ssh://user@remote_host"

> docker --context context1 container ls

> docker context use context1


### 10.9 Przechowywanie warstw obrazu na dysku

Overlay2:
* Storage driver - od niego zależy jak warstwy obrazów są przechowywane na dysku
* Katalog `/var/lib/docker/overlay2`

```bash
docker image pull redis
docker image inspect redis
# pobranie ostatniego wpisu z GraphDriver.Data.LowerDir
# /var/lib/docker/overlay2/72c57cf93a93986b42b78783f311639ced43ec2bfe5b76a4e657de86c99820c0/diff
cd /var/lib/docker/overlay2/72c57cf93a93986b42b78783f311639ced43ec2bfe5b76a4e657de86c99820c0/diff
ls -lah # wyświetlone zostają pliki i obiekty pierwszej warstwy obrazu
cd ..
ls -lah
cat link # wyświetlenie skróconego linku wartwy pierwszej

docker image inspect redis
# pobranie drugiego wpisu od końca z GraphDriver.Data.LowerDir
# /var/lib/docker/overlay2/de1037552243f2a4fb6c6eb52039aaebf19570e60a3e068fa4cd1c7fbbd662b3/diff
cd /var/lib/docker/overlay2/de1037552243f2a4fb6c6eb52039aaebf19570e60a3e068fa4cd1c7fbbd662b3/diff
ls -lah # wyświetlone zostają pliki warstwy drugiej obrazu
cd ..
ls -lah
cat lower # wyświetlenie skróconego linku wartwy nadrzędnej, czyli w tym przypadku wartwy pierwszej
```