#!/bin/bash
B88=http://127.0.0.1:88
B89=http://127.0.0.1:89
HX='Host: 222.77.25.136:88'
echo "=== 1) 前端产物是否仍写死内网 API 地址 ==="
n=$(grep -c "192\.168\.111\.231:89" /www/wwwroot/yufams/js/app.*.js 2>/dev/null || true)
echo "  写死地址出现次数 = ${n:-0}"
echo -n "  是否含 /api 基址: "; grep -o '"/api"' /www/wwwroot/yufams/js/app.*.js 2>/dev/null | head -1 || echo "未匹配(可能被压缩拼接)"
echo "=== 2) 经 88 的 /api 登录 ==="
curl -s -o /tmp/l.json -w "  HTTP=%{http_code} TYPE=%{content_type}\n" -X POST "$B88/api/login" -H 'Content-Type: application/json' -H "$HX" -d '{"username":"admin","password":"admin123","role":"ADMIN"}'
head -c 180 /tmp/l.json; echo
TOK=$(python3 -c "import json;print(json.load(open('/tmp/l.json'))['data']['token'])" 2>/dev/null)
echo "  token_len=${#TOK}"
echo "=== 3) 经 88 调业务接口 ==="
curl -s -o /tmp/pg.json -w "  HTTP=%{http_code}\n" "$B88/api/assets/selectPage?pageNum=1&pageSize=5" -H "token: $TOK" -H "$HX"
python3 -c "import json;d=json.load(open('/tmp/pg.json'));print('  code',d['code'],'total',d['data']['total'])"
echo "=== 4) 直连 89（老路径）仍可用 ==="
curl -s -o /dev/null -w "  89 /assets/selectPage HTTP=%{http_code}\n" "$B89/assets/selectPage?pageNum=1&pageSize=5" -H "token: $TOK"
echo "=== 5) /scan/:id 仍是 SPA 页 ==="
curl -s -o /dev/null -w "  88 /scan/117 HTTP=%{http_code} TYPE=%{content_type}\n" "$B88/scan/117"
echo "=== 6) 上传返回相对路径 + 经 88 取回 ==="
echo hello-e2e > /tmp/up.txt
curl -s -o /tmp/up.json -X POST "$B88/api/files/upload" -F "file=@/tmp/up.txt" -H "$HX"
cat /tmp/up.json; echo
REL=$(python3 -c "import json;print(json.load(open('/tmp/up.json'))['data'])" 2>/dev/null)
echo "  relative=$REL"
curl -s -o /tmp/back.txt -w "  经88取回 HTTP=%{http_code} SIZE=%{size_download}\n" "$B88$REL" -H "$HX"
echo "  内容: $(cat /tmp/back.txt 2>/dev/null)"
echo "=== 7) 导出里的二维码链接 ==="
curl -s -o /tmp/e.xlsx "$B88/api/assets/export?token=$TOK" -H "$HX"
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
print('  二维码链接样例', cells(rows[1])[-1])
PY
echo DONE
