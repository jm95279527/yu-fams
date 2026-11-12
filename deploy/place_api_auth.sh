#!/bin/bash
set -e
B=/opt/yu-fams/Yu-FAMS-SpringBoot-master
cp /tmp/menu_api_auth.sql $B/src/main/resources/sql/menu_api_auth.sql
cp /tmp/role_perm.sql $B/src/main/resources/sql/role_perm.sql
cp /tmp/SysMenu.java $B/src/main/java/com/example/entity/SysMenu.java
cp /tmp/SysMenuMapper.xml $B/src/main/resources/mapper/SysMenuMapper.xml
cp /tmp/SysRoleService.java $B/src/main/java/com/example/service/SysRoleService.java
cp /tmp/JwtInterceptor.java $B/src/main/java/com/example/common/config/JwtInterceptor.java
cp /tmp/WebConfig.java $B/src/main/java/com/example/common/config/WebConfig.java
cp /tmp/AdminService.java $B/src/main/java/com/example/service/AdminService.java

echo "===== 应用 SQL 迁移（sys_menu 加 api 字段）====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null < $B/src/main/resources/sql/menu_api_auth.sql
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "SELECT id,name,api FROM sys_menu WHERE api IS NOT NULL ORDER BY id;"

echo "===== 构建后端 ====="
cd $B
mvn clean package -DskipTests -s /opt/yu-fams/m2-settings.xml 2>&1 | tail -8

echo "===== 重启服务 ====="
systemctl restart yufams
sleep 4
systemctl is-active yufams
journalctl -u yufams -n 15 --no-pager | grep -E "Started|ERROR|Exception" | tail -10
echo DONE
