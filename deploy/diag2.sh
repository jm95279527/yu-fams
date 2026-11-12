#!/bin/bash
echo "=== root ==="
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:89/
echo "=== staff selectAll (no token, expect 401 json) ==="
curl -s http://127.0.0.1:89/staff/selectAll | head -c 300
echo
echo "=== login verbose ==="
curl -sv http://127.0.0.1:89/user/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' 2>&1 | tail -30
echo "=== check audit_log table exists ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SHOW TABLES LIKE 'audit_log';" 2>/dev/null
