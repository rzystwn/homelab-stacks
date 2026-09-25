#!/bin/bash
# Backup semua service + config sebelum clean install OS
# Target: /mnt/data/Backups/server_backup_YYYY-MM-DD

DATE=$(date +%Y-%m-%d_%H%M)
BACKUP_DIR="/mnt/data/Backups/server_backup_$DATE"
mkdir -p "$BACKUP_DIR"

echo "=== Backup dimulai: $DATE ==="
echo "Target: $BACKUP_DIR"
echo ""

# 1. Backup /opt/stacks (semua compose files + config + bind mount data)
echo "[1/5] Backup /opt/stacks ..."
cp -r /opt/stacks "$BACKUP_DIR/stacks"
echo "    Done: $BACKUP_DIR/stacks"

# 2. Backup Immich PostgreSQL database
echo "[2/5] Dump Immich DB ..."
docker exec immich_postgres pg_dumpall -U postgres > "$BACKUP_DIR/immich_db.sql"
echo "    Done: $BACKUP_DIR/immich_db.sql ($(du -sh "$BACKUP_DIR/immich_db.sql" | cut -f1))"

# 3. Backup Samba Docker volumes (etc/config)
echo "[3/5] Backup Samba volumes ..."
mkdir -p "$BACKUP_DIR/samba_volumes"
for VOL in \
  "2731cf24d20d2b40783e598889f076f77474a1a27b8f37d894470f0a7854c11f" \
  "095ff4ebcf69b4b33e008b8fb967a48a0a7e863147dc08e0c4fe0bd2b64d74b1" \
  "71010d668007a96d01c2311f23594fbe66dc0834f55fd866b2816b4bb141d9ed" \
  "4c4233ead6a1cb5b3600a459a8004f9f24d9fcc74340ca9cb247b830ded7730b" \
  "5cd7ac64bf454dddf38ffa271026a12809bfde12eaf88d395c1b47190c00d140"; do
  SRC="/var/lib/docker/volumes/$VOL/_data"
  DEST="$BACKUP_DIR/samba_volumes/$VOL"
  if [ -d "$SRC" ]; then
    cp -r "$SRC" "$DEST"
    echo "    Copied volume: $VOL"
  fi
done

# 4. Backup Portainer + Syncthing volumes
echo "[4/5] Backup Portainer & Syncthing volumes ..."
mkdir -p "$BACKUP_DIR/named_volumes"
docker run --rm \
  -v portainer_data:/src:ro \
  -v "$BACKUP_DIR/named_volumes":/dst \
  alpine tar czf /dst/portainer_data.tar.gz -C /src .
docker run --rm \
  -v "ba91be1c6f76ef8118f16985a4d991911eb1436d8db23cf5e1704feb8f57e0ec":/src:ro \
  -v "$BACKUP_DIR/named_volumes":/dst \
  alpine tar czf /dst/syncthing_data.tar.gz -C /src . 2>/dev/null || echo "    Syncthing volume skip (volume ID mungkin berbeda)"
echo "    Done: $BACKUP_DIR/named_volumes"

# 5. Backup Hermes profile
echo "[5/5] Backup ~/.hermes ..."
cp -r /home/kazor/.hermes "$BACKUP_DIR/hermes"
echo "    Done: $BACKUP_DIR/hermes"

# Summary
echo ""
echo "=== Backup selesai ==="
du -sh "$BACKUP_DIR"
echo ""
echo "Isi backup:"
ls -lh "$BACKUP_DIR"

echo ""
echo "=== RESTORE GUIDE ==="
cat << 'EOF'
Setelah clean install Arch + Docker:

1. Mount HDD:
   sudo mount /dev/sdX1 /mnt/data

2. Restore stacks:
   sudo cp -r /mnt/data/Backups/server_backup_TANGGAL/stacks /opt/stacks

3. Restore Immich DB:
   cd /opt/stacks/immich && docker compose up -d immich_postgres
   sleep 10
   cat /mnt/data/Backups/server_backup_TANGGAL/immich_db.sql | docker exec -i immich_postgres psql -U postgres

4. Restore Samba volumes:
   (lihat folder samba_volumes, copy ke /var/lib/docker/volumes/<id>/_data)

5. Jalankan semua stack:
   for d in /opt/stacks/*/; do cd "$d" && docker compose up -d; done

6. Restore Hermes:
   curl -fsSL https://hermes-agent.nousresearch.com/install.sh | sh
   cp -r /mnt/data/Backups/server_backup_TANGGAL/hermes ~/.hermes
   hermes
EOF
