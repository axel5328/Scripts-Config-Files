#!/usr/bin/env bash
set -euo pipefail

STACK_ROOT="/opt/stacks"
NEXTCLOUD_STACK="$STACK_ROOT/nextcloud"
BACKUP_STACK="/opt/stacks/backup"

DATA_ROOT="/mnt/data"
BACKUP_ROOT="/mnt/backup-usb"

NEXTCLOUD_DATA="$DATA_ROOT/nextcloud/"
BACKUP_TARGET="$BACKUP_ROOT/nextcloud/"

DATE=$(date +%F)

send_matrix() {
  local msg="$1"
  local txn_id
  txn_id="$(date +%s%N)"

  curl -fsSL -X PUT \
    "$MATRIX_HOMESERVER/_matrix/client/v3/rooms/${MATRIX_ROOM_ID}/send/m.room.message/${txn_id}" \
    -H "Authorization: Bearer $MATRIX_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    --data-raw "$(jq -n --arg body "$msg" '{
      msgtype: "m.text",
      body: $body
    }')" >/dev/null || echo "WARN: Matrix-Benachrichtigung fehlgeschlagen"
}

if [[ ! -f "$BACKUP_STACK/.env" ]]; then
  echo "ERROR: Backup .env fehlt!"
  exit 1
fi

set -a
source "$NEXTCLOUD_STACK/.env"
source "$BACKUP_STACK/.env"
set +a

if ! mountpoint -q "$BACKUP_ROOT"; then
  echo "ERROR: Backup-Ziel ist nicht gemountet: $BACKUP_ROOT"
  send_matrix "❌ Nextcloud Backup fehlgeschlagen: Backup-Ziel ist nicht gemountet ($BACKUP_ROOT)"
  exit 1
fi

mkdir -p "$BACKUP_TARGET/data" "$BACKUP_TARGET/db"

START_TOTAL=$(date +%s)

echo "=== Nextcloud Maintenance Mode ON ==="
docker exec -u www-data nextcloud php occ maintenance:mode --on

echo "=== Daten sichern ==="
START_RSYNC=$(date +%s)

rsync -rlptDH --delete \
  --info=stats2,progress2 \
  --exclude='appdata_*' \
  --exclude='updater-*/' \
  --exclude='*.part' \
  "$NEXTCLOUD_DATA/" \
  "$BACKUP_TARGET/data/"

END_RSYNC=$(date +%s)

echo "=== Datenbank dumpen ==="
START_DB=$(date +%s)

docker exec nextcloud-db mariadb-dump \
  -u root \
  -p"$MYSQL_ROOT_PASSWORD" \
  --single-transaction \
  --quick \
  "$MYSQL_DATABASE" \
  | gzip -1 > "$BACKUP_TARGET/db/nextcloud-db-$DATE.sql.gz"

END_DB=$(date +%s)

echo "=== Maintenance Mode OFF ==="
docker exec -u www-data nextcloud php occ maintenance:mode --off

END_TOTAL=$(date +%s)

RSYNC_TIME=$((END_RSYNC - START_RSYNC))
DB_TIME=$((END_DB - START_DB))
TOTAL_TIME=$((END_TOTAL - START_TOTAL))

echo "=== Backup abgeschlossen ==="

send_matrix "✅ Nextcloud Backup abgeschlossen
Datum: $DATE
Gesamt: ${TOTAL_TIME}s
Dateien: ${RSYNC_TIME}s
Datenbank: ${DB_TIME}s"
