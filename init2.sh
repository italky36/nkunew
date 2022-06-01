#!/bin/bash

#Указать переменные
#Пароль traefik
traefik_pass="Error456"
#Почта для let`s encrypt
mail="italky2@mail.ru"
#Домен
domain="horsekfh.ru"
#Пароль от админки VPN
vpnpass="Error456"
#База данных
postgresdb="nodedb"
#Пользователь БД
postgresusr="pgadmin"
#Пароль БД
postgrespass="pgpass"

apt-get update && apt-get upgrade -y


#install docker
echo "install docker"
apt install apt-transport-https ca-certificates curl software-properties-common apache2-utils git -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt update
apt install docker-ce -y

#install docker-compose
echo "install docker-compose"
curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

touch acme.json
chmod 600 acme.json

traefikp=`htpasswd -nb admin $traefik_pass`

echo "Генерация конфигов"

echo -en "defaultEntryPoints = ["\"http\"", "\"https\""]

[entryPoints]
 [entryPoints.dashboard]
   address = "\":8080\""
   [entryPoints.dashboard.auth]
     [entryPoints.dashboard.auth.basic]
       users = ["\"$traefikp\""]
 [entryPoints.http]
   address = "\":80\""
     [entryPoints.http.redirect]
       entryPoint = "\"https\""
 [entryPoints.https]
   address = "\":443\""
     [entryPoints.https.tls]

[api]
entrypoint="\"dashboard\""

[acme]
 email = "\"$mail\""
 storage = "\"acme.json\""
 entryPoint = "\"https\""
 onHostRule = true
   [acme.httpChallenge]
   entryPoint = "\"http\""

[[acme.domains]]
  main = "\"$domain\""
  sans = ["\"www.$domain\"", "\"vpnsec.$domain\"","\"monitor.$domain\"","\"db.$domain\""]   

[docker]
 domain = "\"$domain\""
 watch = true
 network = "\"web\""
" > traefik.toml


echo -en "version: '3'

services:
  nodejs:
    build:
      context: .
      dockerfile: Dockerfile
    image: nodejs
    container_name: nodejs
    restart: unless-stopped
    labels:
      - traefik.backend=blog
      - traefik.frontend.rule=Host:$domain,www.$domain
      - traefik.docker.network=web
      - traefik.port=3000
    volumes:
      - ./db:/home/node/app/db/
    networks:
      - web

  wg-easy:
    environment:
      - WG_HOST=$domain
      - PASSWORD=$vpnpass
      - WG_PORT=51820
      - WG_DEFAULT_ADDRESS=10.0.0.x
      - WG_DEFAULT_DNS=1.1.1.1
      - WG_MTU=1420
      - WG_ALLOWED_IPS=10.0.0.0/24
    image: weejewel/wg-easy
    container_name: wg-easy
    volumes:
      - ./wireguard:/etc/wireguard
    ports:
      - "\"51820:51820/udp\""
      - "\"51821:51821/tcp\""
    restart: unless-stopped
    labels:
      - traefik.backend=vpnsec
      - traefik.frontend.rule=Host:vpnsec.$domain
      - traefik.docker.network=web
      - traefik.port=51821
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
    networks:
      - web

  traefik:
    image: "traefik:1.7.2-alpine"
    container_name: traefik
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "$PWD/acme.json:/acme.json"
      - "$PWD/traefik.toml:/traefik.toml"
    restart: unless-stopped
    ports:
      - 80:80
      - 443:443
    labels:
      - traefik.frontend.rule=Host:monitor.$domain
      - traefik.port=8080
    networks:
      - web

  db:
    image: "postgres:13.7-alpine"
    container_name: postgres
    volumes:
      - "$PWD/pgdata:/var/lib/postgresql/data/"
    environment:
      POSTGRES_DB: $postgresdb
      POSTGRES_USER: $postgresusr
      POSTGRES_PASSWORD: $postgrespass
    labels:
      - traefik.enable=false
    networks:
      - web

  adminer:
    image: adminer:latest
    container_name: adminer
    labels:
      - traefik.backend=adminer
      - traefik.frontend.rule=Host:db.$domain
      - traefik.docker.network=web
      - traefik.port=8080
    networks:
      - web
    depends_on:
      - db

networks:
  web:
    external: false" >  docker-compose.yml
  
docker-compose up -d

echo "Firewall setup"
echo "y" | ufw enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 51820/udp
