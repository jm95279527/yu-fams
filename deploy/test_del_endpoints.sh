#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOKLEN=${#TOK}"
echo "--- DELETE /assetsReceive/delete/999901 (bogus id, 非破坏性) ---"
curl -s -X DELETE $B/assetsReceive/delete/999901 -H "token: $TOK"; echo
echo "--- DELETE /assetsRepair/delete/999901 (bogus id, 非破坏性) ---"
curl -s -X DELETE $B/assetsRepair/delete/999901 -H "token: $TOK"; echo
echo "--- 借用列表（含状态）---"
curl -s "$B/assetsReceive/selectPage?pageNum=1&pageSize=20" -H "token: $TOK" \
  | python3 -c 'import sys,json
d=json.load(sys.stdin)["data"]["list"]
for x in d: print("  id=%s status=%s returnStatus=%s borrower=%s"%(x["id"],x["status"],x["returnStatus"],x.get("borrowerName")))'
echo "--- 维修列表（含状态）---"
curl -s "$B/assetsRepair/selectPage?pageNum=1&pageSize=20" -H "token: $TOK" \
  | python3 -c 'import sys,json
d=json.load(sys.stdin)["data"]["list"]
for x in d: print("  id=%s status=%s assets=%s"%(x["id"],x["status"],x.get("assetsName")))'
echo TEST_DELETE_DONE
