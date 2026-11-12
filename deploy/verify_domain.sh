#!/bin/bash
B=http://127.0.0.1:88
HX='Host: your-domain.com:88'
echo "=== 域名解析 ==="
getent hosts your-domain.com
echo "=== 1) 经域名登录 ==="
curl -s -o /tmp/l.json -w "  /api/login HTTP=%{http_code}\n" -X POST "$B/api/login" -H 'Content-Type: application/json' -H "$HX" -d '{"username":"admin","password":"admin123","role":"ADMIN"}'
TOK=$(python3 -c "import json;print(json.load(open('/tmp/l.json'))['data']['token'])" 2>/dev/null)
echo "  token_len=${#TOK}"
echo "=== 2) 经域名取业务数据 ==="
curl -s -o /tmp/pg.json -w "  /api/assets/selectPage HTTP=%{http_code}\n" "$B/api/assets/selectPage?pageNum=1&pageSize=5" -H "token: $TOK" -H "$HX"
python3 -c "import json;d=json.load(open('/tmp/pg.json'));print('  code',d['code'],'total',d['data']['total'])"
echo "=== 3) 二维码链接（导出末列）==="
curl -s -o /tmp/e.xlsx "$B/api/assets/export?token=$TOK" -H "$HX"
python3 - <<'PY'
import zipfile, xml.etree.ElementTree as ET
NS='{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
z=zipfile.ZipFile('/tmp/e.xlsx')
ss=[]
if 'xl/sharedStrings.xml' in z.namelist():
    r=ET.fromstring(z.read('xl/sharedStrings.xml'))
    for si in r.findall(NS+'si'): ss.append(''.join(t.text or '' for t in si.iter(NS+'t')))
sh=ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
rows=sh.find(NS+'sheetData').findall(NS+'row')
def cells(rw):
    out=[]
    for c in rw.findall(NS+'c'):
        v=c.find(NS+'v'); t='' if v is None else v.text
        if c.get('t')=='s' and t not in (None,''): t=ss[int(t)]
        out.append('' if t is None else t)
    return out
print('  表头列数', len(cells(rows[0])), '| 末列', cells(rows[0])[-1])
print('  样例', cells(rows[1])[-1])
PY
echo "=== 4) 批量二维码内容（字节比对法）==="
AID=$(mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SELECT id FROM assets ORDER BY id DESC LIMIT 1;" 2>/dev/null)
curl -s -o /tmp/q.zip "$B/api/assets/qrcode/batch?ids=$AID&token=$TOK" -H "$HX"
rm -rf /tmp/qz && mkdir -p /tmp/qz && unzip -o -q /tmp/q.zip -d /tmp/qz
PNG=$(ls /tmp/qz/*.png | head -1)
EXPECT="http://your-domain.com:88/scan/$AID"
curl -s -o /tmp/expect.png --get --data-urlencode "text=$EXPECT" --data-urlencode "size=300" "$B/api/qr/png" -H "$HX"
echo "  zip内 : $(md5sum "$PNG" | cut -d' ' -f1)"
echo "  期望值: $(md5sum /tmp/expect.png | cut -d' ' -f1)  <- $EXPECT"
cmp -s "$PNG" /tmp/expect.png && echo "  ✔ 二维码内容 == $EXPECT" || echo "  ✘ 不一致"
echo "=== 5) /scan/:id 仍返回 SPA ==="
curl -s -o /dev/null -w "  HTTP=%{http_code} TYPE=%{content_type}\n" "$B/scan/$AID" -H "$HX"
echo DONE
