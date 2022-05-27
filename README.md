README.md
=========
Удаление неиспользуемых образов:
     
     docker system prune -a
     
Для перезапуска сайта:

    docker-compose up -d --force-recreate --no-deps nodejs

Для перезапуска vpn:

    docker-compose up -d --force-recreate --no-deps wg-easy

Для первичной настройки:

    git clone https://github.com/italky36/nkunew && chmod +x init.sh && bash init.sh
