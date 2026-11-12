#!/bin/bash
set -e
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage_ui
cp $SRC/assets/css/manager.css $FRONT/src/assets/css/manager.css
cp $SRC/assets/css/polish.css $FRONT/src/assets/css/polish.css
cp $SRC/main.js $FRONT/src/main.js
echo SYNC_OK
cd $FRONT
npm run build > /tmp/ui_front.log 2>&1 || { tail -n 100 /tmp/ui_front.log; exit 1; }
echo NPM_OK
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
echo STAGE_UI_DONE
