#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
curl -s -o /tmp/qr.xlsx "$B/assets/export?token=$TOK"
python3 - <<'PY' > /tmp/qrurls.txt
import zipfile, xml.etree.ElementTree as ET
NS='{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
z=zipfile.ZipFile('/tmp/qr.xlsx')
ss=[]
if 'xl/sharedStrings.xml' in z.namelist():
    r=ET.fromstring(z.read('xl/sharedStrings.xml'))
    for si in r.findall(NS+'si'):
        ss.append(''.join(t.text or '' for t in si.iter(NS+'t')))
sh=ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
rows=sh.find(NS+'sheetData').findall(NS+'row')
def cells(rw):
    out=[]
    for c in rw.findall(NS+'c'):
        v=c.find(NS+'v'); txt='' if v is None else v.text
        if c.get('t')=='s' and txt not in (None,''): txt=ss[int(txt)]
        out.append('' if txt is None else txt)
    return out
print('rows=%d' % len(rows))
h=cells(rows[0])
print('表头(%d): %s' % (len(h), ','.join(h)))
for rw in rows[1:4]:
    c=cells(rw)
    print('  序号=%s 资产编号=%s 二维码链接=%s' % (c[0], c[1], c[-1]))
print('SAMPLEURL=' + cells(rows[1])[-1])
PY
cat /tmp/qrurls.txt
U=$(grep '^SAMPLEURL=' /tmp/qrurls.txt | cut -d= -f2-)
echo "--- 校验链接可达性: $U ---"
curl -s -o /dev/null -w "http=%{http_code} type=%{content_type}\n" "$U"
echo DONE
