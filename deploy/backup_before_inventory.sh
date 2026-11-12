#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
TS=$(date +%Y%m%d_%H%M%S)
DIR=/opt/yu-fams/backup/manual_$TS
mkdir -p "$DIR"

echo "=== 1. 数据库 ==="
mysqldump -uroot -pYOUR_DB_PASSWORD \
  --single-transaction --quick --routines --triggers \
  --default-character-set=utf8mb4 --set-gtid-purged=OFF \
  xm-assets | gzip -9 > "$DIR/db_xm-assets.sql.gz"
gunzip -t "$DIR/db_xm-assets.sql.gz"

echo "=== 2. 上传文件 ==="
tar -czf "$DIR/uploads.tar.gz" -C "$BACK" files
tar -tzf "$DIR/uploads.tar.gz" > /dev/null

echo "=== 3. 后端源码 ==="
tar -czf "$DIR/backend-src.tar.gz" --exclude=target --exclude=files --exclude=.idea --exclude='*.iml' -C "$BACK" .
tar -tzf "$DIR/backend-src.tar.gz" > /dev/null

echo "=== 4. 前端源码 ==="
tar -czf "$DIR/frontend-src.tar.gz" --exclude=node_modules --exclude=dist --exclude=files -C "$FRONT" .
tar -tzf "$DIR/frontend-src.tar.gz" > /dev/null

echo "=== 5. 运行配置 ==="
CONFIG_FILES="etc/systemd/system/yufams.service www/server/panel/vhost/nginx/yufams.conf"
[ -f /opt/yu-fams/yufams.env ] && CONFIG_FILES="$CONFIG_FILES opt/yu-fams/yufams.env"
tar -czf "$DIR/config.tar.gz" -C / $CONFIG_FILES

echo "=== 6. 校验和 ==="
cd "$DIR"
sha256sum * > SHA256SUMS.txt
ls -lh "$DIR"

echo "=== 7. 汇总包 ==="
tar -czf "/tmp/yufams_backup_$TS.tar.gz" -C /opt/yu-fams/backup "manual_$TS"
ls -lh "/tmp/yufams_backup_$TS.tar.gz"
echo "BACKUP_DIR=$DIR"
echo "BACKUP_TGZ=/tmp/yufams_backup_$TS.tar.gz"
echo "BACKUP_TS=$TS"
echo BACKUP_DONE
