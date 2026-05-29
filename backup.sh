#!/bin/bash
set -euo pipefail

STACK_ROOT="/opt/stacks"
NEXTCLOUD_STACK="$STACK_ROOT/nextcloud"

DATA_ROOT="/mnt/data"
BACKUP_ROOT="/mnt/backup-usb"

NEXTCLOUD_DATA="$DATA_ROOT/nextcloud"
BACKUP_TARGET="$BACKUP_ROOT/nextcloud"

DATE=$(date +%F)

set -a
source "$NEXTCLOUD_STACK/.env"
set +a

mkdir -p "$BACKUP_TARGET/data" "$BACKUP_TARGET/db"

echo "=== Nextcloud Maintenance Mode ON ==="
docker exec -u www-data nextcloud php occ maintenance:mode --on

echo "=== Daten sichern ==="
rsync -aHAX --delete --info=progress2 \
  "$NEXTCLOUD_DATA/" \
  "$BACKUP_TARGET/data/"

echo "=== Datenbank dumpen ==="
docker exec nextcloud-db mariadb-dump \
  -u root \
  -p"$MYSQL_ROOT_PASSWORD" \
  "$MYSQL_DATABASE" \
  > "$BACKUP_TARGET/db/nextcloud-db-$DATE.sql"

echo "=== Maintenance Mode OFF ==="
docker exec -u www-data nextcloud php occ maintenance:mode --off

echo "=== Backup abgeschlossen ==="
