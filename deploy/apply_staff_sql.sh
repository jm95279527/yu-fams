#!/bin/bash
cd /opt/yu-fams/Yu-FAMS-SpringBoot-master
echo "===== 应用 staff 增强 SQL ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null < src/main/resources/sql/staff_enhance.sql
echo "exit=$?"
echo "===== 验证 staff 表结构 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "DESCRIBE staff;"
echo DONE
