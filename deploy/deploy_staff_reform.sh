#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master

echo "===== 1. 复制后端文件 ====="
cp /tmp/staffref/Staff.java $BACK/src/main/java/com/example/entity/Staff.java
cp /tmp/staffref/StaffMapper.java $BACK/src/main/java/com/example/mapper/StaffMapper.java
cp /tmp/staffref/StaffMapper.xml $BACK/src/main/resources/mapper/StaffMapper.xml
cp /tmp/staffref/StaffService.java $BACK/src/main/java/com/example/service/StaffService.java
cp /tmp/staffref/StaffController.java $BACK/src/main/java/com/example/controller/StaffController.java
cp /tmp/staffref/WechatWorkSyncService.java $BACK/src/main/java/com/example/service/WechatWorkSyncService.java
cp /tmp/staffref/JwtInterceptor.java $BACK/src/main/java/com/example/common/config/JwtInterceptor.java
echo "backend files copied"

echo "===== 2. 复制前端文件 ====="
cp /tmp/staffref/Staff.vue $FRONT/src/views/manager/Staff.vue
cp /tmp/staffref/StaffPerson.vue $FRONT/src/views/manager/StaffPerson.vue
cp /tmp/staffref/Assets.vue $FRONT/src/views/manager/Assets.vue
cp /tmp/staffref/AssetsIn.vue $FRONT/src/views/manager/AssetsIn.vue
cp /tmp/staffref/AssetsTransfer.vue $FRONT/src/views/manager/AssetsTransfer.vue
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
