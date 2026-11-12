#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
J='Content-Type: application/json'
TOK=$(curl -s "$B/login" -H "$J" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"

# 选一个库存足够的资产做测试，结束后恢复
AID=$($M -e "SELECT id FROM assets ORDER BY num DESC, id LIMIT 1;" 2>/dev/null)
NUM0=$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)
$M -e "UPDATE assets SET num=10 WHERE id=$AID;" 2>/dev/null
echo "测试资产 id=$AID（临时置库存10，结束后恢复为 $NUM0）"

echo "=== 1) 借用必填校验 ==="
echo -n "  缺借用人: "; curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"borrowerPhone\":\"13800000000\",\"returnDate\":\"2026-12-31\"}" | head -c 120; echo
echo -n "  缺联系方式: "; curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"borrowerName\":\"张三\",\"returnDate\":\"2026-12-31\"}" | head -c 120; echo
echo -n "  手机号格式错: "; curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"borrowerName\":\"张三\",\"borrowerPhone\":\"123\",\"returnDate\":\"2026-12-31\"}" | head -c 140; echo

echo "=== 2) 借用正常提交（管理员）==="
curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" \
  -d "{\"assetsId\":$AID,\"borrowerName\":\"张三\",\"borrowerPhone\":\"13800000001\",\"returnDate\":\"2026-12-31\",\"comment\":\"E2E借用验证\"}" | head -c 120; echo
RID=$($M -e "SELECT id FROM assets_receive WHERE comment='E2E借用验证' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
$M -e "SELECT CONCAT('  落库: id=',id,' 借用人=',IFNULL(borrower_name,''),' 联系方式=',IFNULL(borrower_phone,''),' 状态=',status) FROM assets_receive WHERE id=$RID;" 2>/dev/null

echo "=== 3) 扫码提交借用（★不带 token，任何人可提交）==="
curl -s -X POST "$B/scan/borrow" -H "$J" \
  -d "{\"assetsId\":$AID,\"borrowerName\":\"李四\",\"borrowerPhone\":\"13900000002\",\"returnDate\":\"2026-12-31\",\"comment\":\"E2E扫码借用\"}" | head -c 160; echo
SCN=$($M -e "SELECT id FROM assets_receive WHERE comment='E2E扫码借用' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
$M -e "SELECT CONCAT('  落库: id=',id,' 借用人=',IFNULL(borrower_name,''),' 联系方式=',IFNULL(borrower_phone,''),' staff_id=',IFNULL(staff_id,'NULL'),' 状态=',status) FROM assets_receive WHERE id=$SCN;" 2>/dev/null

echo "=== 4) 扫码提交报修（★不带 token）==="
curl -s -X POST "$B/scan/repair" -H "$J" \
  -d "{\"assetsId\":$AID,\"assetsName\":\"扫码测试资产\",\"assetsCode\":\"SCAN-001\",\"reporterName\":\"王五\",\"reporterPhone\":\"13700000003\",\"reason\":\"E2E扫码报修\",\"faultDesc\":\"屏幕闪烁\"}" | head -c 160; echo
RPR=$($M -e "SELECT id FROM assets_repair WHERE reason='E2E扫码报修' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
$M -e "SELECT CONCAT('  落库: id=',id,' 报修人=',IFNULL(reporter_name,''),' 报修电话=',IFNULL(reporter_phone,''),' staff_id=',IFNULL(staff_id,'NULL'),' 状态=',status) FROM assets_repair WHERE id=$RPR;" 2>/dev/null

echo "=== 5) 带登录态提交报修（管理员新增报修）==="
echo -n "  缺报修电话: "; curl -s -X POST "$B/assetsRepair/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"reporterName\":\"赵六\",\"reason\":\"E2E报修验证\",\"faultDesc\":\"x\"}" | head -c 130; echo
curl -s -X POST "$B/assetsRepair/add" -H "$H" -H "$J" \
  -d "{\"assetsId\":$AID,\"assetsName\":\"E2E资产\",\"assetsCode\":\"E2E-001\",\"reporterName\":\"赵六\",\"reporterPhone\":\"13600000004\",\"reason\":\"E2E报修验证\",\"faultDesc\":\"键盘失灵\"}" | head -c 120; echo
RPR2=$($M -e "SELECT id FROM assets_repair WHERE reason='E2E报修验证' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
$M -e "SELECT CONCAT('  落库: id=',id,' 报修人=',IFNULL(reporter_name,''),' 电话=',IFNULL(reporter_phone,'')) FROM assets_repair WHERE id=$RPR2;" 2>/dev/null

echo "=== 6) 借用审核通过 -> 通知内容含联系方式 ==="
curl -s -X POST "$B/robotConfig/add" -H "$H" -H "$J" \
  -d '{"name":"E2E临时","type":"wechat","webhookUrl":"https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=e2e-tmp","enabled":true}' > /dev/null
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" \
  -d "{\"id\":$RID,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"未归还\",\"returnDate\":\"2026-12-31\"}" > /dev/null
sleep 1
$M -e "SELECT CONCAT('  标题=',IFNULL(title,'')) FROM notify_log ORDER BY id DESC LIMIT 1;" 2>/dev/null
$M -e "SELECT CONCAT('  内容=',REPLACE(content,CHAR(10),' | ')) FROM notify_log ORDER BY id DESC LIMIT 1;" 2>/dev/null
$M -e "SELECT CONCAT('  业务类型=',IFNULL(biz_type,'')) FROM notify_log ORDER BY id DESC LIMIT 1;" 2>/dev/null

echo "=== 清理 ==="
$M -e "DELETE FROM notify_log;" 2>/dev/null
$M -e "DELETE FROM robot_config;" 2>/dev/null
$M -e "DELETE FROM assets_repair WHERE reason IN ('E2E扫码报修','E2E报修验证');" 2>/dev/null
$M -e "DELETE FROM assets_receive WHERE comment IN ('E2E借用验证','E2E扫码借用');" 2>/dev/null
$M -e "UPDATE assets SET num=$NUM0 WHERE id=$AID;" 2>/dev/null
$M -e "SELECT CONCAT('  receive剩余=',COUNT(*)) FROM assets_receive; SELECT CONCAT('  repair剩余=',COUNT(*)) FROM assets_repair; SELECT CONCAT('  notify_log=',COUNT(*)) FROM notify_log; SELECT CONCAT('  robot_config=',COUNT(*)) FROM robot_config; SELECT CONCAT('  asset num=',num) FROM assets WHERE id=$AID;" 2>/dev/null
echo DONE
