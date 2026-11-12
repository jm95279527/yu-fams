#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
probe() {
  local name="$1"; local url="$2"
  curl -s -o /tmp/p.xlsx "$url"
  python3 - "$name" <<'PY'
import sys, zipfile, xml.etree.ElementTree as ET
name=sys.argv[1]
NS='{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
z=zipfile.ZipFile('/tmp/p.xlsx')
ss=[]
if 'xl/sharedStrings.xml' in z.namelist():
    r=ET.fromstring(z.read('xl/sharedStrings.xml'))
    for si in r.findall(NS+'si'):
        ss.append(''.join(t.text or '' for t in si.iter(NS+'t')))
sh=ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
rows=sh.find(NS+'sheetData').findall(NS+'row')
print('==== %s (rows=%d) ====' % (name, len(rows)))
for rw in rows[:4]:
    vals=[]
    for c in rw.findall(NS+'c'):
        v=c.find(NS+'v'); isv=c.find(NS+'is')
        if c.get('t')=='inlineStr' and isv is not None:
            txt=''.join(t.text or '' for t in isv.iter(NS+'t'))
        else:
            txt='' if v is None else v.text
            if c.get('t')=='s' and txt not in (None,''): txt=ss[int(txt)]
        vals.append(txt)
    print(' r%s(%d): %s' % (rw.get('r'), len(vals), vals[:22]))
PY
}
probe "assets/export"      "$B/assets/export?token=$TOK"
probe "assetsIn/export"    "$B/assetsIn/export?token=$TOK"
probe "assetsIn/template"  "$B/assetsIn/template?token=$TOK"
echo DONE
