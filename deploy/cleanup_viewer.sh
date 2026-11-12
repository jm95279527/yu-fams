#!/bin/bash
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "DELETE FROM admin WHERE username IN ('viewer_ui2','viewer_api');"
echo "===== 最终库状态 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "SELECT id,username,role_id FROM admin; SELECT id,name,code FROM sys_role;"
echo "===== 验证 sys_menu.api 字段 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "SELECT COUNT(*) AS menus_with_api FROM sys_menu WHERE api IS NOT NULL;"
echo DONE
