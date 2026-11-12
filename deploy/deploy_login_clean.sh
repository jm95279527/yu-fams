#!/bin/bash
set -e
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage16

echo "=== backup ==="
mkdir -p /tmp/stage16bak
cp $FRONT/src/views/Login.vue /tmp/stage16bak/
echo BACKUP_OK

cp $SRC/frontend/views/Login.vue $FRONT/src/views/
echo "--- 残留检查（应无输出）---"
grep -n -E '第三方登录|wechatLogin|dingTalkLogin|企业微信登录|钉钉登录' $FRONT/src/views/Login.vue || echo "CLEAN_OK"

echo "=== build frontend ==="
cd $FRONT
npm run build > $SRC/build.log 2>&1
echo NPM_OK
ls -la dist/index.html

echo "=== publish ==="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
curl -s -o /dev/null -w "front88=%{http_code}\n" http://127.0.0.1:88/
curl -s -o /dev/null -w "login89=%{http_code}\n" -X POST http://127.0.0.1:89/login
echo STAGE16_DONE
