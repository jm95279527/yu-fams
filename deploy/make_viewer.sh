#!/bin/bash
BASE=http://YOUR_SERVER_IP:89
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "DELETE FROM admin WHERE username='viewer_ui2';"
AT=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
curl -s -X POST $BASE/admin/add -H "token: $AT" -H 'Content-Type: application/json' -d '{"username":"viewer_ui2","name":"只读UI测试","password":"123","roleId":3}'
echo ""
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -N -e "SELECT id FROM admin WHERE username='viewer_ui2';"
