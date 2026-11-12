#!/bin/bash
API=http://127.0.0.1:89
TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "=== myMenus 含数据备份 ==="
curl -s "$API/role/myMenus" -H "token: $TOKEN" | python3 -c '
import sys, json
d = json.load(sys.stdin)
def walk(items):
    for m in items or []:
        if m.get("path") == "/dataBackup":
            print("FOUND", m.get("name"), m.get("path"), m.get("api"))
        walk(m.get("children"))
walk(d.get("data"))
'
echo "=== 未授权访问 ==="
curl -s "$API/dataBackup/list" | head -c 120; echo
echo MENU_CHECK_DONE
