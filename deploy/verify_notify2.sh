#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/nf2
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
B=http://127.0.0.1:89

echo "===== 1. 覆盖 + 构建 + 重启 ====="
cp $SRC/AssetsReceiveService.java $BACK/src/main/java/com/example/service/
cd $BACK
mvn clean package -DskipTests -q > $SRC/build.log 2>&1
echo "build exit=$?"
tail -3 $SRC/build.log
bash /tmp/restart89.sh

echo "===== 2. 验证领用通知内容（最小载荷，资产信息应取自库）====="
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"; J='Content-Type: application/json'
curl -s -X POST "$B/robotConfig/add" -H "$H" -H "$J" \
  -d '{"name":"E2E临时","type":"wechat","webhookUrl":"https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=e2e-temp","enabled":true}' > /dev/null
AID=$($M -e "SELECT id FROM assets WHERE num > 0 ORDER BY id LIMIT 1;" 2>/dev/null)
NUM0=$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)
echo "  asset=$AID num0=$NUM0"
curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" \
  -d "{\"assetsId\":$AID,\"returnDate\":\"2026-12-31\",\"comment\":\"E2E通知内容验证\"}" > /dev/null
RCV=$($M -e "SELECT id FROM assets_receive WHERE comment='E2E通知内容验证' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "  receive_id=$RCV"
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" \
  -d "{\"id\":$RCV,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"未归还\",\"returnDate\":\"2026-12-31\"}" > /dev/null
sleep 1
echo "--- 通知记录 ---"
$M -e "SELECT CONCAT('event=',event_key,' biz=',biz_type,'/',biz_id,' status=',status) FROM notify_log ORDER BY id DESC LIMIT 1;" 2>/dev/null
$M -e "SELECT CONCAT('title=',IFNULL(title,'')) FROM notify_log ORDER BY id DESC LIMIT 1;" 2>/dev/null
$M -e "SELECT CONCAT('content=',REPLACE(content,CHAR(10),' | ')) FROM notify_log ORDER BY id DESC LIMIT 1;" 2>/dev/null

echo "===== 3. 停用模板后应不再推送 ====="
$M -e "UPDATE notify_template SET enabled=0 WHERE event_key='RECEIVE_PASS';" 2>/dev/null
curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" \
  -d "{\"assetsId\":$AID,\"returnDate\":\"2026-12-31\",\"comment\":\"E2E停用模板验证\"}" > /dev/null
RCV2=$($M -e "SELECT id FROM assets_receive WHERE comment='E2E停用模板验证' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
BEFORE=$($M -e "SELECT COUNT(*) FROM notify_log;" 2>/dev/null)
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" \
  -d "{\"id\":$RCV2,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"未归还\",\"returnDate\":\"2026-12-31\"}" > /dev/null
sleep 1
AFTER=$($M -e "SELECT COUNT(*) FROM notify_log;" 2>/dev/null)
echo "  notify_log 条数: $BEFORE -> $AFTER （停用后应不变）"
$M -e "UPDATE notify_template SET enabled=1 WHERE event_key='RECEIVE_PASS';" 2>/dev/null

echo "===== 4. 清理 ====="
$M -e "DELETE FROM notify_log; DELETE FROM robot_config; DELETE FROM assets_receive WHERE id IN ($RCV,$RCV2); UPDATE assets SET num=$NUM0 WHERE id=$AID;" 2>/dev/null
$M -e "SELECT CONCAT('robot_config=',COUNT(*)) FROM robot_config; SELECT CONCAT('notify_log=',COUNT(*)) FROM notify_log; SELECT CONCAT('receive_left=',COUNT(*)) FROM assets_receive; SELECT CONCAT('num=',num) FROM assets WHERE id=$AID; SELECT CONCAT('tpl_enabled=',enabled) FROM notify_template WHERE event_key='RECEIVE_PASS';" 2>/dev/null
echo DONE
