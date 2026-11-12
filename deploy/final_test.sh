#!/bin/bash
B=http://localhost:89
M="mysql -N -uroot -pYOUR_DB_PASSWORD xm-assets"
TOKEN=$(curl -s -X POST "$B/login" -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
AUTH="token: $TOKEN"

echo "=== 现存 UI 测试单据 ==="
$M -e "SELECT CONCAT(id,': ',status,' to_dept=',IFNULL(to_department_id,'NULL'),' to_loc=',to_location,' | 审核人=',IFNULL(approver_name,'NULL')) FROM assets_transfer ORDER BY id;" 2>/dev/null

RID=$($M -e "SELECT id FROM assets_transfer WHERE status='已拒绝' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "=== 驳回单据 $RID 编辑后重新提交（PUT update）==="
curl -s -X PUT "$B/assetsTransfer/update" -H "Content-Type: application/json" -H "$AUTH" \
  -d "{\"id\":$RID,\"assetsId\":26,\"toDepartmentId\":12,\"toLocation\":\"111\",\"reason\":\"UI测试-驳回后重新提交\",\"comment\":\"\"}"
echo
$M -e "SELECT CONCAT('重新提交后: status=',status,', approver=',IFNULL(approver_name,'NULL')) FROM assets_transfer WHERE id=$RID;" 2>/dev/null

echo "=== 审核通过（资产应回到 dept=12/111）==="
curl -s -X POST "$B/assetsTransfer/audit/$RID" -H "Content-Type: application/json" -H "$AUTH" -d '{"pass":true}'
echo
$M -e "SELECT CONCAT('资产26最终: dept=',department_id,',loc=',location) FROM assets WHERE id=26;" 2>/dev/null

echo "=== 已调拨单据禁止修改 ==="
curl -s -X PUT "$B/assetsTransfer/update" -H "Content-Type: application/json" -H "$AUTH" \
  -d "{\"id\":$RID,\"reason\":\"试图改已完成单\"}"
echo

echo "=== 清理全部测试单据与明细，恢复初始状态 ==="
$M -e "DELETE FROM assets_transfer; DELETE FROM assets_detail WHERE assets_id=26 AND operation_type='调拨';" 2>/dev/null
echo "assets_transfer 剩余: $($M -e 'SELECT COUNT(*) FROM assets_transfer;' 2>/dev/null)"
echo "assets_detail(26/调拨) 剩余: $($M -e "SELECT COUNT(*) FROM assets_detail WHERE assets_id=26 AND operation_type='调拨';" 2>/dev/null)"
echo "--- 资产26（应 dept=12 loc=111）---"
$M -e "SELECT CONCAT('id=26 name=',name,' dept=',department_id,' loc=',location,' status=',status) FROM assets WHERE id=26;" 2>/dev/null
echo "--- 空列表接口验证 ---"
curl -s "$B/assetsTransfer/selectPage?pageNum=1&pageSize=5" | head -c 120
echo
