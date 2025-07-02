# 5. Komunikacja pomiędzy kontenerami

### 5.1 Sieć typu bridge
```bash
docker network create -d bridge mybridge
docker run -d --net mybridge --name db postgress:9.6
docekr run -d --net mybridge -e DB=db -p 8080:3000 --name web mywebapp:1.0

#
docker container run -itd --name ubuntu1 ubuntu bash
docker container run -itd --name ubuntu2 ubuntu bash
docker container inspect ubuntu1
# pobranie adresu IP kontenera ubuntu1- 172.17.0.2
docker container exec -it ubuntu2 bash
  apt-get update && apt-get install -y iputils-ping
  ping ubuntu1
  ping 172.17.0.2
  exit
docker network ls
docker network inspect bridge
docker network create -d bridge custombridge
docker network ls
docker container run -itd --name ubuntu3 --net custombridge ubuntu bash
docker container run -itd --name ubuntu4 --net custombridge ubuntu bash
docker container ls
docker container inspect ubuntu3  #IP: 172.18.0.2
docker container exec -it ubuntu4 bash
  apt-get update && apt-get install -y iputils-ping
  ping ubuntu3
  ping 172.18.0.2
  exit
docker network connect custombridge ubuntu1 #kontener podłączony do 2 sieci
docker network inspect custombridge
docker network inspect bridge
docker container inspect ubuntu1
docker network disconnect custombridge ubuntu4
docker container inspect ubuntu4
```

### 5.2 Komunikacja pomiędzy kontenerami - Wordpress i MySQL
```bash
docker network create -d bridge wp
docker container run -d -p 3308:3306 --name db -e MYSQL_DATABASE=exampledb -e MYSQL_USER=exampleuser -e MYSQL_PASSWORD=examplepass -e MYSQL_RANDOM_ROOT_PASSWORD=1 --network=wp mysql:5.7
docker container run -d -p 8080:80 -e WORDPRESS_DB_HOST=db:3306 -e WORDPRESS_DB_USER=exampleuser -e WORDPRESS_DB_PASSWORD=examplepass -e WORDPRESS_DB_NAME=exampledb --network=wp wordpress:latest
docker container ls
curl localhost:8080
```

### 5.3 Sterownik sieciowy HOST
```bash
docker run -d --network host --name db postgress
docker run -d --network host --name web mywebapp

#
docker container run -d --name db -e MYSQL_DATABASE=exampledb -e MYSQL_USER=exampleuser -e MYSQL_PASSWORD=examplepass -e MYSQL_RANDOM_ROOT_PASSWORD=1 --network=host --name mysql-hostnet mysql:5.7
docker container run -d --name wp -e WORDPRESS_DB_HOST=127.0.0.1:3306 -e WORDPRESS_DB_USER=exampleuser -e WORDPRESS_DB_PASSWORD=examplepass -e WORDPRESS_DB_NAME=exampledb --network=host wordpress:latest
docker container ls
docker container inspect wp
```

### 5.4 Sterownik sieciowy MACVLAN
```bash
docker network create -d macvlan --subnet=10.0.1.0/24 --gateway=10.0.1.1 -o parent=eth0 mymacvlan
docker run --network mymacvlan -e DB=10.0.1.2 --name web mywebapp

#
docker network create -d macvlan --subnet=10.0.0.0/24 --gateway=10.0.0.1 -o parent=eth0 mymacvlan
docker network ls
docker container run -itd --name ubuntu1 --net mymacvlan ubuntu bash
docker network inspect mymacvlan
ifconfig
```

### 5.5 Podłączanie kontenerów do sieci innego kontenera
```bash
docker network create -d bridge mynet
docker container run -itd --name ubuntu1 --net mynet ubuntu bash
docker container run -it --name ubuntu2 --network container:ubuntu1 ubuntu bash  #podłączenie do tej samej sieci co kontener ubuntu1
  apt-get update && apt-get install -y iputils-ping
  ping ubuntu1
```