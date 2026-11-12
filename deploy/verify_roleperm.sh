#!/bin/bash
# 角色权限模块接口验证
BASE=http://YOUR_SERVER_IP:89

login() { # $1=username $2=password -> echo token
  curl -s -X POST $BASE/login -H 'Content-Type: application/json' \
    -d "{\"username\":\"$1\",\"password\":\"$2\",\"role\":\"ADMIN\"}" \
    | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//'
}

echo "===== 1. admin 登录（应含 roleId:1）====="
LOGIN=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}')
TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
echo "$LOGIN" | grep -o '"roleId":[0-9]*'
echo "$LOGIN" | grep -o '"roleName":"[^"]*"' || echo "(login用select *无roleName，正常)"

echo ""
echo "===== 2. 超管 myMenus（应返回全部顶级菜单）====="
curl -s "$BASE/role/myMenus" -H "token: $TOKEN" | grep -o '"name":"[^"]*"' | head -20
echo "顶级目录数:"
curl -s "$BASE/role/myMenus" -H "token: $TOKEN" | grep -o '"parentId":0' | wc -l

echo ""
echo "===== 3. 角色分页（3个内置角色+管理员数）====="
curl -s "$BASE/role/selectPage?pageNum=1&pageSize=10" -H "token: $TOKEN" | grep -o '"id":[0-9]*,"name":"[^"]*","code":"[^"]*"[^}]*"adminCount":[0-9]*'

echo ""
echo "===== 4. 资产管理员角色回显 menuIds 数量 ====="
curl -s "$BASE/role/selectById/2" -H "token: $TOKEN" | grep -o '"menuIds":\[[^]]*\]' | tr ',' '\n' | wc -l

echo ""
echo "===== 5. 菜单树 /menu/tree ====="
curl -s "$BASE/menu/tree" -H "token: $TOKEN" | grep -o '"name":"[^"]*"' | wc -l

echo ""
echo "===== 6. 新建测试角色 TEST_ROLE ====="
curl -s -X POST "$BASE/role/add" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"测试角色","code":"TEST_ROLE","description":"接口测试用","sort":99}'
echo ""
RID=$(curl -s "$BASE/role/selectAll" -H "token: $TOKEN" | tr '}' '\n' | grep 'TEST_ROLE' | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
echo "测试角色ID=$RID"

echo ""
echo "===== 7. 给测试角色分配菜单：驾驶舱+台账+公告（1,10,11,50,51）====="
curl -s -X POST "$BASE/role/assignMenus" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"roleId\":$RID,\"menuIds\":[1,10,11,50,51]}"
echo ""
curl -s "$BASE/role/selectById/$RID" -H "token: $TOKEN" | grep -o '"menuIds":\[[^]]*\]'

echo ""
echo "===== 8. 新建测试管理员 viewer01 绑定测试角色 ====="
curl -s -X POST "$BASE/admin/add" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"username\":\"viewer01\",\"name\":\"测试只读员\",\"password\":\"123\",\"roleId\":$RID}"
echo ""
AID=$(mysql -uroot -pYOUR_DB_PASSWORD xm-assets -se "SELECT id FROM admin WHERE username='viewer01';" 2>/dev/null)
echo "viewer01 admin id=$AID"

echo ""
echo "===== 9. viewer01 登录 + myMenus（只能见 驾驶舱/台账/公告）====="
VTOKEN=$(login viewer01 123)
echo "viewer token 获取: ${VTOKEN:0:20}..."
echo "可见菜单名称:"
curl -s "$BASE/role/myMenus" -H "token: $VTOKEN" | grep -o '"name":"[^"]*"'
echo "可见路由path:"
curl -s "$BASE/role/myMenus" -H "token: $VTOKEN" | grep -o '"path":"[^"]*"'

echo ""
echo "===== 10. viewer01 越权操作角色（应403）====="
curl -s -X POST "$BASE/role/add" -H "token: $VTOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"hack","code":"HACK"}'
echo ""
curl -s -X DELETE "$BASE/role/delete/1" -H "token: $VTOKEN"
echo ""
curl -s -X POST "$BASE/admin/add" -H "token: $VTOKEN" -H 'Content-Type: application/json' \
  -d '{"username":"hack01","roleId":1}'
echo " （roleId应被后端剥离）"

echo ""
echo "===== 11. 超管保护：删超管角色/给超管分配权限 均应拒绝 ====="
curl -s -X DELETE "$BASE/role/delete/1" -H "token: $TOKEN"
echo ""
curl -s -X POST "$BASE/role/assignMenus" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"roleId":1,"menuIds":[1]}'
echo ""

echo ""
echo "===== 12. 非法角色标识应拒绝 ====="
curl -s -X POST "$BASE/role/add" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"bad","code":"bad-code"}'
echo ""

echo ""
echo "===== 清理 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "DELETE FROM admin WHERE username='viewer01'; DELETE FROM sys_role_menu WHERE role_id=$RID; DELETE FROM sys_role WHERE id=$RID;" 2>&1 | grep -v Warning
echo "剩余角色:"
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -se "SELECT id,name,code FROM sys_role;" 2>/dev/null
echo "剩余测试管理员:"
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -se "SELECT id,username,role_id FROM admin;" 2>/dev/null
echo "DONE"
