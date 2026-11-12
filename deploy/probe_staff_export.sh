#!/bin/bash
BASE=http://localhost:89
TOKEN=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "== staff export =="
curl -s "$BASE/staff/export" -H "token: $TOKEN" -o /tmp/rf_staff.xlsx
mkdir -p /tmp/rf_staffx && rm -rf /tmp/rf_staffx/* && cd /tmp/rf_staffx && unzip -o -q /tmp/rf_staff.xlsx
python3 - <<'PY'
import re
xml = open('xl/sharedStrings.xml', encoding='utf-8').read()
texts = re.findall(r'<t[^>]*>(.*?)</t>', xml, re.S)
print(texts[:25])
PY
echo "== hutool jars =="
find /root/.m2 -name "hutool-poi*.jar" 2>/dev/null
find /root/.m2 -name "hutool-core*.jar" 2>/dev/null | head -3
echo DONE
