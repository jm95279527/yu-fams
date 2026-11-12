#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOK_LEN=${#TOK}"

echo ""
echo "########## A. 按编号/按ID 查询 ##########"
NO=$($M -e "select no from assets where id=125")
echo "asset125 no=$NO"
curl -s "$B/qr/assetByNo/$NO" | python3 -c 'import sys,json;d=json.load(sys.stdin);print("  byNo code=",d["code"]," assetId=",d["data"]["assetId"]," no=",d["data"]["no"])'
curl -s "$B/qr/asset/125" | python3 -c 'import sys,json;d=json.load(sys.stdin);print("  byId code=",d["code"]," assetId=",d["data"]["assetId"]," no=",d["data"]["no"])'

echo ""
echo "########## B. 导出中的二维码链接 ##########"
curl -s "$B/assets/export?token=$TOK" -o /tmp/qr_export.xlsx
python3 - <<'PY'
import zipfile,re
z=zipfile.ZipFile('/tmp/qr_export.xlsx')
xml=''
for n in z.namelist():
    if 'sharedStrings' in n or 'worksheets/sheet' in n:
        xml+=z.read(n).decode('utf-8')
texts=re.findall(r'<t[^>]*>([^<]*)</t>',xml)
links=[t for t in texts if '/scan/' in t]
print("  scan_links=",links)
print("  uses_asset_no=", any('/scan/HM-DZ' in t for t in links))
print("  no_numeric_suffix=", not any(re.search(r'/scan/\d+$',t) for t in links))
PY
rm -f /tmp/qr_export.xlsx

echo ""
echo "########## C. 批量二维码内容比对 ##########"
curl -s "$B/assets/qrcode/batch?ids=125&token=$TOK" -o /tmp/qr125.zip
unzip -o -q /tmp/qr125.zip -d /tmp/qr125
ACTUAL=$(ls /tmp/qr125/*.png | head -1)
echo "  zip_png=$(basename "$ACTUAL")"
FRONT=$($M -e "select 'http://your-domain.com:88'")
EXPECT_URL="$FRONT/scan/$NO"
OLD_URL="$FRONT/scan/125"
curl -s --get --data-urlencode "text=$EXPECT_URL" --data-urlencode "size=300" "$B/qr/png" -o /tmp/expect_no.png
curl -s --get --data-urlencode "text=$OLD_URL" --data-urlencode "size=300" "$B/qr/png" -o /tmp/expect_id.png
echo "  expect_url=$EXPECT_URL"
echo "  md5_actual=$(md5sum "$ACTUAL" | cut -d' ' -f1)"
echo "  md5_expect_no=$(md5sum /tmp/expect_no.png | cut -d' ' -f1)"
echo "  md5_old_id=$(md5sum /tmp/expect_id.png | cut -d' ' -f1)"
cmp -s "$ACTUAL" /tmp/expect_no.png && echo "  MATCH_ASSET_NO=YES" || echo "  MATCH_ASSET_NO=NO"
cmp -s "$ACTUAL" /tmp/expect_id.png && echo "  MATCH_OLD_ID=YES" || echo "  MATCH_OLD_ID=NO"
rm -rf /tmp/qr125 /tmp/qr125.zip /tmp/expect_no.png /tmp/expect_id.png

echo ""
echo "########## D. 前端产物包含新逻辑 ##########"
WWW=/www/wwwroot/yufams
grep -rl "assetByNo" $WWW/js | head -3
grep -rl "scan/:code" $WWW/js | head -3
echo VERIFY_QR_NO_DONE
