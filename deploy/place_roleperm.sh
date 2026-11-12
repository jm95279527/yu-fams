#!/bin/bash
set -e
SRC=/opt/yu-fams/Yu-FAMS-SpringBoot-master/src/main
VUE=/opt/yu-fams/Yu-FAMS-Vue-master/src
T=/tmp/roleperm

cp $T/entity/*.java   $SRC/java/com/example/entity/
cp $T/mapper/*.java   $SRC/java/com/example/mapper/
cp $T/service/*.java  $SRC/java/com/example/service/
cp $T/controller/*.java $SRC/java/com/example/controller/
cp $T/xml/*.xml       $SRC/resources/mapper/
cp $T/sql/role_perm.sql $SRC/resources/sql/
cp $T/fe/RolePerm.vue $VUE/views/manager/
cp $T/fe/Admin.vue    $VUE/views/manager/
cp $T/fe/Manager.vue  $VUE/views/Manager.vue
cp $T/fe/router_index.js $VUE/router/index.js
echo "FILES_PLACED"

mysql -uroot -pYOUR_DB_PASSWORD xm-assets < $SRC/resources/sql/role_perm.sql 2>&1 | grep -v "Warning" || true
echo "SQL_IMPORTED"
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>&1 <<'SQL' | grep -v "Warning"
SELECT id, name, code FROM sys_role ORDER BY id;
SELECT COUNT(*) AS menu_count FROM sys_menu;
SELECT COUNT(*) AS role_menu_count FROM sys_role_menu;
SELECT id, username, role_id FROM admin;
SQL
