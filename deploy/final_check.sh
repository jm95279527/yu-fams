#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "=== 带 token 的下载/导出接口 ==="
for U in "/assets/template" "/assetsIn/template"; do
  printf "%-22s " "$U"
  curl -s -o /tmp/t.out -w 'HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}\n' "$B$U?token=$TOK"
done
printf "%-22s " "/assets/qrcode/batch"
curl -s -o /tmp/q.out -w 'HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}\n' "$B/assets/qrcode/batch?ids=1&token=$TOK"
echo "=== 盘点测试数据残留检查 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SELECT CONCAT('inventory_task=',COUNT(*)) FROM inventory_task; SELECT CONCAT('inventory_item=',COUNT(*)) FROM inventory_item; SELECT CONCAT('staff=',COUNT(*)) FROM staff;" 2>/dev/null
