#!/bin/bash


docker stop traefik
docker rm traefik
docker-compose  down
echo "y" | docker system prune -a
