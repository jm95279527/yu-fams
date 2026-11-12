#!/bin/bash
set -e
API=http://127.0.0.1:89

TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')

curl -s $API/dashboard/overview -H "token: $TOKEN" > /tmp/overview.json

python3 -c '
import json
d = json.load(open("/tmp/overview.json"))
print("code:", d["code"])
x = d.get("data") or {}
print("kpi:", x.get("kpi"))
print("todo:", x.get("todo"))
print("statusDist:", x.get("statusDist"))
print("companyDist:", x.get("companyDist"))
print("deptTop:", (x.get("deptTop") or [])[:3])
print("categoryDist:", (x.get("categoryDist") or [])[:3])
print("monthly:", x.get("monthly"))
print("inventory:", x.get("inventory"))
print("recentAssets:", (x.get("recentAssets") or [])[:2])
'
echo OVERVIEW_DONE
