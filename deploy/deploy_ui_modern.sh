#!/bin/bash
set -e
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage_ui3
cp $SRC/assets/css/manager.css $FRONT/src/assets/css/manager.css
cp $SRC/assets/css/polish.css $FRONT/src/assets/css/polish.css
cp $SRC/main.js $FRONT/src/main.js
cp $SRC/views/manager/Home.vue $FRONT/src/views/manager/Home.vue
echo SYNC_OK
cd $FRONT
npm run build > /tmp/ui3_front.log 2>&1 || { tail -n 100 /tmp/ui3_front.log; exit 1; }
echo NPM_OK
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
echo STAGE_UI3_DONE
