#!/bin/bash
echo "=== nginx 上的 app.js ==="
ls -l /www/wwwroot/yufams/js/app.*.js
echo "=== index.html 引用的 app.js ==="
grep -o 'app\.[a-z0-9]*\.js' /www/wwwroot/yufams/index.html
echo "=== 构建目录 app.js ==="
ls -l /opt/yu-fams/Yu-FAMS-Vue-master/dist/js/app.*.js
echo "=== 服务器源码中是否已含新路由 ==="
grep -c "robotConfig" /opt/yu-fams/Yu-FAMS-Vue-master/src/router/index.js
echo "=== 产物中是否含 robotConfig ==="
grep -l "robotConfig" /www/wwwroot/yufams/js/*.js 2>/dev/null
echo DONE
