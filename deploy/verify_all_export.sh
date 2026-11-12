#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "token_len=${#TOK}"
check() {
  local name="$1"; local url="$2"
  local out=/tmp/expchk.bin
  local meta
  meta=$(curl -s -o "$out" -w '%{http_code}|%{content_type}|%{size_download}' "$url")
  local magic
  magic=$(head -c 2 "$out" | xxd -p)
  printf "%-26s %s MAGIC=%s\n" "$name" "$meta" "$magic"
  rm -f "$out"
}
echo "=== 导出/下载接口（带 token）==="
check "assets/export"         "$B/assets/export?token=$TOK"
check "assets/template"       "$B/assets/template?token=$TOK"
check "assets/qrcode/batch"   "$B/assets/qrcode/batch?ids=1&token=$TOK"
check "assetsIn/export"       "$B/assetsIn/export?token=$TOK"
check "assetsIn/template"     "$B/assetsIn/template?token=$TOK"
check "staff/export"          "$B/staff/export?token=$TOK"
check "assetsScrap/export"    "$B/assetsScrap/export?token=$TOK"
check "assetsTransfer/export" "$B/assetsTransfer/export?token=$TOK"
check "apiConfig/export"      "$B/apiConfig/export"
echo "=== 无 token（应 401）==="
check "assets/export(notoken)" "$B/assets/export"
echo "=== 已发布前端产物检查 ==="
ls -l /www/wwwroot/yufams/js/app.*.js 2>/dev/null | head -2
echo "--- app.js 中 blob 短路标记 ---"
grep -c "responseType" /www/wwwroot/yufams/js/*.js 2>/dev/null | grep -v ":0" || echo "no match"
echo "=== 盘点测试数据残留 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SELECT id,name,status FROM inventory_task;" 2>/dev/null
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SELECT CONCAT('item_count=',COUNT(*)) FROM inventory_item;" 2>/dev/null
echo DONE
