#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
B=http://127.0.0.1:89
echo "=== 1) department 表 ==="
$M -e "select concat(id,' | ',ifnull(name,'-'),' | level=',ifnull(level,'NULL'),' | pid=',ifnull(pid,'NULL'),' | company_id=',ifnull(company_id,'NULL')) from department order by id"
echo ""
echo "=== 2) 关键接口自查 ==="
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
for u in /department/selectAll /department/selectTree /department/selectParent /company/selectAll /assets/selectPage /assets/selectAll; do
  echo "--- $u ---"
  curl -s "$B$u?pageNum=1&pageSize=5" -H "token: $TOK" | head -c 600
  echo ""
done
echo ""
echo "=== 3) 最近异常日志（department/company/assets）==="
journalctl -u yufams --since -40min 2>/dev/null | grep -E 'Exception|ERROR|Caused by' | tail -25
echo ""
echo "=== 4) 最近 25 条审计 ==="
$M -e "select concat(id,' | ',create_time,' | ',username,' | ',method,' | ',uri,' | ',result_code) from audit_log order by id desc limit 25" 2>/dev/null
echo ""
echo "=== 5) 近期 500 的接口 ==="
$M -e "select concat(create_time,' | ',method,' | ',uri,' | ',result_code,' | ',ifnull(params,'')) from audit_log where result_code='500' order by id desc limit 15" 2>/dev/null
echo DBG5_DONE
