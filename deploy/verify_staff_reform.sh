#!/bin/bash
BASE=http://localhost:89
q(){ mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "$1" 2>/dev/null; }
PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# 预清理上次失败运行的残留
q "DELETE FROM staff WHERE username IN ('rf_test','rf_dup');"

TOKEN=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")

echo "===== 1. 新增完整档案员工（密码123456，工号 E001，试图提权 ADMIN） ====="
R=$(curl -s -X POST $BASE/staff/add -H "Content-Type: application/json" -H "token: $TOKEN" \
  -d '{"username":"rf_test","password":"123456","empNo":"E001","name":"改造测试","gender":"男","phone":"13700137000","email":"rf@t.com","idCard":"110101199001011234","birthDate":"1990-01-01","education":"本科","nativePlace":"北京","address":"海淀区","emergencyContact":"张三","emergencyPhone":"13800000000","departmentId":12,"position":"工程师","entryDate":"2026-02-01","status":"在职","remark":"测试备注","role":"ADMIN"}')
echo "$R" | grep -q '"code":"200"' && ok "新增成功" || bad "新增失败: $R"

ID=$(q "SELECT id FROM staff WHERE username='rf_test';")
echo "staff id=$ID"

echo "===== 2. 库内密码为 MD5，角色固定 STAFF ====="
PWDDB=$(q "SELECT password FROM staff WHERE id=$ID;")
ROLEDB=$(q "SELECT role FROM staff WHERE id=$ID;")
echo "stored pwd=$PWDDB role=$ROLEDB"
[ ${#PWDDB} -eq 32 ] && ok "密码已 MD5" || bad "密码未加密: $PWDDB"
[ "$ROLEDB" = "STAFF" ] && ok "角色固定 STAFF" || bad "角色被提权: $ROLEDB"

echo "===== 3. 列表接口不返回密码，且新字段齐全 ====="
curl -s "$BASE/staff/selectPage?pageNum=1&pageSize=10&empNo=E001" -H "token: $TOKEN" > /tmp/rf_list.json
python3 - <<'PY'
import json
d=json.load(open('/tmp/rf_list.json'))
s=d['data']['list'][0]
assert s.get('password') is None, 'password leaked: %s' % s.get('password')
for f in ['empNo','gender','idCard','education','nativePlace','emergencyContact','departmentName','leaveDate','remark']:
    assert f in s, 'missing field %s' % f
assert s['empNo']=='E001' and s['departmentName']=='hena' and s['idCard']=='110101199001011234'
print('fields ok')
PY
[ $? -eq 0 ] && ok "列表无密码泄漏+字段齐全" || bad "列表返回异常"

echo "===== 4. 工号重复拒绝 ====="
R=$(curl -s -X POST $BASE/staff/add -H "Content-Type: application/json" -H "token: $TOKEN" \
  -d '{"username":"rf_dup","empNo":"E001","name":"重复"}')
echo "$R" | grep -q '工号已存在' && ok "工号重复被拦截" || bad "工号重复未拦截: $R"

echo "===== 5. 员工用正确密码登录 ====="
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"rf_test","password":"123456","role":"STAFF"}')
echo "$R" | grep -q '"code":"200"' && ok "正确密码登录成功" || bad "登录失败: $R"
STAFF_TOKEN=$(echo "$R" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")

echo "===== 6. 错误密码登录拒绝 ====="
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"rf_test","password":"wrong","role":"STAFF"}')
echo "$R" | grep -q '"code":"200"' && bad "错误密码竟然登录成功" || { ok "错误密码被拒"; }

echo "===== 7. 改为离职：自动写离职日期，登录被拒，旧 token 401 ====="
curl -s -X PUT $BASE/staff/update -H "Content-Type: application/json" -H "token: $TOKEN" \
  -d "{\"id\":$ID,\"status\":\"离职\"}" >/dev/null
LEAVE=$(q "SELECT leave_date FROM staff WHERE id=$ID;")
echo "leave_date=$LEAVE"
[ -n "$LEAVE" ] && ok "离职日期自动填充" || bad "离职日期未填充"
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"rf_test","password":"123456","role":"STAFF"}')
echo "$R" | grep -q '已离职停用' && ok "离职后登录被拒" || bad "离职登录未拦截: $R"
R=$(curl -s "$BASE/staff/selectPage?pageNum=1&pageSize=5" -H "token: $STAFF_TOKEN")
echo "$R" | grep -q '"code":"401"' && ok "旧 token 立即失效(401)" || bad "旧 token 未拦截: $R"

echo "===== 8. 恢复在职：离职日期清空，可登录 ====="
curl -s -X PUT $BASE/staff/update -H "Content-Type: application/json" -H "token: $TOKEN" \
  -d "{\"id\":$ID,\"status\":\"在职\"}" >/dev/null
LEAVE=$(q "SELECT leave_date FROM staff WHERE id=$ID;")
[ -z "$LEAVE" -o "$LEAVE" = "NULL" ] && ok "恢复在职后离职日期清空" || bad "离职日期未清空: $LEAVE"
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"rf_test","password":"123456","role":"STAFF"}')
echo "$R" | grep -q '"code":"200"' && ok "恢复在职后可登录" || bad "恢复在职登录失败: $R"

echo "===== 9. 重置密码为默认 123 ====="
curl -s -X PUT $BASE/staff/resetPassword/$ID -H "token: $TOKEN" >/dev/null
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"rf_test","password":"123","role":"STAFF"}')
echo "$R" | grep -q '"code":"200"' && ok "重置密码后可用 123 登录" || bad "重置密码失败: $R"

echo "===== 10. 有关联记录时禁止删除（伪造一条 assets_in 关联） ====="
q "INSERT INTO assets_in (staff_id) VALUES ($ID);"
R=$(curl -s -X DELETE $BASE/staff/delete/$ID -H "token: $TOKEN")
echo "$R" | grep -q '关联记录' && ok "关联员工删除被拦截" || bad "删除拦截失败: $R"
q "DELETE FROM assets_in WHERE staff_id=$ID ORDER BY id DESC LIMIT 1;"

echo "===== 11. 筛选：手机号模糊 + 状态 ====="
T1=$(curl -s "$BASE/staff/selectPage?pageNum=1&pageSize=10&phone=13700137" -H "token: $TOKEN" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['total'])")
T2=$(curl -s "$BASE/staff/selectPage?pageNum=1&pageSize=10&status=%E5%9C%A8%E8%81%8C" -H "token: $TOKEN" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['total'])")
echo "phone result=$T1, 在職 result=$T2"
[ "$T1" = "1" ] && ok "手机号模糊筛选" || bad "手机号筛选异常: $T1"
[ "$T2" -ge "1" ] && ok "状态筛选" || bad "状态筛选异常: $T2"

echo "===== 12. 导出 xlsx ====="
curl -s -o /tmp/staff_export.xlsx "$BASE/staff/export" -H "token: $TOKEN"
MAGIC=$(head -c 2 /tmp/staff_export.xlsx)
[ "$MAGIC" = "PK" ] && ok "导出为 xlsx（zip 头正确，$(stat -c%s /tmp/staff_export.xlsx) 字节）" || bad "导出文件异常: $MAGIC"

echo "===== 13. 清理 ====="
curl -s -X DELETE $BASE/staff/delete/$ID -H "token: $TOKEN" >/dev/null
LEFT=$(q "SELECT COUNT(*) FROM staff WHERE username IN ('rf_test','rf_dup');")
[ "$LEFT" = "0" ] && ok "测试数据已清理" || bad "清理失败，剩余 $LEFT 条"

echo ""
echo "===== RESULT: PASS=$PASS FAIL=$FAIL ====="
echo DONE
