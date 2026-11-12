#!/bin/bash
set -e
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
cp /tmp/polish.css $FRONT/src/assets/css/polish.css
echo SYNC_OK
cd $FRONT
npm run build > /tmp/assets_font.log 2>&1 || { tail -n 100 /tmp/assets_font.log; exit 1; }
echo NPM_OK
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
echo STAGE_ASSETS_FONT_DONE
