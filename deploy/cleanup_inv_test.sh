#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "=== 删除前 ==="
$M -e "SELECT id,name,status FROM inventory_task;" 2>/dev/null
$M -e "SELECT CONCAT('item=',COUNT(*)) FROM inventory_item;" 2>/dev/null
$M -e "DELETE FROM inventory_item WHERE task_id IN (13,14);" 2>/dev/null
$M -e "DELETE FROM inventory_task WHERE id IN (13,14);" 2>/dev/null
echo "=== 删除后 ==="
$M -e "SELECT CONCAT('task=',COUNT(*)) FROM inventory_task;" 2>/dev/null
$M -e "SELECT CONCAT('item=',COUNT(*)) FROM inventory_item;" 2>/dev/null
echo DONE
