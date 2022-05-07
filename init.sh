#!/bin/bash
apt-get update && apt-get upgrade -y


#install docker
echo "install docker"
apt install apt-transport-https ca-certificates curl software-properties-common apache2-utils git -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt update
apt install docker-ce

#install docker-compose
echo "install docker-compose"
curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

touch acme.json
chmod 600 acme.json

read -p "Введите пароль от traefik: " traefiks
traefikp=`htpasswd -nb admin $traefiks`

read -p "Введите почту для сертификата: " mail

read -p "Введите домен: " domain

read -p "Введите пароль от wireguard: " vpnpass

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

networks:
  web:
    external: true" >  docker-compose.yml

docker network create web

docker run -d --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $PWD/traefik.toml:/traefik.toml \
  -v $PWD/acme.json:/acme.json \
  -p 80:80 \
  -p 443:443 \
  -l traefik.frontend.rule=Host:monitor.$domain \
  -l traefik.port=8080 \
  --network web \
  --name traefik \
  traefik:1.7.2-alpine
  
docker-compose up -d

echo "Firewall setup"
ufw enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 51820/udp
