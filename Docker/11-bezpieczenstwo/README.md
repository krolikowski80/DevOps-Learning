# 11. Bezpieczeństwo

### 11.3 Least privileged - czyli jak pozbyć się roota z kontenera
```bash
docker run -itd --name ubuntu-defaultuser ubuntu /bin/bash
docker container top ubuntu-defaultuser #PID: 5169
ps -aux | grep bash
# root      5169  0.0  0.0   4112  3388 pts/0    Ss+  14:34   0:00 /bin/bash

cd ../home/bartoszpelikan/
touch /home/bartoszpelikan/most-wanted-file
ls
docker run -itd --name ubuntu-defaultuser1 -v /:/hacking ubuntu /bin/bash
docker exec -it ubuntu-defaultuser1 bash
    ls -l
    cd hacking 
    ls
    rm ./home/bartoszpelikan/most-wanted-file
    exit

docker run -itd --user 998 --name ubuntu-customuser -v /:/hacking ubuntu /bin/bash
docker container top ubuntu-customuser #PID: 5596
ps -aux | grep bash
# 998       5596  0.1  0.0   4112  3184 pts/0    Ss+  14:40   0:00 /bin/bash
docker exec -it ubuntu-customuser bash
    cd hacking/home/bartoszpelikan/
    touch test-file # odmowa dostępu
    exit
```

### 11.4 User re-mapping
```bash
ls -lah /var/lib/docker
nano /etc/docker/daemon.json
# dodanie wpisu "userns-remap": "default"
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo nano /etc/systemd/system/docker.service.d/docker.conf
#[Service]
#ExecStart=
#ExecStart=/usr/bin/dockerd
sudo systemctl daemon-reload
systemctl restart docker
ls -lah /var/lib/docker

docker run -itd --name ubuntu-remap ubuntu bash
docker exec -it ubuntu-remap ps aux
docker container top ubuntu-remap # PID: 2892
ps -aux | grep bash
# 296608    2892  0.1  0.0   4112  3392 pts/0    Ss+  15:46   0:00 bash
```

### 11.5 Capabilities

Capabilities - mechanizm linuxowy za pomocą którego możemy ograniczyć uprawnienia roota (tylko i wyłączenie dla roota)
* domyślnie Docker usuwa wszystkie capabilities, a nastepnie dodaje tylko te które uważa za niezbędne

`docker run --cap-drop <CAP_TYPE> <IMAGE>` - usunięcie
`docker run --cap-drop <CAP_TYPE> <IMAGE>` - usunięcie wszystkich
`docker run --cap-add <CAP_TYPE> <IMAGE>` - dodanie

[All capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)

```bash
docker container run --rm -it alpine chown nobody /
docker container run --rm -it --cap-drop ALL --cap-add CHOWN alpine chown nobody /
docker container run --rm -it --cap-drop CHOWN alpine chown nobody / #błąd
docker container run --rm -it --cap-drop chown -u nobody alpine chown nobody / #błąd - nie ma możliwości aby dodać capabilities innemu użytkownikowi niż rootddd
```

### 11.6 AppArmor i SELinux

* Domyślny moduł bezpieczeństwa dla dystrybucji: Ubuntu, Debian (od wersji 10), OpenSUSE
* Zabezpiecza system operacyjny poprzez profile dla pojedynczych aplikacji lub kontenerów
* Pozwala kontrolować:
    * dostęp do plików
    * dostęp do sieci
    * wykonywanie zadań (chown, setuid etc)
* Tworzymy profile per kontener - nie per Docker Daemon
* Domyślnie każdy kontener uruchamiany jest z profilem docker-default
    ```bash
    docker run --rm -it --security-opt apparmor=docker-default hello-world
    # to samo co
    docker rum --rm -it hello-world
    ```
* Można uruchomić kontener bez żadnego profilu (nie zalecane)
    * `--security-opt apparmor=unconfined`
* `apparmor_status` - wyświetla status poszczególnych profilów

```bash
docker container run -dit --name apparmor1 alpine sh
apparmor_status
docker container rm -f apparmor1
docker container run -dit --name apparmor2 --security-opt apparmor=unconfined alpine sh
apparmor_status
docker container rm -f apparmor2
```

### 11.7 Skanowanie obrazów pod kątem bezpieczeństwa

1. Git scanning: Snyk.io, GitHub
2. Skanowanie podczas budowania obrazu: Aqua Microscanner
3. Skanowanie po zbudowaniu obrazu: Anchore, Clair, Trivy

### 11.9 Walidator obrazów

[Dockle](https://github.com/goodwithtech/dockle)

### 11.10 Weryfikacja hosta

* [Dockerbench](https://github.com/docker/docker-bench-security)
* Skrypt weryfikujący najlepsze praktyki - sprawdza Docker Hosta

