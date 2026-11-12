#!/bin/bash
echo "=== 哪个 vhost 监听 88 ==="
grep -rln "listen 88" /www/server/panel/vhost/nginx/ /www/server/nginx/conf/ 2>/dev/null
echo "--- 内容 ---"
for f in $(grep -rln "listen 88" /www/server/panel/vhost/nginx/ /www/server/nginx/conf/ 2>/dev/null); do
  echo "### $f"
  cat "$f"
done
echo "=== 是否已存在 /api 反代 ==="
grep -rn "proxy_pass" /www/server/panel/vhost/nginx/ 2>/dev/null | head
echo DONE
