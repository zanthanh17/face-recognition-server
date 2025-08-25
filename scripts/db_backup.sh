#!/usr/bin/env bash
set -euo pipefail

# Simple Postgres backup using docker compose
# Usage: ./scripts/db_backup.sh [output_dir]

PROJECT_ROOT="$(cd "$(dirname "$0")"/.. && pwd)"
cd "$PROJECT_ROOT"

OUT_DIR="${1:-$PROJECT_ROOT/backups}"
mkdir -p "$OUT_DIR"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
FNAME="face-${TS}.dump"
TMP_PATH="/tmp/${FNAME}"

echo "[+] Creating DB dump inside container: $TMP_PATH"
docker compose exec -T db sh -lc "pg_dump -U postgres -d face -F c -f '$TMP_PATH'"

echo "[+] Copying dump to host: $OUT_DIR/$FNAME"
docker compose cp db:"$TMP_PATH" "$OUT_DIR/$FNAME"

echo "[+] Cleaning up container temporary file"
docker compose exec -T db sh -lc "rm -f '$TMP_PATH'"

echo "[✓] Backup complete: $OUT_DIR/$FNAME"






