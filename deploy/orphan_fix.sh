#!/bin/bash
# 孤儿 staff 引用修复：先备份后置 NULL（数据行保留，仅清除悬挂引用）
export MYSQL_PWD=YOUR_DB_PASSWORD
M(){ mysql -uroot xm-assets -N -e "$1" 2>&1; }
FIX(){
  t=$1; c=$2
  n=$(M "SELECT COUNT(*) FROM $t WHERE $c IS NOT NULL AND $c NOT IN (SELECT id FROM staff)")
  if [ -n "$n" ] && [ "$n" -gt 0 ]; then
    bk="backup_${t}_${c}_orphan"
    r1=$(M "CREATE TABLE $bk AS SELECT * FROM $t WHERE $c IS NOT NULL AND $c NOT IN (SELECT id FROM staff)")
    r2=$(M "UPDATE $t SET $c=NULL WHERE $c IS NOT NULL AND $c NOT IN (SELECT id FROM staff)")
    echo "FIXED $t.$c rows=$n backup=$bk ${r1}${r2}"
  else
    echo "SKIP  $t.$c orphans=${n:-QUERY_ERR}"
  fi
}
FIX assets staff_id
FIX assets_in staff_id
FIX assets_receive staff_id
FIX assets_repair staff_id
FIX assets_scrap staff_id
FIX assets_scrap applicant_id
FIX assets_transfer from_staff_id
FIX assets_transfer to_staff_id
FIX assets_transfer transfer_staff_id
FIX inventory staff_id
FIX inventory_item staff_id
echo "== post-fix audit (expect all 0) =="
M "SELECT 'assets.staff_id', COUNT(*) FROM assets WHERE staff_id IS NOT NULL AND staff_id NOT IN (SELECT id FROM staff)
UNION ALL SELECT 'assets_in.staff_id', COUNT(*) FROM assets_in WHERE staff_id IS NOT NULL AND staff_id NOT IN (SELECT id FROM staff)
UNION ALL SELECT 'assets_receive.staff_id', COUNT(*) FROM assets_receive WHERE staff_id IS NOT NULL AND staff_id NOT IN (SELECT id FROM staff)
UNION ALL SELECT 'assets_repair.staff_id', COUNT(*) FROM assets_repair WHERE staff_id IS NOT NULL AND staff_id NOT IN (SELECT id FROM staff)
UNION ALL SELECT 'assets_scrap.staff_id', COUNT(*) FROM assets_scrap WHERE staff_id IS NOT NULL AND staff_id NOT IN (SELECT id FROM staff)
UNION ALL SELECT 'assets_scrap.applicant_id', COUNT(*) FROM assets_scrap WHERE applicant_id IS NOT NULL AND applicant_id NOT IN (SELECT id FROM staff)
UNION ALL SELECT 'assets_transfer.from_staff_id', COUNT(*) FROM assets_transfer WHERE from_staff_id IS NOT NULL AND from_staff_id NOT IN (SELECT id FROM staff)
UNION ALL SELECT 'assets_transfer.to_staff_id', COUNT(*) FROM assets_transfer WHERE to_staff_id IS NOT NULL AND to_staff_id NOT IN (SELECT id FROM staff)
UNION ALL SELECT 'assets_transfer.transfer_staff_id', COUNT(*) FROM assets_transfer WHERE transfer_staff_id IS NOT NULL AND transfer_staff_id NOT IN (SELECT id FROM staff)
UNION ALL SELECT 'inventory.staff_id', COUNT(*) FROM inventory WHERE staff_id IS NOT NULL AND staff_id NOT IN (SELECT id FROM staff)
UNION ALL SELECT 'inventory_item.staff_id', COUNT(*) FROM inventory_item WHERE staff_id IS NOT NULL AND staff_id NOT IN (SELECT id FROM staff)"
echo "== backup tables =="
M "SHOW TABLES LIKE 'backup_%'"
echo "== backend sanity =="
TOKEN=$(curl -s -X POST http://localhost:89/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "assets/selectAll: $(curl -s "http://localhost:89/assets/selectAll?pageSize=10" -H "token: $TOKEN" | head -c 40)"
echo "dashboard/status: $(curl -s "http://localhost:89/dashboard/status-distribution?period=month" -H "token: $TOKEN" | head -c 40)"
echo DONE
