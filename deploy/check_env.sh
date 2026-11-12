#!/bin/bash
echo "=== frontend .env files ==="
ls -la /opt/yu-fams/Yu-FAMS-Vue-master/.env* 2>/dev/null
grep -rn "VUE_APP_BASEURL" /opt/yu-fams/Yu-FAMS-Vue-master/.env* 2>/dev/null
echo "=== nginx sites with port 88 ==="
grep -rln "listen.*88" /www/server/panel/vhost/nginx/ /etc/nginx/ 2>/dev/null | head
echo "=== proxy_pass in those ==="
grep -rn "proxy_pass\|root\s" /www/server/panel/vhost/nginx/*.conf 2>/dev/null | head -20
echo "=== deployed dist built time ==="
ls -la /www/wwwroot/yufams/ | head -5
echo "=== index.html baseurl hint ==="
grep -o "http://[0-9.:]*" /www/wwwroot/yufams/index.html 2>/dev/null | head
