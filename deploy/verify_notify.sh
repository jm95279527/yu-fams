#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"
J='Content-Type: application/json'

echo "=== 0) 菜单授权 ==="
$M -e "SELECT CONCAT('role=',role_id,' -> menu=',menu_id) FROM sys_role_menu WHERE menu_id IN (53,54);" 2>/dev/null
$M -e "SELECT CONCAT('menu53/api=',IFNULL(api,''),' menu54/api=',IFNULL(api,'')) FROM sys_menu WHERE id=53;" 2>/dev/null
$M -e "SELECT CONCAT('id=',id,' name=',name,' api=',IFNULL(api,'')) FROM sys_menu WHERE id IN (53,54);" 2>/dev/null

echo "=== 1) 机器人配置接口 ==="
curl -s -o /tmp/r1.json -w "  selectAll HTTP=%{http_code}\n" "$B/robotConfig/selectAll" -H "$H"
head -c 200 /tmp/r1.json; echo

echo "=== 2) 新增测试机器人（假 webhook）==="
curl -s -X POST "$B/robotConfig/add" -H "$H" -H "$J" \
  -d '{"name":"E2E测试机器人","type":"wechat","webhookUrl":"https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=e2e-test-key","enabled":true,"remark":"E2E"}' | head -c 200; echo
RID=$($M -e "SELECT id FROM robot_config ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "  robot_id=$RID"

echo "=== 3) 测试发送（预期失败：假 key）==="
curl -s -X POST "$B/robotConfig/test/$RID?message=**E2E连通性测试**" -H "$H" | head -c 400; echo

echo "=== 4) 模板列表 ==="
curl -s "$B/notify/templates" -H "$H" | python3 -c "import sys,json;d=json.load(sys.stdin);print('  code',d['code'],'templates',len(d['data']));print('  启用中的:',[t['eventKey'] for t in d['data'] if t['enabled']])"

echo "=== 5) 通知记录 ==="
curl -s "$B/notify/selectPage?pageNum=1&pageSize=10" -H "$H" | python3 -c "import sys,json;d=json.load(sys.stdin);print('  code',d['code'],'total',d['data']['total']);[print('   ',r['createTime'],r['eventKey'],r['status'],(r['response'] or '')[:80]) for r in d['data']['list']]"

echo "=== 6) 触发真实审批（领用：新增→审核通过）应产生 RECEIVE_PASS 推送 ==="
AID=$($M -e "SELECT id FROM assets WHERE num > 0 ORDER BY id DESC LIMIT 1;" 2>/dev/null)
NUM0=$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)
curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"returnDate\":\"2026-12-31\",\"comment\":\"E2E通知验证\"}" > /dev/null
RCV=$($M -e "SELECT id FROM assets_receive ORDER BY id DESC LIMIT 1;" 2>/dev/null)
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" -d "{\"id\":$RCV,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"未归还\",\"returnDate\":\"2026-12-31\"}" > /dev/null
sleep 1
$M -e "SELECT CONCAT('  log: ',event_key,' biz=',biz_type,'/',IFNULL(biz_id,0),' status=',status,' resp=',IFNULL(LEFT(response,70),'')) FROM notify_log WHERE event_key='RECEIVE_PASS' ORDER BY id DESC LIMIT 1;" 2>/dev/null
$M -e "SELECT CONCAT('  内容: ',REPLACE(LEFT(content,160),CHAR(10),' / ')) FROM notify_log WHERE event_key='RECEIVE_PASS' ORDER BY id DESC LIMIT 1;" 2>/dev/null

echo "=== 7) 清理 ==="
$M -e "DELETE FROM notify_log; DELETE FROM robot_config WHERE id=$RID; DELETE FROM assets_receive WHERE id=$RCV; UPDATE assets SET num=$NUM0 WHERE id=$AID;" 2>/dev/null
$M -e "SELECT CONCAT('robot_config=',COUNT(*)) FROM robot_config; SELECT CONCAT('notify_log=',COUNT(*)) FROM notify_log; SELECT CONCAT('assets_receive=',COUNT(*)) FROM assets_receive; SELECT CONCAT('asset_num=',num) FROM assets WHERE id=$AID;" 2>/dev/null
echo DONE
