#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master

echo "===== 1. 复制后端文件 ====="
cp /tmp/stafffiles/Staff.java $BACK/src/main/java/com/example/entity/Staff.java
cp /tmp/stafffiles/StaffService.java $BACK/src/main/java/com/example/service/StaffService.java
cp /tmp/stafffiles/StaffMapper.xml $BACK/src/main/resources/mapper/StaffMapper.xml
echo "backend files copied"

echo "===== 2. 复制前端文件 ====="
cp /tmp/stafffiles/Staff.vue $FRONT/src/views/manager/Staff.vue
echo "frontend file copied"

echo "===== 3. 构建后端 ====="
cd $BACK
mvn clean package -DskipTests -q 2>&1 | tail -5
echo "mvn exit=$?"

echo "===== 4. 构建前端 ====="
cd $FRONT
npm run build 2>&1 | tail -8
echo "npm build exit=$?"

echo "===== 5. 重启后端 ====="
pkill -f 'yu-fams' || true
sleep 2
nohup java -jar $BACK/target/yu-fams-0.0.1-SNAPSHOT.jar > /tmp/yu-fams.log 2>&1 &
sleep 8

echo "===== 6. 检查后端启动 ====="
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:89/staff/selectPage?pageNum=1\&pageSize=1
echo DONE
