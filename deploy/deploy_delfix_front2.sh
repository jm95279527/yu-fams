#!/bin/bash
set -e
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/delfix
export PATH=/usr/lib/jvm/java-1.8.0-openjdk/bin:$PATH

cp $SRC/frontend/views/manager/AssetsRepair.vue $FRONT/src/views/manager/
grep -n 'width="265"' $FRONT/src/views/manager/AssetsRepair.vue

cd $FRONT
npm run build > $SRC/build-front2.log 2>&1
echo NPM_OK
ls -la dist/index.html

rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
echo PUBLISH_OK
curl -s -o /dev/null -w "front88=%{http_code}\n" http://127.0.0.1:88/
echo FRONT_ONLY_DONE
