#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
REL=/tmp/yufams_release_src

rm -rf $REL
mkdir -p $REL

echo "=== 后端源码 ==="
tar -czf $REL/backend.tar.gz --exclude=target --exclude=files --exclude=.idea --exclude='*.iml' -C $BACK .
echo "=== 前端源码 ==="
tar -czf $REL/frontend.tar.gz --exclude=node_modules --exclude=dist --exclude=files -C $FRONT .
echo "=== 上传文件 ==="
tar -czf $REL/uploads.tar.gz -C $BACK files
echo "=== 数据库全量备份 ==="
mysqldump -uroot -pYOUR_DB_PASSWORD \
  --single-transaction --quick --routines --triggers \
  --default-character-set=utf8mb4 --set-gtid-purged=OFF \
  xm-assets > $REL/xm-assets_full.sql
gzip -9 -f $REL/xm-assets_full.sql
echo "=== 部署配置 ==="
cp /etc/systemd/system/yufams.service $REL/yufams.service
cp /www/server/panel/vhost/nginx/yufams.conf $REL/nginx-yufams.conf

ls -lh $REL
echo RELEASE_SRC_DONE
