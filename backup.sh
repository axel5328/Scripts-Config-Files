#!/bin/bash

set -e

# .env laden
set -a
source /home/axel/docker/nextcloud/.env
set +a

DATE=$(date +%F)

echo "=== Nextcloud Maintenance Mode ON ==="
docker exec -u www-data nextcloud php occ maintenance:mode --on

echo "=== Daten sichern ==="
rsync -aHAX --delete --info=progress2 \
  /mnt/data/nextcloud/ \
  /mnt/backup-usb/nextcloud/data/

echo "=== Datenbank dumpen ==="
docker exec nextcloud-db mariadb-dump \
  -u root \
  -p"$MYSQL_ROOT_PASSWORD" \
  "$MYSQL_DATABASE" \
  > /mnt/backup-usb/nextcloud/db/nextcloud-db-$DATE.sql

echo "=== Maintenance Mode OFF ==="
docker exec -u www-data nextcloud php occ maintenance:mode --off

echo "=== Backup abgeschlossen ==="
