#!/bin/bash
set -e
export MYSQL_PWD=YOUR_DB_PASSWORD
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master

echo "===== 0. SQL ====="
mysql -uroot xm-assets < /tmp/harden/system_harden.sql
echo "sql applied"

echo "===== 1. 复制后端文件 ====="
mkdir -p $BACK/src/main/java/com/example/common/filter $BACK/src/main/java/com/example/common/utils
cp /tmp/harden/AuditLog.java $BACK/src/main/java/com/example/entity/
cp /tmp/harden/AuditLogMapper.java $BACK/src/main/java/com/example/mapper/
cp /tmp/harden/AuditLogMapper.xml $BACK/src/main/resources/mapper/
cp /tmp/harden/AuditLogService.java $BACK/src/main/java/com/example/service/
cp /tmp/harden/AuditLogController.java $BACK/src/main/java/com/example/controller/
cp /tmp/harden/AuditLogFilter.java $BACK/src/main/java/com/example/common/filter/
cp /tmp/harden/LoginGuard.java $BACK/src/main/java/com/example/common/utils/
cp /tmp/harden/JwtInterceptor.java $BACK/src/main/java/com/example/common/config/
cp /tmp/harden/AdminService.java $BACK/src/main/java/com/example/service/
cp /tmp/harden/StaffService.java $BACK/src/main/java/com/example/service/
echo "backend files copied"

echo "===== 2. 复制前端文件 ====="
cp /tmp/harden/AuditLog.vue $FRONT/src/views/manager/
cp /tmp/harden/index.js $FRONT/src/router/index.js
echo "frontend files copied"

echo "===== 3. 构建后端 ====="
cd $BACK
mvn clean package -DskipTests -q 2>&1 | tail -8
echo "mvn done"

echo "===== 4. 构建前端 ====="
cd $FRONT
npm run build 2>&1 | tail -4

echo "===== 5. 部署前端到 nginx ====="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
nginx -s reload
echo "frontend deployed"

echo "===== 6. 重启后端 ====="
bash /tmp/restart_backend.sh
sleep 15
curl -s -o /dev/null -w "login HTTP %{http_code}\n" -X POST http://localhost:89/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}'
echo DONE
