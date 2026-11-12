#!/bin/bash
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>&1 <<'SQL' | grep -v "Warning"
DELETE FROM admin WHERE username IN ('viewer01','hack01','hack');
SELECT id, username, role_id FROM admin;
SELECT id, name, code FROM sys_role;
SELECT COUNT(*) AS role_menu_left FROM sys_role_menu;
SQL
echo CLEANED
