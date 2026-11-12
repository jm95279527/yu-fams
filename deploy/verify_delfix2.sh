#!/bin/bash
# 借用/维修 后台删除验证（自建临时数据，不触碰用户数据）
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOKLEN=${#TOK}"

# ---- 建临时资产 ----
$M -e "insert into assets (name,category,no,num,date,status,location,comment) values ('测试删除用资产','测试分类','TEST-DEL-001',1,curdate(),'正常','测试地点','delfix-verify')"
A=$($M -e "select id from assets where comment='delfix-verify' order by id desc limit 1")
echo "临时资产 A=$A  初始 num|status = $($M -e "select concat(num,'|',status) from assets where id=$A")"

mkborrow () {  # $1=status $2=return_status
  $M -e "insert into assets_receive (assets_id,staff_id,borrower_name,borrower_phone,date,comment,return_date,status,return_status) values ($A,NULL,'测试删除','13800000001',now(),'delfix-verify',curdate(),'$1','$2')"
  $M -e "select id from assets_receive where comment='delfix-verify' order by id desc limit 1"
}
mkrepair () {  # $1=status
  $M -e "insert into assets_repair (assets_id,assets_name,status,fault_desc,date,reporter_name,reporter_phone) values ($A,'测试删除用资产','$1','delfix-verify',now(),'测试删除','13800000001')"
  $M -e "select id from assets_repair where fault_desc='delfix-verify' order by id desc limit 1"
}

echo ""
echo "=== 1) 借用[通过+未归还] 删除 → 库存应 +1 ==="
R1=$(mkborrow '通过' '未归还'); echo "RID=$R1 删除前 assets=$($M -e "select concat(num,'|',status) from assets where id=$A")"
echo "DELETE: $(curl -s -X DELETE $B/assetsReceive/delete/$R1 -H "token: $TOK")"
echo "删除后 assets=$($M -e "select concat(num,'|',status) from assets where id=$A")  单据剩余=$($M -e "select count(*) from assets_receive where id=$R1")"

echo ""
echo "=== 2) 借用[待审核] 删除 → 库存不变 ==="
$M -e "update assets set num=1,status='正常' where id=$A"
R2=$(mkborrow '待审核' '未归还'); echo "RID=$R2 删除前 assets=$($M -e "select concat(num,'|',status) from assets where id=$A")"
echo "DELETE: $(curl -s -X DELETE $B/assetsReceive/delete/$R2 -H "token: $TOK")"
echo "删除后 assets=$($M -e "select concat(num,'|',status) from assets where id=$A")  单据剩余=$($M -e "select count(*) from assets_receive where id=$R2")"

echo ""
echo "=== 3) 借用[通过+已归还] 删除 → 库存不变 ==="
R3=$(mkborrow '通过' '已归还'); echo "RID=$R3 删除前 assets=$($M -e "select concat(num,'|',status) from assets where id=$A")"
echo "DELETE: $(curl -s -X DELETE $B/assetsReceive/delete/$R3 -H "token: $TOK")"
echo "删除后 assets=$($M -e "select concat(num,'|',status) from assets where id=$A")  单据剩余=$($M -e "select count(*) from assets_receive where id=$R3")"

echo ""
echo "=== 4) 维修[维修中] 删除（旧前端不允许）==="
E1=$(mkrepair '维修中'); echo "EPID=$E1 状态=$($M -e "select status from assets_repair where id=$E1")"
echo "DELETE: $(curl -s -X DELETE $B/assetsRepair/delete/$E1 -H "token: $TOK")"
echo "单据剩余=$($M -e "select count(*) from assets_repair where id=$E1")"

echo ""
echo "=== 5) 维修[已完成] 删除（旧前端不允许）==="
E2=$(mkrepair '已完成'); echo "EPID=$E2 状态=$($M -e "select status from assets_repair where id=$E2")"
echo "DELETE: $(curl -s -X DELETE $B/assetsRepair/delete/$E2 -H "token: $TOK")"
echo "单据剩余=$($M -e "select count(*) from assets_repair where id=$E2")"

echo ""
echo "=== 6) 批量删除借用单 ==="
$M -e "update assets set num=1,status='正常' where id=$A"
BR1=$(mkborrow '通过' '未归还'); BR2=$(mkborrow '待审核' '未归还')
echo "BR1=$BR1 BR2=$BR2 删除前 assets=$($M -e "select concat(num,'|',status) from assets where id=$A")"
echo "DELETE batch: $(curl -s -X DELETE $B/assetsReceive/delete/batch -H "token: $TOK" -H 'Content-Type: application/json' -d "[$BR1,$BR2]")"
echo "删除后 assets=$($M -e "select concat(num,'|',status) from assets where id=$A")（应 +1：批量中只有1条是借出状态）"
echo "剩余=$($M -e "select count(*) from assets_receive where id in ($BR1,$BR2)")"

echo ""
echo "=== 7) 清理临时数据 ==="
$M -e "delete from assets_receive where comment='delfix-verify'"
$M -e "delete from assets_repair where fault_desc='delfix-verify'"
$M -e "delete from assets where comment='delfix-verify'"
echo "assets=$($M -e "select count(*) from assets where comment='delfix-verify'")"
echo "receive=$($M -e "select count(*) from assets_receive where comment='delfix-verify'")"
echo "repair=$($M -e "select count(*) from assets_repair where fault_desc='delfix-verify'")"
echo "assets_total=$($M -e "select count(*) from assets")  receive_total=$($M -e "select count(*) from assets_receive")  repair_total=$($M -e "select count(*) from assets_repair")"
echo VERIFY_DELFIX2_DONE
