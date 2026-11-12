#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e"
B=http://127.0.0.1:89
J='Content-Type: application/json'

echo "=== 当前配置 ==="
$M "SELECT CONCAT('  id=',id,' name=',IFNULL(name,''),' enabled=',enabled) FROM robot_config;" 2>/dev/null

echo "=== 去重：同一 webhook 只保留最后添加的那条 ==="
$M "DELETE r1 FROM robot_config r1 JOIN robot_config r2 ON r1.webhook_url = r2.webhook_url AND r1.id < r2.id;" 2>/dev/null
$M "SELECT CONCAT('  保留 id=',id,' name=',IFNULL(name,''),' enabled=',enabled) FROM robot_config;" 2>/dev/null

echo "=== 实测发送（往你的群里发一条测试消息）==="
TOK=$(curl -s "$B/login" -H "$J" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
RID=$($M "SELECT id FROM robot_config ORDER BY id DESC LIMIT 1;" 2>/dev/null)
curl -s -X POST "$B/robotConfig/test/$RID" -H "token: $TOK" --get --data-urlencode "message=**群机器人连通性测试**\n> 来自固定资产管理系统" | head -c 300; echo
echo "=== 该次发送的记录 ==="
$M "SELECT CONCAT('  ',create_time,' ',status,' | ',IFNULL(LEFT(response,140),'')) FROM notify_log ORDER BY id DESC LIMIT 1;" 2>/dev/null
echo DONE
