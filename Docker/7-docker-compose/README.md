# 7. Docker-compose

### 7.1 Wprowadzenie do docker-compose

```yml
version: '3.7'

services:
  servicename: # WYMAGANE: dowolna nazwa ustalona przez Ciebie
    image: # OPCJONALNE: może być pominięty gdy korzystamy z "build"
    container_name: # OPCJONALNE: wymuszamy nazwę kontenera.
    command: # OPCJONALNE: możemy zastąpić CMD z Dockerfile
    ports: # OPCJONALNE: mapujemy porty
    environment: # OPCJONALNE: zmienne środowiskowe. przykład: "-e MY_SQL_PASSWORD=1"
    volumes: # OPCJONALNE: odpowiednik "-v" w docker container run
  servicename-2:
    image: # OPCJONALNE: może być pominięty gdy korzystamy z "build"
    restart: # OPCJONALNE: określamy politykę restartów
      
volumes: # OPCJONALNE

networks: # OPCJONALNE
```

```bash
cd 7.1
docker-compose up
docker container ls -a
docker-compose up -d
docker-compose ps
docker-compose down
docker container ls -a
docker volume ls
docker-compose down -v #-v usuwa również utworzone volumeny
```

### 7.2 Automatyczne budowanie obrazów
```bash
docker-compose build # wymusza przebudowanie obrazu
docker-compose up --build # wymusza przebudowanie obrazu

#
cd 7.2
docker-compose config
docker-compose build
docker-compose up -d
docker-compose down
# zmiana w pliku 7.2/ui/src/App.js
docker-compose build
docker-compose up -d
docker-compose down
```

### 7.3 Zmienne środowiskowe
Plik `.env` 
* zmienne środowiskowe na hoście mają większy priorytet
* zmienne środowiskowe zdefiniowane w terminalu mają najwyższy priorytet
lub `env_file` do załączenia w docker-compose.yml
* przekazanie zmiennych bezpośrednio do kontenera

```bash
docker-compose config
export DB_NAME="FromShellDbName"
docker-compose config
docker-compose -f docker-compose.envfile.yml config
docker-compose up -d
docker-compose down
```

### 7.4 Wiele instancji na podstawie tego samego pliku YAML
```bash
cd 7.4
export WP_PORT="9091" #$Env:WP_PORT="9091" dla PowerShella
docker-compose -p dev up -d
export WP_PORT="9092"
docker-compose -p staging up -d
export WP_PORT="9093"
docker-compose -p prod up -d
docker container ls
docker-compose -p prod down
docker-compose -p staging down
docker-compose -p dev down
docker container ls
```

### 7.5 Łączenie plików docker-compose.yml
```bash
cd 7.5
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up 
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up 
```

### 7.6 Zewnętrzna sieć
```bash
docker network create -d bridge myproject-external-network
docker-compose -f docker-compose.vault.yml up -d
docker-compose -f docker-compose.vault.yml ps
docker container run -it --net myproject-external-network ubuntu bash
  apt-get update && apt-get install -y iputils-ping
  ping vault
  exit
```

### 7.7 Tworzenie docker-compose yml na podstawie docker container run
* Narzędzie [composerize](https://github.com/magicmark/composerize)
```bash
node --version
npm install composerize -g
composerize docker run -p 80:80 --restart always --name composerize-nginx nginx:1.17
composerize docker run -d -p 3308:3306 --name db -e MYSQL_DATABASE=exampledb -e MYSQL_USER=exampleuser -e MYSQL_PASSWORD=examplepass -e MYSQL_RANDOM_ROOT_PASSWORD=1 --network=wp mysql:5.7
composerize docker run -d -p 8080:80 -e WORDPRESS_DB_HOST=db:3306 -e WORDPRESS_DB_USER=exampleuser -e WORDPRESS_DB_PASSWORD=examplepass -e WORDPRESS_DB_NAME=exampledb --network=wp wordpress:latest
```