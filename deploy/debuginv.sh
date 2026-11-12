#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "=== add task ==="
curl -s "$B/inventory/task/add" -H "token:$TOK" -H 'Content-Type: application/json' -d '{"type":"全部","departmentId":"","name":"UI流程验证任务","remark":"e2e"}'
echo
echo "=== selectPage ==="
curl -s "$B/inventory/task/selectPage?pageNum=1&pageSize=20" -H "token:$TOK" | head -c 500
