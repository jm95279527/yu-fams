#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
echo "=== sys_menu 结构 ==="
$M -e "SHOW CREATE TABLE sys_menu\G" 2>/dev/null | head -25
echo "=== sys_role_menu 结构 ==="
$M -e "SHOW CREATE TABLE sys_role_menu\G" 2>/dev/null | head -20
echo "=== 已建表检查 ==="
$M -N -e "SELECT CONCAT('robot_config=',COUNT(*)) FROM robot_config; SELECT CONCAT('notify_template=',COUNT(*)) FROM notify_template; SELECT CONCAT('notify_log=',COUNT(*)) FROM notify_log;" 2>/dev/null
echo "=== sys_menu 当前最大 id ==="
$M -N -e "SELECT CONCAT('max_id=',IFNULL(MAX(id),0)) FROM sys_menu;" 2>/dev/null
echo DONE
