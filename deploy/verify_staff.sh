#!/bin/bash
BASE=http://localhost:89
echo "===== 1. 登录获取 token ====="
TOKEN=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "token=${TOKEN:0:20}..."

echo ""
echo "===== 2. 新增员工（带部门/职位/入职日期/状态） ====="
curl -s -X POST $BASE/staff/add -H "Content-Type: application/json" -H "token: $TOKEN" \
  -d '{"username":"staff_test","password":"123","name":"测试员工","phone":"13800138000","email":"t@t.com","departmentId":12,"position":"工程师","entryDate":"2026-01-15","status":"在职","role":"STAFF"}'
echo ""

echo ""
echo "===== 3. 分页查询（验证 departmentName/position/entryDate/status） ====="
curl -s "$BASE/staff/selectPage?pageNum=1&pageSize=10" -H "token: $TOKEN" | python3 -m json.tool

echo ""
echo "===== 4. 按部门筛选 ====="
curl -s "$BASE/staff/selectPage?pageNum=1&pageSize=10&departmentId=12" -H "token: $TOKEN" | python3 -c "import sys,json;d=json.load(sys.stdin);print('total=',d['data']['total']);[print(s['username'],s.get('departmentName'),s.get('position'),s.get('status')) for s in d['data']['list']]"

echo ""
echo "===== 5. 按状态筛选（离职） ====="
curl -s "$BASE/staff/selectPage?pageNum=1&pageSize=10&status=离职" -H "token: $TOKEN" | python3 -c "import sys,json;d=json.load(sys.stdin);print('离职 total=',d['data']['total'])"

echo ""
echo "===== 6. 修改员工（改职位和状态为离职） ====="
curl -s -X PUT $BASE/staff/update -H "Content-Type: application/json" -H "token: $TOKEN" \
  -d "{\"username\":\"staff_test\",\"name\":\"测试员工\",\"departmentId\":12,\"position\":\"高级工程师\",\"status\":\"离职\",\"role\":\"STAFF\"}"
echo ""

echo ""
echo "===== 7. 验证修改后状态 ====="
curl -s "$BASE/staff/selectPage?pageNum=1&pageSize=10&username=staff_test" -H "token: $TOKEN" | python3 -c "import sys,json;d=json.load(sys.stdin);[print(s['username'],s.get('position'),s.get('status')) for s in d['data']['list']]"

echo ""
echo "===== 8. 清理测试数据 ====="
ID=$(curl -s "$BASE/staff/selectPage?pageNum=1&pageSize=10&username=staff_test" -H "token: $TOKEN" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['data']['list'][0]['id'])")
curl -s -X DELETE $BASE/staff/delete/$ID -H "token: $TOKEN"
echo ""
echo "deleted id=$ID"
echo DONE
