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

traefikpass=`htpasswd -nb admin $traefikpass`

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
