#!/bin/bash
BASE=http://YOUR_SERVER_IP:89
echo "===== viewer_ui 库内角色 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "
SELECT a.id,a.username,a.role_id,r.name,r.code FROM admin a LEFT JOIN sys_role r ON a.role_id=r.id WHERE a.username='viewer_ui';"
echo "===== viewer_ui 登录 ====="
LOGIN=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"viewer_ui","password":"123","role":"ADMIN"}')
echo "$LOGIN" | head -c 400
echo ""
TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
echo "===== viewer_ui myMenus ====="
curl -s "$BASE/role/myMenus" -H "token: $TOKEN"
echo ""
echo "===== viewer_ui 访问 /role/selectAll（不拦截，数据接口仍可调）====="
curl -s "$BASE/role/selectAll" -H "token: $TOKEN" | head -c 200
echo ""
echo DONE
