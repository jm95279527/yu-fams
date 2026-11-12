#!/bin/bash
# 补充修复：inventory.staff_id / assets_transfer.transfer_staff_id 为 NOT NULL，先改可空再置 NULL
export MYSQL_PWD=YOUR_DB_PASSWORD
M(){ mysql -uroot xm-assets -N -e "$1" 2>&1; }
echo "== column defs before =="
M "SHOW COLUMNS FROM inventory LIKE 'staff_id'"
M "SHOW COLUMNS FROM assets_transfer LIKE 'transfer_staff_id'"
echo "== alter to nullable =="
M "ALTER TABLE inventory MODIFY staff_id INT NULL COMMENT '盘点经办人，孤儿修复后可空'"
M "ALTER TABLE assets_transfer MODIFY transfer_staff_id INT NULL COMMENT '调拨经办人，孤儿修复后可空'"
echo "alter ok"
echo "== null the orphans =="
M "UPDATE inventory SET staff_id=NULL WHERE staff_id IS NOT NULL AND staff_id NOT IN (SELECT id FROM staff)"
M "UPDATE assets_transfer SET transfer_staff_id=NULL WHERE transfer_staff_id IS NOT NULL AND transfer_staff_id NOT IN (SELECT id FROM staff)"
echo "update ok"
echo "== re-audit =="
M "SELECT 'inventory.staff_id', COUNT(*) FROM inventory WHERE staff_id IS NOT NULL AND staff_id NOT IN (SELECT id FROM staff)
UNION ALL SELECT 'assets_transfer.transfer_staff_id', COUNT(*) FROM assets_transfer WHERE transfer_staff_id IS NOT NULL AND transfer_staff_id NOT IN (SELECT id FROM staff)"
echo "== rows after fix =="
M "SELECT 'inventory', id, staff_id, staff_name FROM inventory"
M "SELECT 'assets_transfer', id, transfer_staff_id, transfer_staff_name FROM assets_transfer"
echo DONE
