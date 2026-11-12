#!/bin/bash
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>&1 <<'SQL' | grep -v "Warning"
SELECT id, username, name, role FROM admin;
SELECT '--- staff columns ---' AS info;
SHOW COLUMNS FROM staff;
SELECT '--- staff role values ---' AS info;
SELECT DISTINCT role FROM staff;
SELECT '--- all tables ---' AS info;
SHOW TABLES;
SQL
echo DONE
