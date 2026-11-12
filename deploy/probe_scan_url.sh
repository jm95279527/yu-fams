#!/bin/bash
for P in 88 89; do
  echo "--- port $P /scan/107 ---"
  curl -s -o /tmp/s$P.out -w "http=%{http_code} type=%{content_type} size=%{size_download}\n" "http://127.0.0.1:$P/scan/107"
  head -c 120 /tmp/s$P.out; echo
done
echo "--- nginx 监听配置 ---"
grep -rn "listen\|server_name\|location" /www/server/panel/vhost/nginx/*.conf 2>/dev/null | head -30
echo "--- 前端 baseUrl ---"
grep -rn "VUE_APP_BASEURL" /opt/yu-fams/Yu-FAMS-Vue-master/.env* 2>/dev/null
echo DONE
