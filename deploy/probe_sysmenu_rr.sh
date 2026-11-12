#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "=== sys_menu 列 ==="
$M -e "SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION) FROM information_schema.columns WHERE table_schema='xm-assets' AND table_name='sys_menu';" 2>&1 | head -2
echo "=== sys_menu 全部行 ==="
$M -e "SELECT * FROM sys_menu ORDER BY id;" 2>&1 | head -60
echo "=== 角色-菜单授权 ==="
$M -e "SELECT CONCAT(role_id,' -> menu_id=',menu_id) FROM sys_role_menu ORDER BY role_id,menu_id;" 2>&1 | head -60
echo DONE
