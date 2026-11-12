#!/bin/bash
set -e
API=http://127.0.0.1:89
WEB=http://127.0.0.1:88
ACCESS=9fa6c836351d4cee963ca371e97202ac
URL="http://your-domain.com:88/inventory/$ACCESS"

echo "--- 1. 通过 88 门户生成盘点二维码 ---"
curl -s -o /tmp/inv_qr.png -w 'http=%{http_code} type=%{content_type} size=%{size_download}\n' \
  "$WEB/api/qr/png?size=320&text=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=''))" "$URL")"
file /tmp/inv_qr.png

echo "--- 2. 后端识别二维码图片，回读内容 ---"
curl -s -X POST $API/qr/decode -F "file=@/tmp/inv_qr.png" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d["code"],d["data"]);assert d["data"]==sys.argv[1]' "$URL" && echo QR_ROUNDTRIP_OK

echo "--- 3. 通过 88 门户调用公开盘点接口 ---"
curl -s "$WEB/api/inventoryPublic/task/$ACCESS"; echo

echo "--- 4. 后台页面已包含二维码入口 ---"
grep -rl '盘点单二维码' /www/wwwroot/yufams/js | head -n 2
echo PAGE_CHECK_DONE
