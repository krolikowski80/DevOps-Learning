# DockerNotes

* [3. Uruchamianie kontenerów](./3-uruchamianie-kontenerów/README.md)

* [4. Praca z obrazami](./4-praca-z-obrazami/README.md)

* [5. Komunikacja pomiędzy kontenerami](./5-komunikacja-pomiedzy-kontenerami/README.md)

* [6. Trwałość danych kontenera](./6-trwałocs-danych-kontenera/README.md)

* [7. Docker-compose](./7-docker-compose/README.md)

* [8. Monitoring](./8-monitoring/README.md)

* [9. Dodatkowe narzędzia](./9-dodatkowe-narzedzia/README.md)

* [10. Docker Advanced](./10-docker-advanced/README.md)

* [11. Bezpieczeństwo](./11-bezpieczenstwo/README.md)

* [12. DevOps](./12-devops/README.md)

* [13. Docker Swarm](./13-docker-swarm/README.md)




### Instalacja Dockera na Ubuntu
```bash
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

sudo passwd
su -
```