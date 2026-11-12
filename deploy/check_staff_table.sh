#!/bin/bash
echo "===== staff 表结构 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "DESCRIBE staff;"
echo ""
echo "===== staff 现有数据 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "SELECT id,username,name,phone,department_id,role FROM staff;"
echo ""
echo "===== department 表 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "SELECT id,name FROM department;"
echo DONE
