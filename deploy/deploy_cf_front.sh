#!/bin/bash
set -e
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage31
export PATH=/usr/local/bin:/usr/bin:$PATH

echo "=== sync frontend ==="
cp -r $SRC/frontend/. $FRONT/src/
echo FRONT_SYNC_OK

echo "=== build frontend ==="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo NPM_OK

echo "=== publish ==="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
echo PUBLISH_OK
ls -l --time-style=+%F_%T /www/wwwroot/yufams/js/app.*.js
echo "--- index 引用 ---"
grep -oE 'js/app\.[A-Za-z0-9]+\.js' /www/wwwroot/yufams/index.html
echo STAGE31_DONE
