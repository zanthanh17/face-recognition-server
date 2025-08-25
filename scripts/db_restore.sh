#!/usr/bin/env bash
set -euo pipefail

# Restore Postgres backup using docker compose
# Usage: ./scripts/db_restore.sh /path/to/face-YYYYmmddTHHMMSSZ.dump

if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/backup.dump" >&2
  exit 1
fi

BACKUP_PATH="$1"
if [ ! -f "$BACKUP_PATH" ]; then
  echo "Backup file not found: $BACKUP_PATH" >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")"/.. && pwd)"
cd "$PROJECT_ROOT"

BASENAME="$(basename "$BACKUP_PATH")"
DEST="/tmp/$BASENAME"

echo "[+] Copying backup into container: $DEST"
docker compose cp "$BACKUP_PATH" db:"$DEST"

echo "[+] Dropping and recreating database 'face'"
docker compose exec -T db sh -lc "psql -U postgres -c \"DROP DATABASE IF EXISTS face;\" && psql -U postgres -c \"CREATE DATABASE face;\" && psql -U postgres -d face -c \"CREATE EXTENSION IF NOT EXISTS vector;\""

echo "[+] Restoring from dump"
docker compose exec -T db sh -lc "pg_restore -U postgres -d face '$DEST'"

echo "[+] Cleaning up"
docker compose exec -T db sh -lc "rm -f '$DEST'"

echo "[✓] Restore complete"






