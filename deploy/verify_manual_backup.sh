#!/bin/bash
set -e
API=http://127.0.0.1:89

TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')

echo "=== 备份前列表 ==="
curl -s $API/dataBackup/list -H "token: $TOKEN" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d["code"], len(d.get("data") or []), [x["name"] for x in (d.get("data") or [])])'

echo "=== 手动备份 ==="
curl -s -X POST $API/dataBackup/create -H "token: $TOKEN" | python3 -m json.tool

echo "=== 备份后列表 ==="
curl -s $API/dataBackup/list -H "token: $TOKEN" | python3 -c 'import sys,json;d=json.load(sys.stdin);[print(x["name"], x["typeText"], x["sizeText"], x["time"]) for x in (d.get("data") or [])]'

echo "=== 服务器目录 ==="
ls -lh /opt/yu-fams/Yu-FAMS-SpringBoot-master/backup/ | tail -n 10
echo TEST_DONE
