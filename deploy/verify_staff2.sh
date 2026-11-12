#!/bin/bash
BASE=http://localhost:89
TOKEN=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")

echo "===== 新增测试员工 ====="
curl -s -X POST $BASE/staff/add -H "Content-Type: application/json" -H "token: $TOKEN" \
  -d '{"username":"staff_test2","password":"123","name":"测试2","departmentId":12,"position":"工程师","entryDate":"2026-01-15","status":"在职","role":"STAFF"}' >/dev/null
ID=$(curl -s "$BASE/staff/selectPage?pageNum=1&pageSize=10&username=staff_test2" -H "token: $TOKEN" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['list'][0]['id'])")
echo "id=$ID"

echo ""
echo "===== 修改（带id）：改职位+状态为离职 ====="
curl -s -X PUT $BASE/staff/update -H "Content-Type: application/json" -H "token: $TOKEN" \
  -d "{\"id\":$ID,\"username\":\"staff_test2\",\"name\":\"测试2\",\"departmentId\":12,\"position\":\"高级工程师\",\"status\":\"离职\",\"role\":\"STAFF\"}"
echo ""

echo ""
echo "===== 验证修改结果 ====="
curl -s "$BASE/staff/selectPage?pageNum=1&pageSize=10&username=staff_test2" -H "token: $TOKEN" | python3 -c "import sys,json;d=json.load(sys.stdin);s=d['data']['list'][0];print('position=',s['position'],'status=',s['status'])"

echo ""
echo "===== 状态筛选（离职，URL编码） ====="
curl -s "$BASE/staff/selectPage?pageNum=1&pageSize=10&status=%E7%A6%BB%E8%81%8C" -H "token: $TOKEN" | python3 -c "import sys,json;d=json.load(sys.stdin);print('离职 total=',d['data']['total'])"

echo ""
echo "===== 清理 ====="
curl -s -X DELETE $BASE/staff/delete/$ID -H "token: $TOKEN" >/dev/null
echo "deleted"
echo DONE
