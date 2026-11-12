#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOK_LEN=${#TOK}"
echo "-- selectPage --"
curl -s "$B/assets/selectPage?pageNum=1&pageSize=10" -H "token: $TOK" | head -c 400; echo
echo "-- selectAll --"
curl -s "$B/assets/selectAll" -H "token: $TOK" | head -c 300; echo
echo "-- assetField/public --"
curl -s "$B/assetField/public" | head -c 300; echo
echo "-- export http/size --"
curl -s -o /tmp/no_seq2.xlsx -w 'http=%{http_code} size=%{size_download}\n' "$B/assets/export?token=$TOK"
unzip -p /tmp/no_seq2.xlsx xl/worksheets/sheet1.xml | head -c 300; echo
echo "-- journal --"
journalctl -u yufams -n 30 --no-pager | tail -12
rm -f /tmp/no_seq2.xlsx
