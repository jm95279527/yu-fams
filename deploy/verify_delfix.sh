#!/bin/bash
# 借用/维修 后台删除 验证：接口可删 + 删除已借出单据时库存自动恢复
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOKLEN=${#TOK}"
TOD=$(date +%F)

A=$($M -e "select id from assets where num > 0 and status='正常' order by id limit 1")
SNAP=$($M -e "select concat(num,'|',status) from assets where id=$A")
echo "ASSET=$A  SNAP(num|status)=$SNAP"

echo ""
echo "--- 1) 借用：建单 → 审核通过（扣库存） → 删除（应恢复库存）---"
curl -s -X POST $B/assetsReceive/add -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"assetsId\":$A,\"borrowerName\":\"测试删除\",\"borrowerPhone\":\"13800000001\",\"returnDate\":\"$TOD\",\"comment\":\"删除修复验证\"}"; echo
RID=$($M -e "select id from assets_receive where borrower_name='测试删除' order by id desc limit 1")
echo "RID=$RID"
curl -s -X PUT $B/assetsReceive/update -H "token: $TOK" -H 'Content-Type: application/json' -d "{\"id\":$RID,\"status\":\"通过\"}" > /dev/null
echo "审核通过后 assets: $($M -e "select concat(num,'|',status) from assets where id=$A")"
echo "删除借用单: $(curl -s -X DELETE $B/assetsReceive/delete/$RID -H "token: $TOK")"
echo "删除后 assets: $($M -e "select concat(num,'|',status) from assets where id=$A")"
echo "单据剩余: $($M -e "select count(*) from assets_receive where id=$RID")"

echo ""
echo "--- 2) 借用：直接删除「待审核」单（不应影响库存）---"
curl -s -X POST $B/assetsReceive/add -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"assetsId\":$A,\"borrowerName\":\"测试删除\",\"borrowerPhone\":\"13800000001\",\"returnDate\":\"$TOD\",\"comment\":\"待审核删除\"}" > /dev/null
RID2=$($M -e "select id from assets_receive where borrower_name='测试删除' order by id desc limit 1")
BEFORE2=$($M -e "select concat(num,'|',status) from assets where id=$A")
echo "删除前 assets=$BEFORE2 ; 删除返回=$(curl -s -X DELETE $B/assetsReceive/delete/$RID2 -H "token: $TOK")"
echo "删除后 assets=$($M -e "select concat(num,'|',status) from assets where id=$A")（应与删除前一致）"

echo ""
echo "--- 3) 维修：建单 → 删除（任意状态均可删）---"
curl -s -X POST $B/assetsRepair/add -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"assetsId\":$A,\"reporterName\":\"测试删除\",\"reporterPhone\":\"13800000001\",\"faultDesc\":\"删除修复验证\"}"; echo
EPID=$($M -e "select id from assets_repair where reporter_name='测试删除' order by id desc limit 1")
echo "EPID=$EPID 状态=$($M -e "select status from assets_repair where id=$EPID")"
echo "删除维修单: $(curl -s -X DELETE $B/assetsRepair/delete/$EPID -H "token: $TOK")"
echo "单据剩余: $($M -e "select count(*) from assets_repair where id=$EPID")"

echo ""
echo "--- 4) 清理 ---"
$M -e "delete from notify_log where content like '%测试删除%'"
$M -e "delete from assets_receive where borrower_name='测试删除'"
$M -e "delete from assets_repair where reporter_name='测试删除'"
echo "资产最终状态=$($M -e "select concat(num,'|',status) from assets where id=$A") ; 期望=$SNAP"
$M -e "select concat('receive_left=',count(*)) from assets_receive where borrower_name='测试删除'"
$M -e "select concat('repair_left=',count(*)) from assets_repair where reporter_name='测试删除'"
echo VERIFY_DELFIX_DONE
