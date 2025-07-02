# 4. Praca z obrazami

### 4.1 Docker Hub i repozytoria
```bash
docker image pull alpine:3.7
docker image ls
docker image pull alpine:3.9
```

### 4.2 Tagowanie i publikowanie obrazów na Docker Hub
```bash
docker image pull alpine:3.9
docker image tag alpine:3.9 bpelikan/alpine:3.9
docker image ls
docker login
docker image push bpelikan/alpine:3.9
docker image rm bpelikan/alpine:3.9
docker image pull bpelikan/alpine:3.9
docker container run --name myalpine1 bpelikan/alpine:3.9
docker container run --name myalpine2 -it bpelikan/alpine:3.9 sh
  exit
docker images ls
docker image pull alpine:3.7
docker image tag alpine:3.7 bpelikan/alpine:3.7
docker image push bpelikan/alpine:3.7
```

### 4.4 Dockerfile
```bash
cd 4.4
ls -l
docker image build -t myalpine . 
docker container run --name alpine1 myalpine:latest
```

<details>
  <summary><b><i>Dockerfile</i></b></summary>

```Dockerfile
FROM alpine:3.9

COPY text.txt .

CMD ["cat", "text.txt"]
```
</details>

### 4.5 Rozszerzenie oficjalnych obrazów
```bash
cd 4.5
docker container run -d --name nginx11 nginx:latest
docker container cp nginx11:/usr/share/nginx/html/index.html index.html
ls
docker image build -t mynginx:latest .
docker container run -d --name mynginx11 mynginx:latest
docker container run --name mynginx12 -d -p 8081:80 mynginx:latest 
curl http://localhost:8081/
```

<details>
  <summary><b><i>Dockerfile</i></b></summary>

```Dockerfile
FROM nginx:latest

COPY index.html /usr/share/nginx/html

CMD ["nginx", "-g", "daemon off;"]
```
</details>

### 4.6 Budowanie własnego obrazu - czyli konteneryzacja aplikacji
```bash
cd 4.6
docker image build -t myapp:1.0 .
docker container run -d -p 8081:8080 --name myapp1 myapp:1.0
docker image build -t myapp:2.0 .
docker container run -d -p 8082:8080 --name myapp2 myapp:2.0
docker container ls
```

### 4.7 Warstwowa budowa obrazu
```bash
docker manifest inspect <image>
docker image history ubuntu
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive:latest ubuntu
```

### 4.8 Mutli-stage builds
```bash
cd 4.8
docker image build -t myreact:latest .
docker container run -d -p 8082:80 --name react-prod myreact:latest
docker image build --target development --build-arg NODE_ENV=development -t react-dev .
docker container run -d -p 3000:3000 --name react-dev react-dev:latest
docker image inspect react-dev:latest
docker image inspect myreact:latest
```

### 4.10 Docker Linter

* [Hadolint](https://github.com/hadolint/hadolint) - narzędzie do walidacji oraz optymalizacji plików Dockerfile