#!/bin/bash
set -e
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage_qr
cp -r $SRC/views/. $FRONT/src/views/
echo SYNC_OK
cd $FRONT
npm run build > $SRC/build-front2.log 2>&1 || { tail -n 80 $SRC/build-front2.log; exit 1; }
echo NPM_OK
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
echo PUBLISH_OK
echo STAGE_FRONT_DONE
