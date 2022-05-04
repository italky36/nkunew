Для перезапуска сайта:

docker-compose up --force-recreate --no-deps nodejs

Для перезапуска vpn:

docker-compose up --force-recreate --no-deps wg-easy

Для первичной настройки:

git clone https://github.com/italky36/nkunew && chmod +x init.sh && bash init.sh
