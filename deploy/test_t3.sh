#!/bin/bash
B=http://localhost:89
M="mysql -N -uroot -pYOUR_DB_PASSWORD xm-assets"

TOKEN=$(curl -s -X POST "$B/login" -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
echo "token=${TOKEN:0:12}..."
AUTH="token: $TOKEN"

echo "=== 0. 资产26 调拨前 ==="
$M -e "SELECT CONCAT('dept=',department_id,',staff=',IFNULL(staff_id,'NULL'),',loc=',IFNULL(location,'NULL')) FROM assets WHERE id=26;" 2>/dev/null

echo "=== 1. 提交调拨 26: 部门12->13, 地点111->测试室A ==="
curl -s -X POST "$B/assetsTransfer/add" -H "Content-Type: application/json" -H "$AUTH" \
  -d '{"assetsId":26,"toDepartmentId":13,"toLocation":"测试室A","reason":"接口全流程测试"}'
echo
TID=$($M -e "SELECT id FROM assets_transfer ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "tid=$TID"
$M -e "SELECT CONCAT('from: dept=',from_department_id,'/',from_department_name,' loc=',IFNULL(from_location,'NULL'),' | to: dept=',IFNULL(to_department_id,'NULL'),'/',to_department_name,' loc=',to_location,' | ',status,' by ',transfer_staff_name) FROM assets_transfer WHERE id=$TID;" 2>/dev/null

echo "=== 2. 无变化申请应被业务拒绝 ==="
curl -s -X POST "$B/assetsTransfer/add" -H "Content-Type: application/json" -H "$AUTH" \
  -d '{"assetsId":26,"toDepartmentId":12,"toLocation":"111","reason":"无变化"}'
echo

echo "=== 3. 驳回（缺原因 400 / 带原因成功 / 重复审核拦截） ==="
curl -s -X POST "$B/assetsTransfer/audit/$TID" -H "Content-Type: application/json" -H "$AUTH" -d '{"pass":false}'
echo
curl -s -X POST "$B/assetsTransfer/audit/$TID" -H "Content-Type: application/json" -H "$AUTH" -d '{"pass":false,"rejectReason":"测试驳回-资料不全"}'
echo
curl -s -X POST "$B/assetsTransfer/audit/$TID" -H "Content-Type: application/json" -H "$AUTH" -d '{"pass":true}'
echo
$M -e "SELECT CONCAT(status,' | ',approver_name,' | ',approve_comment) FROM assets_transfer WHERE id=$TID;" 2>/dev/null
$M -e "SELECT CONCAT('驳回后资产26: dept=',department_id,',loc=',location) FROM assets WHERE id=26;" 2>/dev/null

echo "=== 4. 重新提交并审核通过 ==="
curl -s -X POST "$B/assetsTransfer/add" -H "Content-Type: application/json" -H "$AUTH" \
  -d '{"assetsId":26,"toDepartmentId":13,"toLocation":"测试室A","reason":"接口全流程测试-通过"}'
echo
TID2=$($M -e "SELECT id FROM assets_transfer ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "tid2=$TID2"
curl -s -X POST "$B/assetsTransfer/audit/$TID2" -H "Content-Type: application/json" -H "$AUTH" -d '{"pass":true}'
echo
$M -e "SELECT CONCAT('单据: ',status,' by ',approver_name,' at ',approve_time) FROM assets_transfer WHERE id=$TID2;" 2>/dev/null
$M -e "SELECT CONCAT('生效后资产26: dept=',department_id,'/',(SELECT name FROM department WHERE id=assets.department_id),',loc=',location) FROM assets WHERE id=26;" 2>/dev/null

echo "=== 5. 变更明细历史 ==="
$M -e "SELECT CONCAT(operation_type,': ',before_department_name,'/',IFNULL(before_location,'NULL'),' -> ',after_department_name,'/',after_location) FROM assets_detail WHERE assets_id=26 ORDER BY id DESC LIMIT 1;" 2>/dev/null

echo "=== 6. 历史接口 ==="
curl -s -H "$AUTH" "$B/assetsTransfer/selectByAssetsId/26" | head -c 200
echo

echo "=== 7. 清理：还原资产26、删除测试单据/明细及历史演示脏数据 ==="
$M -e "UPDATE assets SET department_id=12, location='111' WHERE id=26;" 2>/dev/null
$M -e "DELETE FROM assets_transfer WHERE reason LIKE '接口全流程测试%' OR reason LIKE '堆栈排查%';" 2>/dev/null
$M -e "DELETE FROM assets_detail WHERE assets_id=26 AND operation_type='调拨';" 2>/dev/null
echo "剩余调拨单ID：$($M -e 'SELECT GROUP_CONCAT(id) FROM assets_transfer;' 2>/dev/null)"
