#!/bin/bash
B=http://127.0.0.1:89
for U in "/assets/template" "/assetsIn/template" "/assets/qrcode/batch?ids=1" "/assetsDetail/export" "/inventory/export" "/apiConfig/export"; do
  printf "%-40s " "$U"
  curl -s -o /tmp/z.out -w 'HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}\n' "$B$U"
done
echo "--- 前端的导出/下载相关 UI 引用 ---"
grep -rn "export\|template\|qrcode" /www/wwwroot/yufams/index.html 2>/dev/null | head -3
