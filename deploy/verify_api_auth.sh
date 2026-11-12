#!/bin/bash
BASE=http://YOUR_SERVER_IP:89
PASS=0; FAIL=0
chk(){ # desc expected_code actual
  if [ "$2" = "$3" ]; then echo "PASS  $1 -> $3"; PASS=$((PASS+1)); else echo "FAIL  $1 -> 期望$2 实际$3"; FAIL=$((FAIL+1)); fi
}

echo "===== 1. 超管登录 ====="
A=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}')
AT=$(echo "$A" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
[ -n "$AT" ] && echo "超管 token OK" || { echo "超管登录失败"; exit 1; }

echo "===== 2. 清理可能残留的 viewer 测试账号 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "DELETE FROM admin WHERE username='viewer_api';"

echo "===== 3. 超管创建只读测试账号 viewer_api（绑定 VIEWER 角色 id=3）====="
ADD=$(curl -s -X POST $BASE/admin/add -H "token: $AT" -H 'Content-Type: application/json' -d '{"username":"viewer_api","name":"接口鉴权测试","password":"123","roleId":3}')
echo "$ADD"
VID=$(mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -N -e "SELECT id FROM admin WHERE username='viewer_api';")
echo "viewer_api id=$VID"

echo "===== 4. viewer_api 登录 ====="
V=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"viewer_api","password":"123","role":"ADMIN"}')
VT=$(echo "$V" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
[ -n "$VT" ] && echo "viewer token OK" || { echo "viewer 登录失败"; exit 1; }

echo "===== 5. 超管：各业务接口应全部 200 ====="
chk "超管 /assets/selectAll"        "200" "$(curl -s -o /dev/null -w '' $BASE/assets/selectAll -H "token: $AT"; echo ${PIPESTATUS[0]})"
# 用 code 字段判断更准
C=$(curl -s $BASE/assets/selectAll -H "token: $AT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "超管 /assets/selectAll code=200" "200" "$C"
C=$(curl -s $BASE/assetsScrap/selectPage -H "token: $AT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "超管 /assetsScrap/selectPage code=200" "200" "$C"
C=$(curl -s $BASE/role/selectAll -H "token: $AT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "超管 /role/selectAll code=200" "200" "$C"
C=$(curl -s $BASE/dashboard/stats -H "token: $AT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "超管 /dashboard/stats code=200" "200" "$C"

echo "===== 6. viewer（只读）：授权接口放行 ====="
C=$(curl -s $BASE/dashboard/stats -H "token: $VT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer /dashboard/stats(通用放行) code=200" "200" "$C"
C=$(curl -s $BASE/role/myMenus -H "token: $VT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer /role/myMenus(通用放行) code=200" "200" "$C"
C=$(curl -s $BASE/notice/selectAll -H "token: $VT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer /notice/selectAll(授权菜单) code=200" "200" "$C"
C=$(curl -s $BASE/assets/selectAll -H "token: $VT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer /assets/selectAll(授权台账) code=200" "200" "$C"

echo "===== 7. viewer：未授权接口应 403 ====="
C=$(curl -s $BASE/assetsScrap/selectPage -H "token: $VT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer /assetsScrap/selectPage(无报废菜单) code=403" "403" "$C"
C=$(curl -s $BASE/assetsIn/selectPage -H "token: $VT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer /assetsIn/selectPage(无入库菜单) code=403" "403" "$C"
C=$(curl -s $BASE/category/selectAll -H "token: $VT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer /category/selectAll(无分类菜单) code=403" "403" "$C"
C=$(curl -s $BASE/role/selectAll -H "token: $VT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer /role/selectAll(无角色菜单) code=403" "403" "$C"
C=$(curl -s $BASE/admin/selectPage -H "token: $VT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer /admin/selectPage(无管理员菜单) code=403" "403" "$C"
C=$(curl -s $BASE/staff/selectAll -H "token: $VT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer /staff/selectAll(无员工菜单) code=403" "403" "$C"

echo "===== 8. 个人信息归属校验 ====="
C=$(curl -s $BASE/admin/selectById/$VID -H "token: $VT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer 查询本人 selectById/$VID code=200" "200" "$C"
C=$(curl -s $BASE/admin/selectById/4 -H "token: $VT" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer 查询他人 selectById/4 code=403" "403" "$C"
C=$(curl -s -X PUT $BASE/admin/update -H "token: $VT" -H 'Content-Type: application/json' -d "{\"id\":4,\"name\":\"越权修改\"}" | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "viewer 修改他人 update id=4 code=403" "403" "$C"

echo "===== 9. 未携带 token 应 401 ====="
C=$(curl -s $BASE/assets/selectAll | grep -o '"code":"[^"]*"' | head -1 | sed 's/"code":"//;s/"//'); chk "无token /assets/selectAll code=401" "401" "$C"

echo "===== 10. 清理 ====="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets 2>/dev/null -e "DELETE FROM admin WHERE username='viewer_api';"
echo "viewer_api 已删除"

echo ""
echo "=============================="
echo "PASS=$PASS  FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && echo "ALL PASS" || echo "HAS FAILURES"
