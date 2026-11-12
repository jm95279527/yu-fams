#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/photo
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
B=http://127.0.0.1:89
J='Content-Type: application/json'

echo "===== 1. SQL ====="
$M < $SRC/repair_photo.sql
$M -N -e "SELECT CONCAT('assets_repair.img 是否存在: ',COUNT(*)) FROM information_schema.columns WHERE table_schema='xm-assets' AND table_name='assets_repair' AND column_name='img';"
$M -N -e "SELECT CONCAT('  ',event_key,' | ',REPLACE(content,CHAR(10),' / ')) FROM notify_template WHERE event_key LIKE 'REPAIR%';"

echo "===== 2. 覆盖后端 ====="
cp $SRC/AssetsRepair.java $BACK/src/main/java/com/example/entity/
cp $SRC/AssetsRepairMapper.xml $BACK/src/main/resources/mapper/
cp $SRC/AssetsRepairServiceImpl.java $BACK/src/main/java/com/example/service/impl/
cp $SRC/ScanController.java $BACK/src/main/java/com/example/controller/
cp $SRC/repair_photo.sql $BACK/src/main/resources/sql/

echo "===== 3. 覆盖前端 ====="
cp $SRC/AssetsRepair.vue $SRC/StaffAssets.vue $FRONT/src/views/manager/
cp $SRC/Scan.vue $FRONT/src/views/

echo "===== 4. 构建后端 ====="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1
echo "backend build exit=$?"
tail -6 $SRC/build-back.log

echo "===== 5. 构建前端 ====="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo "frontend build exit=$?"
tail -3 $SRC/build-front.log

echo "===== 6. 发布 + systemd 重启 ====="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
nginx -s reload
systemctl restart yufams
for i in $(seq 1 30); do
  if curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:89/ | grep -q 200; then echo "UP after ${i}s"; break; fi
  sleep 1
done
systemctl is-active yufams

echo "===== 7. 图片上传链路验证 ====="
TOK=$(curl -s "$B/login" -H "$J" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"
python3 -c "open('/tmp/e2e_photo.png','wb').write(bytes.fromhex('89504e470d0a1a0a0000000d494844520000000100000001080600000'
'01f15c4890000000a49444154789c63000100000500010d0a2db40000000049454e44ae426082'))"
echo -n "  免登录上传: "
UP=$(curl -s -X POST "$B/files/upload" -F "file=@/tmp/e2e_photo.png")
echo "$UP" | head -c 150; echo
IMG=$(echo "$UP" | python3 -c "import sys,json;print(json.load(sys.stdin).get('data') or '')" 2>/dev/null)
echo -n "  回取图片: "; curl -s -o /dev/null -w "HTTP=%{http_code} TYPE=%{content_type}\n" "$B$IMG"

echo "===== 8. 报修（合并字段 + 照片）验证 ====="
AID=$($M -e "SELECT id FROM assets ORDER BY id LIMIT 1;" 2>/dev/null)
echo -n "  缺描述: "; curl -s -X POST "$B/assetsRepair/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"reporterName\":\"照片测试\",\"reporterPhone\":\"13100000021\"}" | head -c 120; echo
echo -n "  带描述+照片(登录): "; curl -s -X POST "$B/assetsRepair/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"assetsName\":\"E2E资产\",\"assetsCode\":\"E2E-PIC\",\"reporterName\":\"照片测试\",\"reporterPhone\":\"13100000021\",\"faultDesc\":\"E2E合并字段描述\",\"img\":\"$IMG\"}" | head -c 120; echo
echo -n "  扫码报修+照片(免登录): "; curl -s -X POST "$B/scan/repair" -H "$J" -d "{\"assetsId\":$AID,\"assetsName\":\"E2E资产\",\"assetsCode\":\"E2E-PIC2\",\"reporterName\":\"照片测试\",\"reporterPhone\":\"13100000022\",\"faultDesc\":\"E2E扫码照片描述\",\"img\":\"$IMG\"}" | head -c 120; echo
sleep 1
$M -e "SELECT CONCAT('  落库 id=',id,' 描述=',IFNULL(fault_desc,'(空)'),' 照片=',IFNULL(img,'(空)'),' staff_id=',IFNULL(staff_id,'NULL')) FROM assets_repair WHERE reporter_name='照片测试';" 2>/dev/null
echo "--- 提交通知内容 ---"
$M -e "SELECT CONCAT('  ',event_key,' | ',REPLACE(content,CHAR(10),' / ')) FROM notify_log ORDER BY id LIMIT 3;" 2>/dev/null

echo "===== 9. 清理 ====="
$M -e "DELETE FROM notify_log;" 2>/dev/null
$M -e "DELETE FROM robot_config;" 2>/dev/null
$M -e "DELETE FROM assets_repair WHERE reporter_name='照片测试';" 2>/dev/null
rm -f /tmp/e2e_photo.png
$M -e "SELECT CONCAT('  repair残留=',COUNT(*),' 通知=',(SELECT COUNT(*) FROM notify_log)) FROM assets_repair WHERE reporter_name='照片测试';" 2>/dev/null
echo DONE
