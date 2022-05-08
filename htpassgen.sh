#!/bin/bash

apt update
apt install apache2-utils -y

grep -v "traefikpass" .env > temp && mv temp .env

read -p "Введите пароль от traefik: " traefikp
traefikp=`htpasswd -nb admin $traefikp`

echo -en "traefikpass = $traefikp" >> .env
