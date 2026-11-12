#!/bin/bash
echo "=== 构建与进程 ==="
tail -4 /tmp/exportcol/build.log
ls -l /opt/yu-fams/Yu-FAMS-SpringBoot-master/target/springboot-0.0.1-SNAPSHOT.jar
ps -ef | grep springboot | grep -v grep | head -2
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "token_len=${#TOK}"
probe() {
  local name="$1"; local url="$2"
  curl -s -o /tmp/p.xlsx "$url"
  python3 - "$name" <<'PY'
import sys, zipfile, xml.etree.ElementTree as ET
name=sys.argv[1]
NS='{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
try:
    z=zipfile.ZipFile('/tmp/p.xlsx')
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
            out.append(txt)
        return out
    hdr=sorted(set(cells(rows[0]))) if rows else []
    print('%-22s rows=%-3d 表头列数=%d' % (name, len(rows), len(hdr)))
    if rows:
        print('   表头: %s' % ','.join(cells(rows[0])))
        if len(rows)>1:
            print('   首行: %s' % ','.join('' if x is None else x for x in cells(rows[1])))
except Exception as e:
    print('%-22s ERR %s' % (name, e))
PY
}
echo "=== 导出内容检查 ==="
probe "assets/export"       "$B/assets/export?token=$TOK"
probe "assetsIn/export"     "$B/assetsIn/export?token=$TOK"
probe "assetsIn/template"   "$B/assetsIn/template?token=$TOK"
probe "assets/template"     "$B/assets/template?token=$TOK"
probe "assetsScrap/export"  "$B/assetsScrap/export?token=$TOK"
probe "staff/export"        "$B/staff/export?token=$TOK"
probe "assetsTransfer/export" "$B/assetsTransfer/export?token=$TOK"
probe "apiConfig/export"    "$B/apiConfig/export"
echo DONE
