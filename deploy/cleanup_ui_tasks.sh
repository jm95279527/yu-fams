#!/bin/bash
BASE=http://localhost:89
TOKEN=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
export MYSQL_PWD=YOUR_DB_PASSWORD
for id in $(mysql -uroot xm-assets -N -e "SELECT id FROM inventory_task WHERE name LIKE '%UI盘点%' OR (name='2026年9月资产盘点' AND create_time LIKE '2026-09-14%')" 2>/dev/null); do
  echo "delete task $id:"
  curl -s -X DELETE $BASE/assetsInventory/delete/$id -H "token: $TOKEN"
  echo ""
done
mysql -uroot xm-assets -N -e "SELECT id,name,status FROM inventory_task" 2>/dev/null
echo DONE
