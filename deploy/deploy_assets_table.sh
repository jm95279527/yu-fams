#!/bin/bash
set -e
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/stage_assets_table
cp $SRC/Assets.vue $FRONT/src/views/manager/Assets.vue
echo SYNC_OK
cd $FRONT
npm run build > /tmp/assets_table.log 2>&1 || { tail -n 100 /tmp/assets_table.log; exit 1; }
echo NPM_OK
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
echo STAGE_ASSETS_TABLE_DONE
