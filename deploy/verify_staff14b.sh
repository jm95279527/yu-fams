#!/bin/bash
# 离职标志专项验证（自建临时数据）
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
TOD=$(date +%F)
echo "TOKLEN=${#TOK}"

echo "--- 建在职员工 ---"
curl -s -X POST $B/staff/add -H "token: $TOK" -H 'Content-Type: application/json' \
  -d '{"username":"zzmark_a","name":"离职标志甲","password":"123","status":"在职"}'; echo
SID=$($M -e "select id from staff where username='zzmark_a'")
echo "SID=$SID"

echo "--- 建临时资产（责任人=该员工）---"
curl -s -X POST $B/assets/add -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"name\":\"ZZMARKASSET\",\"category\":\"测试\",\"no\":\"ZZMARK-1\",\"num\":1,\"date\":\"$TOD\",\"status\":\"正常\",\"staffId\":$SID,\"location\":\"测试\"}"; echo
AID=$($M -e "select id from assets where no='ZZMARK-1'")
echo "AID=$AID"

echo "--- 在职时：台账责任人 ---"
curl -s "$B/assets/selectPage?pageNum=1&pageSize=50" -H "token: $TOK" | python3 -c "
import sys,json
for x in json.load(sys.stdin)['data']['list']:
    if x.get('no')=='ZZMARK-1': print('   责任人 =',repr(x.get('staffName')))"

echo "--- 办理离职 ---"
curl -s -X PUT $B/staff/leave/$SID -H "token: $TOK"; echo

echo "--- 离职后：台账责任人（应带（离职））---"
curl -s "$B/assets/selectPage?pageNum=1&pageSize=50" -H "token: $TOK" | python3 -c "
import sys,json
for x in json.load(sys.stdin)['data']['list']:
    if x.get('no')=='ZZMARK-1': print('   责任人 =',repr(x.get('staffName')))"

echo "--- 借用记录（借用人留空，前端回退员工名）---"
$M -e "insert into assets_receive (assets_id,staff_id,borrower_name,borrower_phone,date,comment,return_date,status,return_status) values ($AID,$SID,'','13800000009',now(),'zzmark-verify',curdate(),'通过','未归还')"
RID=$($M -e "select id from assets_receive where comment='zzmark-verify'")
curl -s "$B/assetsReceive/selectPage?pageNum=1&pageSize=50" -H "token: $TOK" | python3 -c "
import sys,json
for x in json.load(sys.stdin)['data']['list']:
    if x.get('id')==$RID: print('   staffName =',repr(x.get('staffName')),' borrowerName =',repr(x.get('borrowerName')))"

echo "--- 维修记录 ---"
$M -e "insert into assets_repair (assets_id,assets_name,status,fault_desc,date,staff_id) values ($AID,'ZZMARKASSET','已完成','zzmark-verify',now(),$SID)"
EID=$($M -e "select id from assets_repair where fault_desc='zzmark-verify'")
curl -s "$B/assetsRepair/selectPage?pageNum=1&pageSize=50" -H "token: $TOK" | python3 -c "
import sys,json
for x in json.load(sys.stdin)['data']['list']:
    if x.get('id')==$EID: print('   staffName =',repr(x.get('staffName')))"

echo "--- 入库单责任人/提交人（把现有入库单的 manager_id 指向该员工）---"
MID=$($M -e "select id from assets_in order by id limit 1")
$M -e "update assets_in set manager_id=$SID where id=$MID"
curl -s "$B/assetsIn/selectPage?pageNum=1&pageSize=50" -H "token: $TOK" | python3 -c "
import sys,json
for x in json.load(sys.stdin)['data']['list']:
    if x.get('id')==$MID: print('   managerName =',repr(x.get('managerName')),' staffName =',repr(x.get('staffName')))"
$M -e "update assets_in set manager_id=null where id=$MID"

echo "--- 员工列表姓名（不应被污染）---"
curl -s "$B/staff/selectAll" -H "token: $TOK" | python3 -c "
import sys,json
for x in json.load(sys.stdin)['data']:
    if (x.get('username') or '')=='zzmark_a': print('   name =',repr(x.get('name')),' status =',x.get('status'))"

echo "--- 清理 ---"
$M -e "delete from assets_receive where comment='zzmark-verify'"
$M -e "delete from assets_repair where fault_desc='zzmark-verify'"
$M -e "delete from assets where no='ZZMARK-1'"
$M -e "delete from staff where username='zzmark_a'"
echo "left staff=$($M -e "select count(*) from staff where username='zzmark_a'") asset=$($M -e "select count(*) from assets where no='ZZMARK-1'") receive=$($M -e "select count(*) from assets_receive where comment='zzmark-verify'") repair=$($M -e "select count(*) from assets_repair where fault_desc='zzmark-verify'")"
echo "总数 staff=$($M -e "select count(*) from staff") assets=$($M -e "select count(*) from assets") receive=$($M -e "select count(*) from assets_receive") repair=$($M -e "select count(*) from assets_repair")"
echo VERIFY14B_DONE
