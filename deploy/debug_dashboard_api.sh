#!/bin/bash
API=http://127.0.0.1:89
LOGIN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}')
echo "LOGIN=${LOGIN:0:120}"
TOKEN=$(echo "$LOGIN" | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])' 2>/dev/null)
echo "TOKEN_LEN=${#TOKEN}"
echo "--- overview raw ---"
curl -s -w "\nHTTP=%{http_code}\n" $API/dashboard/overview -H "token: $TOKEN" | head -c 800
echo
echo "--- backend log ---"
journalctl -u yufams -n 30 --no-pager | tail -n 30
