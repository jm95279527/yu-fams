#!/bin/bash
set -e
VUE=/opt/yu-fams/Yu-FAMS-Vue-master
cp /tmp/index.js $VUE/src/router/index.js
cp /tmp/Manager.vue $VUE/src/views/Manager.vue
cd $VUE
export VUE_APP_BASEURL=http://YOUR_SERVER_IP:89
npm run build 2>&1 | tail -5
rm -rf /www/wwwroot/yufams/js /www/wwwroot/yufams/css
cp -r dist/* /www/wwwroot/yufams/
echo DEPLOY_DONE
ls -l /www/wwwroot/yufams/index.html
grep -c "getMyMenuTree\|beforeEach" /www/wwwroot/yufams/js/app.*.js || true
