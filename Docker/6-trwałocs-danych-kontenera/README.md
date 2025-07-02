# 6. Trwałość danych kontenera

### 6.1 Dane kontenera oraz zapisywanie zmian zachodzących w kontenerze
```bash
# Zapisanie stanu kontenera jako obraz
docker container commit <CONTAINER_NAME> <IMAGE_NAME:TAG>
docker container commit my_ubuntu myubuntu:1.0

# 
docker container run -d -p 8080:80 --name mynginx nginx:latest
cd /var/lib/docker
sudo ls
cd containers
sudo su
cd containers
ls  ##katalogi o nazwach jak id kontenerów
docker exec -it mynginx bash
  apt-get update && apt-get install -y vim
  vi /usr/share/nginx/html/index.html
  exit
curl localhost:8080
docker container inspect mynginx | grep MergedDir # zapisanie zwróconej ścieżki
cd ..
cd overlay2
cd 7b24103b409d41442c466569b348189c73b8be1fc0049d7433bc7e90a6655faa
ls -l
cd merged
cat ./usr/share/nginx/html/index.html
cd /
docker container commit mynginx mynginx:1.0
docker image ls
docker container run -d -p 8081:80 --name mynginx1 mynginx:1.0
curl localhost:8081
docker container rm mynginx --force
docker container run -d -p 8080:80 --name mynginx nginx:latest
curl localhost:8080
curl localhost:8081
```

### 6.2 Volumeny
Wolumeny:
* Domyślne (w Dockerfile): VOLUME /var/lib/postgresql/data
* Nazwane: docker volume create <volume_name>

Wolumeny nazwane:
```bash
docker container run -d -p 5432:5432 --name db -v dbdata:/var/lib/postgresql/data postgres:9.6
# lub
docker volume create dbdata
docker container run -d -p 5432:5432 --name db -v dbdata:/var/lib/postgresql/data postgres:9.6
```

```bash
docker container run -d -p 5432:5432 -e POSTGRES_PASSWORD=test123 --name db postgres:9.6
docker volume ls
docker image inspect postgres:9.6
docker container ls
docker container rm db --force
docker volume ls
docker volume rm 99fb6d762e845d61b348175f4a320c40714bab383cb4819b5584c4f43ec44704

docker container run -d -p 5432:5432 -e POSTGRES_PASSWORD=test123 --name db1 -v my-volume:/var/lib/postgresql/data postgres:9.6
docker volume ls
docker volume inspect my-volume
docker container rm db1 --force
docker volume ls
docker volume prune #czyście wszystkie nieużywane volumeny
# docker system prune #czyści wszystkie nieużywane elementy
docker volume ls
```

### 6.3 Współdzielenie volumenów
```bash
docker volume create myvolume1
docker container run -it --name u1 -v myvolume1:/myvolume1 ubuntu
  ls -lah
  echo "testowy plik 123" > /myvolume1/test.txt
  cat /myvolume1/test.txt
  exit
docker container run -it --name u2 --volumes-from u1 ubuntu
  cat /myvolume1/test.txt
  echo "testowy plik2 123" > /myvolume1/test2.txt
  cat /myvolume1/test2.txt
  exit
docker container ls -a
docker container start -ai u1 #wystartowanie i ponowne wejście do kontenera
  cat /myvolume1/test2.txt
  cat /myvolume1/test.txt
  exit
docker container run -it --name u3 --volumes-from u1:ro ubuntu #ro - read-only
  cat /myvolume1/test.txt
  cat /myvolume1/test2.txt
  rm /myvolume1/test.txt  # brak dostępu
  echo "testowy plik3 123" > /myvolume1/test3.txt #brak dostępu
  exit
```

### 6.4 Bind Mounts
```bash
mkdir -p /var/db/pgdata
docker container run -d -p 5432:5432 --name db -v /var/db/pgdata:/var/lib/postgresql/data postgres:9.6

#
sudo mkdir -p /var/db/pgdata
sudo su
docker container run -d -p 5432:5432 --name db2 -e POSTGRES_PASSWORD=test123 -v /var/db/pgdata:/var/lib/postgresql/data postgres:9.6
cd /var/db/pgdata

git clone https://github.com/dnaprawa/first_app_in_docker
cd first_app_in_docker
ls -l
cat Dockerfile
docker build -t first_app:1.0 .
docker container run -d -p 8080:80 --name first_app_container --mount type=bind,source="$(pwd)",target=/usr/share/nginx/html first_app:1.0
ls
vi index.html
```

### 6.5 Zadanie domowe
```bash
docker volume create mysqldata
docker volume ls
docker image pull mysql:5.6.47
docker container run -d --name db -e MYSQL_RANDOM_ROOT_PASSWORD=yes -v mysqldata:/var/lib/mysql mysql:5.6.47
docker container logs db
# [Note] [Entrypoint]: GENERATED ROOT PASSWORD: ooD0mie8pheej9oiquaiJaithaekieg0
docker container rm db --force
docker volume ls
docker container run -d --name db2 -e MYSQL_RANDOM_ROOT_PASSWORD=yes -v mysqldata:/var/lib/mysql mysql:5.6.48
docker container logs db2
docker container ls
MYSQL_ROOT_PASSWORD=ooD0mie8pheej9oiquaiJaithaekieg0
MYSQL_ROOT_PASSWORD=piR7re1Eizeed7au5voo0raiNg1iep0b
echo $MYSQL_ROOT_PASSWORD
docker container exec db2 sh -c 'exec mysqldump --all-databases -u root -p "$MYSQL_ROOT_PASSWORD" > /home/all-db.sql'
docker container exec db sh -c 'exec mysqldump --all-databases -u root -p "$MYSQL_ROOT_PASSWORD" > ./all-db.sql'
```