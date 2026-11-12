#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master

echo "===== 1. 复制后端文件 ====="
cp /tmp/staffen/StaffService.java $BACK/src/main/java/com/example/service/StaffService.java
cp /tmp/staffen/StaffController.java $BACK/src/main/java/com/example/controller/StaffController.java
echo "backend files copied"

echo "===== 2. 复制前端文件 ====="
cp /tmp/staffen/Staff.vue $FRONT/src/views/manager/Staff.vue
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
curl -s -o /dev/null -w "staff API HTTP %{http_code}\n" "http://localhost:89/staff/selectPage?pageNum=1&pageSize=1"
echo DONE
