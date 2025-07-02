# 13. Docker Swarm

### 13.1 Czym jest Docker Swarm

* [Play with Docker](https://labs.play-with-docker.com/)

### 13.2 Sieć overlay

```bash
docker swarm init
docker network create -d overlay myoverlay
docker network ls
docker container run -d -p 80:80 --name mynginx --network myoverlay nginx:1.17 #error - nie można podłączyć sieci do pojedynczego kontenera
docker network inspect myoverlay # "Attachable": false
docker network rm myoverlay
docker network create -d overlay --attachable myoverlay
docker network ls
docker container rm mynginx --force
docker container run -d -p 80:80 --name mynginx --network myoverlay nginx:1.17
docker network inspect myoverlay
```

### 13.3 Tworzenie klastra

```bash
# 1
docker swarm init --advertise-addr 192.168.0.13 
docker swarm join-token manager
docker swarm join-token worker
docker node ls
docker node promote node4
docker node ls
docker node demote node3
```

### 13.4 Docker Swarm Services
```bash
docker service create --name mynginx -d -p 8080:80 --replicas 3 nginx:1.16.1
docker service ls
docker service ps mynginx

docker service scale mynginx=6
docker service ls
docker service ps mynginx

docker service update --image nginx:1.17.8 mynginx
docker service ls
docker service ps mynginx

docker node update --availability drain manager2 #node2/manager2 przestaje być dostepny
docker service ls
docker service ps mynginx
```

### 13.5 Docker Swarm Stacks
```bash
cd 13.5
docker stack deploy --compose-file docker-compose.stack.yml app
docker stack rm app
docker stack rm mynginx
docker service ls

docker service ps app_vote
docker service scale app_vote=5
docker service ps app_vote

docker swarm leave
docker swarm leave --force
docker node ls
docker stack rm app
docker service ls
```

### 13.6 Docker Swarm Best Practices

* Manager node - statyczny adres IP
* Ilość hostów w trybie manager - minimum 3
* Regularne tworzenie backupów `/var/lib/docker/swarm`
* Przywracanie danych z backupów `/var/lib/docker/swarm`
  * `docker swarm init --force-new-cluster`
* Node Health Monitoring - HTTP API `/nodes`
