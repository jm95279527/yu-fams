#!/bin/bash
set -e -o pipefail
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/rr3
cp $SRC/AssetsRepair.vue $FRONT/src/views/manager/
cd $FRONT
npm run build > $SRC/build.log 2>&1
echo "frontend build exit=$?"
tail -3 $SRC/build.log
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
nginx -s reload
ls /www/wwwroot/yufams/js/app.*.js
echo DONE
