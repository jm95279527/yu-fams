#!/bin/bash
echo "=== 监听端口 ==="
ss -lntp 2>/dev/null | grep -E ':88|:89|:80\b' || netstat -lntp 2>/dev/null | grep -E ':88|:89'
echo "=== 含 88 的 nginx 配置 ==="
grep -rn "listen" /www/server/panel/vhost/nginx/*.conf 2>/dev/null | grep -E ':(88|80|443)'
echo "=== ams.conf 全文 ==="
cat /www/server/panel/vhost/nginx/ams.conf 2>/dev/null
echo "=== 前端产物里写死的 API 地址 ==="
grep -o "http://192\.168\.111\.231:89" /www/wwwroot/yufams/js/app.*.js 2>/dev/null | head -3
grep -o "http://192\.168\.111\.231:89" /www/wwwroot/yufams/js/*.js 2>/dev/null | sort -u | head -5
echo "=== 构建产物中的 VUE_APP_BASEURL 来源 ==="
cat /opt/yu-fams/Yu-FAMS-Vue-master/.env.production 2>/dev/null
echo DONE
