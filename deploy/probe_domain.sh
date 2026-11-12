#!/bin/bash
echo "=== nginx 配置里是否已出现 hemar ==="
grep -rn "hemar" /www/server/panel/vhost/nginx/ /www/server/nginx/conf/ 2>/dev/null | head -20
echo "=== 已有证书目录 ==="
ls -1 /www/server/panel/vhost/cert/ 2>/dev/null
echo "--- 含 hemar 的证书 ---"
find /www/server/panel/vhost/cert -maxdepth 2 -iname "*hemar*" 2>/dev/null | head -20
echo "=== 所有 vhost 的 listen / server_name ==="
grep -rn "listen\|server_name" /www/server/panel/vhost/nginx/*.conf 2>/dev/null
echo "=== 443 是否在监听 ==="
ss -lntp 2>/dev/null | grep -E ':443|:80 ' || echo "no 443/80"
echo "=== 域名解析（本机视角）==="
getent hosts your-domain.com || echo "本机无法解析 your-domain.com"
echo DONE
