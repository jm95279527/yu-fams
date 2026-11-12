#!/bin/bash
cd /opt/yu-fams/Yu-FAMS-SpringBoot-master
echo "===== 应用 staff 改造 SQL ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null < src/main/resources/sql/staff_reform.sql
echo "exit=$?"
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "DESCRIBE staff;"
echo DONE
