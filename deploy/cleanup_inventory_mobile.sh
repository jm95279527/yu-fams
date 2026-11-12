#!/bin/bash
API=http://127.0.0.1:89
TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "delete task 18:"
curl -s -X DELETE $API/assetsInventory/delete/18 -H "token: $TOKEN"; echo
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e 'select count(*) from inventory_task; select count(*) from inventory_item;' 2>/dev/null
rm -f /tmp/inv_qr.png /tmp/stage_inv.tgz /tmp/verify_inventory_page.sh /tmp/verify_inventory_mobile.sh /tmp/verify_inventory_qr.sh
echo CLEANUP_DONE
