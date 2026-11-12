#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOK_LEN=${#TOK}"
curl -s -o /tmp/no_seq.xlsx -w 'http=%{http_code} type=%{content_type} size=%{size_download}\n' "$B/assets/export?token=$TOK"
file /tmp/no_seq.xlsx
unzip -l /tmp/no_seq.xlsx | head -12
echo "--- sheet 前 600 字符 ---"
unzip -p /tmp/no_seq.xlsx xl/worksheets/sheet1.xml | head -c 600; echo
python3 - <<'PY'
import zipfile,re
z=zipfile.ZipFile('/tmp/no_seq.xlsx')
xml=''
for n in z.namelist():
    if 'sharedStrings' in n or 'worksheets/sheet' in n:
        xml+=z.read(n).decode('utf-8')
texts=re.findall(r'<t[^>]*>([^<]*)</t>',xml)
print('texts_count=',len(texts))
print('has_seq=', '序号' in texts)
print('first=',texts[:10])
PY
rm -f /tmp/no_seq.xlsx
