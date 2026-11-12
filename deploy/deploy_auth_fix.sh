#!/bin/bash
set -e
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage36
cd $FRONT
echo "=== backup ==="
rm -rf /tmp/stage36bak
mkdir -p /tmp/stage36bak
cp src/utils/request.js src/views/manager/NumberRule.vue /tmp/stage36bak/
echo BACKUP_OK

echo "=== sync ==="
cp -r $SRC/frontend/. src/
echo SYNC_OK

echo "=== build frontend ==="
npm run build > $SRC/build-front.log 2>&1
echo NPM_OK

echo "=== publish ==="
rm -rf /www/wwwroot/yufams/*
cp -r dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
echo PUBLISH_OK

echo "=== 产物包含失效码处理 ==="
grep -rl "登录已过期" /www/wwwroot/yufams/js | head -3
echo AUTH_FIX_DONE
