#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
B=http://127.0.0.1:89
J='Content-Type: application/json'

echo "=== 重启前 ==="
ps -eo pid,lstart,cmd | grep springboot | grep -v grep
ls -l /opt/yu-fams/Yu-FAMS-SpringBoot-master/target/springboot-0.0.1-SNAPSHOT.jar

echo "=== 彻底杀掉所有 java 后重启 ==="
pkill -9 -f 'springboot-0.0.1-SNAPSHOT' || true
sleep 3
echo "剩余 java 进程数: $(ps -ef | grep springboot | grep -v grep | wc -l)"
bash /tmp/restart89.sh

echo "=== 重启后 ==="
ps -eo pid,lstart,cmd | grep springboot | grep -v grep
echo "java 进程数: $(ps -ef | grep springboot | grep -v grep | wc -l)"

echo "=== 功能复核：归还应使库存 +1（旧代码只有 STAFF 才有此行为）==="
TOK=$(curl -s "$B/login" -H "$J" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"
AID=$($M -e "SELECT id FROM assets WHERE num > 0 ORDER BY num DESC LIMIT 1;" 2>/dev/null)
N0=$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)
curl -s -X POST "$B/assetsReceive/add" -H "$H" -H "$J" -d "{\"assetsId\":$AID,\"borrowerName\":\"重启复核\",\"borrowerPhone\":\"13100000009\",\"returnDate\":\"2026-12-31\",\"comment\":\"E2E重启复核\"}" > /dev/null
RID=$($M -e "SELECT id FROM assets_receive WHERE comment='E2E重启复核' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" -d "{\"id\":$RID,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"未归还\"}" > /dev/null
N1=$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)
curl -s -X PUT "$B/assetsReceive/update" -H "$H" -H "$J" -d "{\"id\":$RID,\"assetsId\":$AID,\"status\":\"通过\",\"returnStatus\":\"已归还\"}" > /dev/null
N2=$($M -e "SELECT num FROM assets WHERE id=$AID;" 2>/dev/null)
echo "  库存: $N0 ->(通过) $N1 ->(归还) $N2   期望: N0-1 再回到 N0"
$M -e "DELETE FROM notify_log; DELETE FROM assets_receive WHERE comment='E2E重启复核';" 2>/dev/null
$M -e "UPDATE assets SET num=$N0 WHERE id=$AID;" 2>/dev/null

echo "=== 前端产物是否含归还方法（懒加载 chunk 里）==="
grep -l "returnBack" /www/wwwroot/yufams/js/*.js 2>/dev/null || echo "  未找到 returnBack"
ls -l /www/wwwroot/yufams/js/app.*.js
$M -e "SELECT CONCAT('  receive剩余=',COUNT(*)) FROM assets_receive; SELECT CONCAT('  asset$AID num=',num) FROM assets WHERE id=$AID;" 2>/dev/null
echo DONE
