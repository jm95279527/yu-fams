#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
jqv() { python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('code'),'|',str(d.get('msg'))[:60],'|',str(d.get('data'))[:200])"; }

echo "=== java 进程数 ==="
ps -ef | grep springboot | grep -v grep | wc -l

AID=$($M -e "SELECT id FROM assets WHERE num > 0 ORDER BY id DESC LIMIT 1;" 2>/dev/null)
NUM0=$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)
echo "测试资产 id=$AID 初始num=$NUM0  admin_id=$($M -e "SELECT id FROM admin ORDER BY id LIMIT 1;" 2>/dev/null)"

echo "=== 1) 新增领用（不传 staffId，应回退为当前管理员）==="
curl -s -X POST "$B/assetsReceive/add?token=$TOK" -H 'Content-Type: application/json' \
  -d "{\"assetsId\":$AID,\"returnDate\":\"2026-12-31\",\"comment\":\"E2E临时验证\"}" | jqv
RID=$($M -e "SELECT id FROM assets_receive ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "领用单 id=$RID"
$M -e "SELECT CONCAT('  staff_id=',staff_id,' status=',status,' return_status=',return_status,' return_date=',return_date) FROM assets_receive WHERE id=$RID;" 2>/dev/null

echo "=== 2) 领用列表分页 ==="
curl -s "$B/assetsReceive/selectPage?pageNum=1&pageSize=5&token=$TOK" | python3 -c "import sys,json;d=json.load(sys.stdin);print('code',d['code'],'total',d['data']['total'],'首条',d['data']['list'][0] if d['data']['list'] else None)"

echo "=== 3) 审核通过（资产num应 -1）==="
curl -s -X PUT "$B/assetsReceive/update?token=$TOK" -H 'Content-Type: application/json' \
  -d "{\"id\":$RID,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"未归还\",\"returnDate\":\"2026-12-31\"}" | jqv
echo "  资产num: $NUM0 -> $($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)"

echo "=== 4) 新增报修（管理员直接选资产）==="
curl -s -X POST "$B/assetsRepair/add?token=$TOK" -H 'Content-Type: application/json' \
  -d "{\"assetsId\":$AID,\"assetsName\":\"E2E测试资产\",\"assetsCode\":\"E2E-CODE\",\"reason\":\"E2E理由\",\"faultDesc\":\"E2E故障\"}" | jqv
PID=$($M -e "SELECT id FROM assets_repair ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "报修单 id=$PID"
$M -e "SELECT CONCAT('  assets_id=',assets_id,' name=',IFNULL(assets_name,''),' status=',status,' date=',IFNULL(date,'')) FROM assets_repair WHERE id=$PID;" 2>/dev/null

echo "=== 5) 报修列表分页 ==="
curl -s "$B/assetsRepair/selectPage?pageNum=1&pageSize=5&token=$TOK" | python3 -c "import sys,json;d=json.load(sys.stdin);print('code',d['code'],'total',d['data']['total'])"

echo "=== 6) 报修改为维修中 ==="
curl -s -X PUT "$B/assetsRepair/update?token=$TOK" -H 'Content-Type: application/json' \
  -d "{\"id\":$PID,\"status\":\"维修中\"}" | jqv

echo "=== 7) 完成维修（前端会带 completeTime 字符串，验证 Jackson 能否解析）==="
curl -s -X PUT "$B/assetsRepair/update?token=$TOK" -H 'Content-Type: application/json' \
  -d "{\"id\":$PID,\"status\":\"已完成\",\"repairResult\":\"维修完成\",\"completeTime\":\"2026/9/14 15:40:00\"}" | head -c 300; echo
$M -e "SELECT CONCAT('  status=',status,' complete_time=',IFNULL(complete_time,'NULL')) FROM assets_repair WHERE id=$PID;" 2>/dev/null

echo "=== 清理 ==="
$M -e "DELETE FROM assets_repair WHERE id=$PID; DELETE FROM assets_receive WHERE id=$RID; UPDATE assets SET num=$NUM0 WHERE id=$AID;" 2>/dev/null
$M -e "SELECT CONCAT('assets_receive=',COUNT(*)) FROM assets_receive; SELECT CONCAT('assets_repair=',COUNT(*)) FROM assets_repair; SELECT CONCAT('asset num=',num) FROM assets WHERE id=$AID;" 2>/dev/null
echo DONE
