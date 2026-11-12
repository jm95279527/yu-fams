#!/bin/bash
export MYSQL_PWD=YOUR_DB_PASSWORD
echo "== inventory_task DDL =="
mysql -uroot xm-assets -N -e "SHOW CREATE TABLE inventory_task\G" 2>/dev/null
echo "== inventory_item DDL =="
mysql -uroot xm-assets -N -e "SHOW CREATE TABLE inventory_item\G" 2>/dev/null
echo "== row counts =="
mysql -uroot xm-assets -N -e "SELECT 'task',COUNT(*) FROM inventory_task UNION ALL SELECT 'item',COUNT(*) FROM inventory_item" 2>/dev/null
echo "== server source has new controller? =="
ls -la /opt/yu-fams/Yu-FAMS-SpringBoot-master/src/main/java/com/example/controller/AssetsInventoryController.java 2>&1
ls /opt/yu-fams/Yu-FAMS-SpringBoot-master/src/main/java/com/example/entity/InventoryTask.java 2>&1
echo "== API live test =="
TOKEN=$(curl -s -X POST http://localhost:89/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])" 2>/dev/null)
curl -s "http://localhost:89/assetsInventory/selectPage?pageNum=1&pageSize=2" -H "token: $TOKEN" | head -c 400
echo ""
echo DONE
