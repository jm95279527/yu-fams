#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "TOKEN len=${#TOK}"
for P in "/staff/export" "/assets/export" "/inventory/export" "/assetsScrap/export" "/assetsTransfer/export"; do
  echo "=== $P ==="
  curl -s -D /tmp/h.txt "$B$P" -H "token:$TOK" -o /tmp/e.out
  echo "--- headers ---"
  head -12 /tmp/h.txt
  echo "--- size: $(stat -c%s /tmp/e.out) bytes, first bytes: ---"
  head -c 200 /tmp/e.out | cat -v
  echo
done
