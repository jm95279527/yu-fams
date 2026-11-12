#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "=== DB 计数 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SELECT CONCAT('assets_rows=',COUNT(*)) FROM assets;" 2>/dev/null
echo "=== selectAll 接口返回行数 ==="
curl -s "$B/assets/selectAll?token=$TOK" | python3 -c "import sys,json;d=json.load(sys.stdin);print('code=',d.get('code'),'rows=',len(d.get('data') or []))"
echo "=== 下载 /assets/export ==="
curl -s -o /tmp/a.xlsx "$B/assets/export?token=$TOK"
ls -l /tmp/a.xlsx
python3 - <<'PY'
import zipfile, re, xml.etree.ElementTree as ET
NS='{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
z=zipfile.ZipFile('/tmp/a.xlsx')
print('entries:', z.namelist())
try:
    ss=[]
    if 'xl/sharedStrings.xml' in z.namelist():
        r=ET.fromstring(z.read('xl/sharedStrings.xml'))
        for si in r.findall(NS+'si'):
            ss.append(''.join(t.text or '' for t in si.iter(NS+'t')))
    sh=ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
    rows=sh.find(NS+'sheetData').findall(NS+'row')
    print('sheet rows:', len(rows))
    for row in rows[:6]:
        vals=[]
        for c in row.findall(NS+'c'):
            v=c.find(NS+'v')
            txt='' if v is None else v.text
            if c.get('t')=='s' and txt is not None:
                txt=ss[int(txt)]
            vals.append(txt)
        print(' |', vals)
except Exception as e:
    print('PARSE_ERR', e)
PY
echo DONE
