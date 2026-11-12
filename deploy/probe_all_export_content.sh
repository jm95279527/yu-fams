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
try:
    z=zipfile.ZipFile('/tmp/p.xlsx')
    ss=0
    if 'xl/sharedStrings.xml' in z.namelist():
        r=ET.fromstring(z.read('xl/sharedStrings.xml'))
        ss=r.get('count','?')
    sh=ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
    rows=sh.find(NS+'sheetData').findall(NS+'row')
    cells=sum(len(rw.findall(NS+'c')) for rw in rows)
    first=''
    if rows:
        v=rows[0].find(NS+'c')
        first='(有值)' if v is not None else '(空)'
    print('%-24s rows=%-4s cells=%-5s sharedCount=%-4s 首行%s' % (name, len(rows), cells, ss, first))
except Exception as e:
    print('%-24s ERR %s' % (name, e))
PY
}
probe "assets/export"         "$B/assets/export?token=$TOK"
probe "assets/template"       "$B/assets/template?token=$TOK"
probe "assetsIn/export"       "$B/assetsIn/export?token=$TOK"
probe "assetsIn/template"     "$B/assetsIn/template?token=$TOK"
probe "staff/export"          "$B/staff/export?token=$TOK"
probe "assetsScrap/export"    "$B/assetsScrap/export?token=$TOK"
probe "assetsTransfer/export" "$B/assetsTransfer/export?token=$TOK"
probe "apiConfig/export"      "$B/apiConfig/export"
echo DONE
