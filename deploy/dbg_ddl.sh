#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
echo "=== assets DDL ==="
$M -e "show create table assets\G" 2>/dev/null
echo ""
echo "=== assets_repair DDL ==="
$M -e "show create table assets_repair\G" 2>/dev/null
echo DBG4_DONE
