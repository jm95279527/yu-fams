#!/bin/bash
# staff 孤儿引用审计（只读，不修改数据）
export MYSQL_PWD=YOUR_DB_PASSWORD
M(){ mysql -uroot xm-assets -N -e "$1" 2>&1; }
echo "== staff rows =="
M "SELECT COUNT(*) FROM staff"
echo "== orphan counts (table.column | count) =="
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
echo "== orphan row details =="
echo "-- inventory --"
M "SELECT id, staff_id FROM inventory WHERE staff_id IS NOT NULL AND staff_id NOT IN (SELECT id FROM staff)"
echo "-- assets_in --"
M "SELECT id, staff_id FROM assets_in WHERE staff_id IS NOT NULL AND staff_id NOT IN (SELECT id FROM staff)"
echo DONE
