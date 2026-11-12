#!/bin/bash
BASE=http://localhost:89
export MYSQL_PWD=YOUR_DB_PASSWORD
q(){ mysql -uroot xm-assets -N -e "$1" 2>/dev/null; }
PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL: $1 | $2"; FAIL=$((FAIL+1)); }
expect(){ # desc pattern actual
  echo "$3" | grep -q "$2" && ok "$1" || bad "$1" "$3"
}

TOKEN=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")

echo "===== 1. 坏手机号拦截 ====="
R=$(curl -s -X POST $BASE/staff/add -H "Content-Type: application/json" -H "token: $TOKEN" -d '{"username":"se_t1","name":"校验1","phone":"12345abc"}')
expect "坏手机号被拦截" "手机号格式不正确" "$R"

echo "===== 2. 坏身份证拦截 ====="
R=$(curl -s -X POST $BASE/staff/add -H "Content-Type: application/json" -H "token: $TOKEN" -d '{"username":"se_t2","name":"校验2","idCard":"12345"}')
expect "坏身份证被拦截" "身份证号格式不正确" "$R"

echo "===== 3. 坏紧急电话拦截 ====="
R=$(curl -s -X POST $BASE/staff/add -H "Content-Type: application/json" -H "token: $TOKEN" -d '{"username":"se_t3","name":"校验3","emergencyPhone":"12306"}')
expect "坏紧急电话被拦截" "紧急联系电话格式不正确" "$R"

echo "===== 4. 弱密码（纯字母）拦截 ====="
R=$(curl -s -X POST $BASE/staff/add -H "Content-Type: application/json" -H "token: $TOKEN" -d '{"username":"se_t4","name":"校验4","password":"abcdefgh"}')
expect "纯字母弱密码被拦截" "密码强度不足" "$R"

echo "===== 5. 弱密码（纯数字）拦截 ====="
R=$(curl -s -X POST $BASE/staff/add -H "Content-Type: application/json" -H "token: $TOKEN" -d '{"username":"se_t5","name":"校验5","password":"123450"}')
expect "纯数字弱密码被拦截" "密码强度不足" "$R"

echo "===== 6. 合法档案+强密码新增 ====="
R=$(curl -s -X POST $BASE/staff/add -H "Content-Type: application/json" -H "token: $TOKEN" \
  -d '{"username":"se_ok","name":"校验通过","password":"ab12cd34","phone":"13700137000","idCard":"320100199505056789","emergencyPhone":"13933334444","empNo":"SE01","status":"在职"}')
expect "合法新增成功" '"code":"200"' "$R"
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"se_ok","password":"ab12cd34","role":"STAFF"}')
expect "强密码可登录" '"code":"200"' "$R"
MD5DB=$(q "SELECT password FROM staff WHERE username='se_ok'")
[ ${#MD5DB} -eq 32 ] && ok "库内为 MD5" || bad "库内非 MD5" "$MD5DB"
STOKEN=$(echo "$R" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")

echo "===== 7. 留空密码=默认123 ====="
R=$(curl -s -X POST $BASE/staff/add -H "Content-Type: application/json" -H "token: $TOKEN" -d '{"username":"se_def","name":"默认密码"}')
expect "留空密码新增成功" '"code":"200"' "$R"
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"se_def","password":"123","role":"STAFF"}')
expect "默认123可登录" '"code":"200"' "$R"

echo "===== 8. 编辑传弱密码拦截且原密码不受影响 ====="
ID=$(q "SELECT id FROM staff WHERE username='se_ok'")
R=$(curl -s -X PUT $BASE/staff/update -H "Content-Type: application/json" -H "token: $TOKEN" -d "{\"id\":$ID,\"password\":\"111\"}")
expect "编辑弱密码被拦截" "密码强度不足" "$R"
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"se_ok","password":"ab12cd34","role":"STAFF"}')
expect "原密码仍可登录" '"code":"200"' "$R"

echo "===== 9. 员工自助改密：弱新密码拦截，强新密码成功 ====="
R=$(curl -s -X PUT $BASE/updatePassword -H "Content-Type: application/json" -H "token: $STOKEN" -d '{"username":"se_ok","role":"STAFF","password":"ab12cd34","newPassword":"999"}')
expect "自助改密弱密码被拦截" "密码强度不足" "$R"
R=$(curl -s -X PUT $BASE/updatePassword -H "Content-Type: application/json" -H "token: $STOKEN" -d '{"username":"se_ok","role":"STAFF","password":"ab12cd34","newPassword":"xy75most"}')
expect "自助改密强密码成功" '"code":"200"' "$R"
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"se_ok","password":"xy75most","role":"STAFF"}')
expect "新密码可登录" '"code":"200"' "$R"

echo "===== 10. 重置密码豁免强度策略（回到123） ====="
curl -s -X PUT $BASE/staff/resetPassword/$ID -H "token: $TOKEN" >/dev/null
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"se_ok","password":"123","role":"STAFF"}')
expect "重置后123可登录" '"code":"200"' "$R"

echo "===== 11. 导出列检查（仅别名19列，含出生日期） ====="
curl -s -o /tmp/se_export.xlsx "$BASE/staff/export" -H "token: $TOKEN"
MAGIC=$(head -c 2 /tmp/se_export.xlsx)
[ "$MAGIC" = "PK" ] && ok "导出为 xlsx ($(stat -c%s /tmp/se_export.xlsx) 字节)" || bad "导出异常" "$MAGIC"
COLS=$(unzip -p /tmp/se_export.xlsx xl/sharedStrings.xml 2>/dev/null | grep -o '出生日期\|工号\|离职日期' | sort -u | tr '\n' ',')
echo "$COLS" | grep -q '出生日期' && ok "含出生日期列" || bad "缺出生日期列" "$COLS"
unzip -p /tmp/se_export.xlsx xl/sharedStrings.xml 2>/dev/null | grep -q 'role\|wxUserid' && bad "导出泄漏内部字段" "role/wxUserid" || ok "无内部字段泄漏"

echo "===== 12. 清理 ====="
curl -s -X DELETE $BASE/staff/delete/$ID -H "token: $TOKEN" >/dev/null
ID2=$(q "SELECT id FROM staff WHERE username='se_def'")
[ -n "$ID2" ] && curl -s -X DELETE $BASE/staff/delete/$ID2 -H "token: $TOKEN" >/dev/null
LEFT=$(q "SELECT COUNT(*) FROM staff WHERE username LIKE 'se_%'")
[ "$LEFT" = "0" ] && ok "测试数据已清理" || bad "清理失败，剩余 $LEFT" ""

echo ""
echo "===== RESULT: PASS=$PASS FAIL=$FAIL ====="
echo DONE
