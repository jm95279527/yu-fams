#!/bin/bash
echo "===== assets 表结构 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "DESCRIBE assets;" | grep -iE 'staff|person|user|duty'
echo ""
echo "===== 全库查找引用 staff id 的列 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "SELECT TABLE_NAME, COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='xm-assets' AND (COLUMN_NAME LIKE '%staff%' OR COLUMN_NAME LIKE '%applicant%' OR COLUMN_NAME LIKE '%duty%' OR COLUMN_NAME LIKE '%receive%person%') ORDER BY TABLE_NAME;"
echo ""
echo "===== Constants ====="
grep -n "USER_DEFAULT_PASSWORD" /opt/yu-fams/Yu-FAMS-SpringBoot-master/src/main/java/com/example/common/Constants.java
echo DONE
