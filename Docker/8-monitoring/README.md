# 8. Monitoring

### 8.1 Wstęp do monitoringu
```bash
docker stats

#
docker container run -d --name apache1 httpd
docker container run -d --name apache2 httpd
docker container run -d --name redis1 redis
docker container run -d --name redis2 redis
docker container ls
docker container stats
docker container stats --no-stream
```

### 8.2 Limitowanie zasobów poszczególnym kontenerom
```bash
docker run -d -p 6370:6379 --memory="600M" --cpus="0.6" --name redis redis

#
docker container run -d -p 8081:80 --memory="256M" --cpus="0.6" nginx
docker container run  --memory="50M" --rm busybox free -m
docker run --memory 50m --rm -it progrium/stress --vm 1 --vm-bytes 62914560 --timeout 3s
docker container run -it --cpus=".5" ubuntu bash
```

### 8.3 Prosty monitoring
* [cAdvisor](https://github.com/google/cadvisor)

```bash
docker container run -d --name apache1 httpd
docker container run -d --name apache2 --memory="100m" httpd
docker container run -d --name redis1 redis
docker container run -d --name redis2 --memory="30m" redis
docker container ls
docker container stats
sudo docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  gcr.io/cadvisor/cadvisor:v0.37.0
```

### 8.4 Zaawansowany monitoring
```bash
git clone https://github.com/bpelikan/dockprom
cd dockprom
ls -l
cat docker-compose.yml
ADMIN_USER=admin ADMIN_PASSWORD=fir854jgyndu43fu docker-compose up -d
docker-compose ps
```

### 8.5 Monitoring as a Service
* [ScoutAPM](https://scoutapm.com/)
* [DataDog](https://www.datadoghq.com/)
* [Sysdig](https://sysdig.com/)
* [Sematext](https://sematext.com/)