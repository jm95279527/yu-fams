#!/bin/bash
set -e
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage_ac
cp $SRC/views/manager/Assets.vue $FRONT/src/views/manager/
echo SYNC_OK
cd $FRONT
npm run build > /tmp/ac_front.log 2>&1 || { tail -n 80 /tmp/ac_front.log; exit 1; }
echo NPM_OK
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
echo STAGE_AC_DONE
