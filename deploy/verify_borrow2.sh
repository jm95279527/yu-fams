#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/borrow2
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
B=http://127.0.0.1:89
J='Content-Type: application/json'

echo "===== 1. 构建并重启 ====="
cp $SRC/AssetsReceiveService.java $BACK/src/main/java/com/example/service/
cd $BACK
mvn clean package -DskipTests -q > $SRC/build.log 2>&1
echo "build exit=$?"
tail -3 $SRC/build.log
bash /tmp/restart89.sh

echo "===== 2. 通知内容复查（审核请求体不带借用人/联系方式）====="
TOK=$(curl -s "$B/login" -H "$J" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"
AID=$($M -e "SELECT id FROM assets ORDER BY num DESC, id LIMIT 1;" 2>/dev/null)
NUM0=$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)
$M -e "UPDATE assets SET num=10 WHERE id=$AID;" 2>/dev/null
curl -s -X POST "$B/robotConfig/add" -H "$H" -H "$J" \
  -d '{"name":"E2E临时","type":"wechat","webhookUrl":"https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=e2e-tmp","enabled":true}' > /dev/null
curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" \
  -d "{\"assetsId\":$AID,\"borrowerName\":\"钱七\",\"borrowerPhone\":\"13500000005\",\"returnDate\":\"2026-12-31\",\"comment\":\"E2E通知复查\"}" > /dev/null
RID=$($M -e "SELECT id FROM assets_receive WHERE comment='E2E通知复查' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "  借用单 id=$RID"
# 审核请求体故意不带借用人/联系方式
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" \
  -d "{\"id\":$RID,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"未归还\",\"returnDate\":\"2026-12-31\"}" > /dev/null
sleep 1
$M -e "SELECT CONCAT('  标题=',IFNULL(title,'')) FROM notify_log ORDER BY id DESC LIMIT 1;" 2>/dev/null
$M -e "SELECT CONCAT('  内容=',REPLACE(content,CHAR(10),' | ')) FROM notify_log ORDER BY id DESC LIMIT 1;" 2>/dev/null

echo "===== 3. 报修通知内容复查 ====="
curl -s -X POST "$B/assetsRepair/add" -H "$H" -H "$J" \
  -d "{\"assetsId\":$AID,\"assetsName\":\"E2E资产\",\"assetsCode\":\"E2E-002\",\"reporterName\":\"孙八\",\"reporterPhone\":\"13400000006\",\"reason\":\"E2E通知复查报修\",\"faultDesc\":\"风扇异响\"}" > /dev/null
RPR=$($M -e "SELECT id FROM assets_repair WHERE reason='E2E通知复查报修' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
curl -s -X PUT "$B/assetsRepair/update" -H "$H" -H "$J" -d "{\"id\":$RPR,\"status\":\"维修中\"}" > /dev/null
sleep 1
$M -e "SELECT CONCAT('  标题=',IFNULL(title,'')) FROM notify_log ORDER BY id DESC LIMIT 1;" 2>/dev/null
$M -e "SELECT CONCAT('  内容=',REPLACE(content,CHAR(10),' | ')) FROM notify_log ORDER BY id DESC LIMIT 1;" 2>/dev/null

echo "===== 4. 清理与核对残留 ====="
$M -e "DELETE FROM notify_log;" 2>/dev/null
$M -e "DELETE FROM robot_config;" 2>/dev/null
$M -e "DELETE FROM assets_repair WHERE reason='E2E通知复查报修';" 2>/dev/null
$M -e "DELETE FROM assets_receive WHERE comment='E2E通知复查';" 2>/dev/null
$M -e "UPDATE assets SET num=$NUM0 WHERE id=$AID;" 2>/dev/null
echo "--- 剩余数据（应为你自己的数据，无 E2E 备注）---"
$M -e "SELECT CONCAT('  receive id=',id,' cmt=',IFNULL(comment,'')) FROM assets_receive;" 2>/dev/null
$M -e "SELECT CONCAT('  repair  id=',id,' reason=',IFNULL(reason,'')) FROM assets_repair;" 2>/dev/null
$M -e "SELECT CONCAT('  notify_log=',COUNT(*)) FROM notify_log; SELECT CONCAT('  robot_config=',COUNT(*)) FROM robot_config; SELECT CONCAT('  asset$AID num=',num) FROM assets WHERE id=$AID;" 2>/dev/null
echo DONE
