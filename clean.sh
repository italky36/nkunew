#!/bin/bash
cd /root/nkunew
docker-compose  down
echo "y" | docker system prune -a
