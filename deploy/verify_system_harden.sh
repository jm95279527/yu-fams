#!/bin/bash
BASE=http://localhost:89
export MYSQL_PWD=YOUR_DB_PASSWORD
q(){ mysql -uroot xm-assets -N -e "$1" 2>/dev/null; }
PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL: $1 | $2"; FAIL=$((FAIL+1)); }
expect(){ echo "$3" | grep -q "$2" && ok "$1" || bad "$1" "$3"; }

TOKEN=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")

echo "===== 0. audit_log 表与菜单 api ====="
[ "$(q "SHOW TABLES LIKE 'audit_log'")" = "audit_log" ] && ok "audit_log 表存在" || bad "audit_log 表不存在" ""
[ "$(q "SELECT api FROM sys_menu WHERE id=52")" = "/auditLog" ] && ok "菜单52 api 已修正" || bad "菜单52 api 错误" "$(q "SELECT api FROM sys_menu WHERE id=52")"

echo "===== 1. 创建测试账号（防爆破用） ====="
R=$(curl -s -X POST $BASE/staff/add -H "Content-Type: application/json" -H "token: $TOKEN" -d '{"username":"guard_t","name":"防爆破测试","password":"ab12cd34","status":"在职"}')
expect "测试账号创建" '"code":"200"' "$R"

echo "===== 2. 连续 5 次错误密码（第5次仍未锁定） ====="
for i in 1 2 3 4 5; do
  R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"guard_t","password":"wrongpw","role":"STAFF"}')
  if echo "$R" | grep -q "锁定"; then bad "第${i}次不应锁定" "$R"; fi
done
echo "$R" | grep -q "账号或密码错误" && ok "第5次仍为密码错误提示" || bad "第5次提示异常" "$R"

echo "===== 3. 第 6 次触发锁定 ====="
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"guard_t","password":"wrongpw","role":"STAFF"}')
expect "第6次触发锁定" "锁定" "$R"
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"guard_t","password":"ab12cd34","role":"STAFF"}')
expect "锁定期内正确密码也被拒" "锁定" "$R"

echo "===== 4. 重启清空内存锁（验证内存实现） ====="
bash /tmp/restart_backend.sh >/dev/null 2>&1
sleep 15
R=$(curl -s -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"guard_t","password":"ab12cd34","role":"STAFF"}')
expect "重启后正确密码可登录" '"code":"200"' "$R"

echo "===== 5. 审计日志：登录成功/失败均入库 ====="
N_FAIL=$(q "SELECT COUNT(*) FROM audit_log WHERE uri='/login' AND result_code='5003' AND params LIKE '%guard_t%'")
[ "$N_FAIL" -ge 5 ] && ok "5次失败登录已入审计 ($N_FAIL)" || bad "失败登录审计缺失" "$N_FAIL"
N_OK=$(q "SELECT COUNT(*) FROM audit_log WHERE uri='/login' AND result_code='200' AND params LIKE '%guard_t%'")
[ "$N_OK" -ge 1 ] && ok "成功登录已入审计" || bad "成功登录审计缺失" "$N_OK"
R=$(q "SELECT params FROM audit_log WHERE uri='/login' AND params LIKE '%guard_t%' ORDER BY id DESC LIMIT 1")
echo "$R" | grep -q '"password":"\*\*\*"' && ok "登录参数密码已脱敏" || bad "密码未脱敏" "$R"
echo "$R" | grep -q "ab12cd34" && bad "明文密码泄漏进日志" "$R" || ok "无明文密码"

echo "===== 6. 审计日志：写操作入库 ====="
N_ADD=$(q "SELECT COUNT(*) FROM audit_log WHERE uri='/staff/add' AND username='admin' AND result_code='200'")
[ "$N_ADD" -ge 1 ] && ok "新增员工操作已入审计" || bad "新增审计缺失" "$N_ADD"
GID=$(q "SELECT id FROM staff WHERE username='guard_t'")
curl -s -X DELETE $BASE/staff/delete/$GID -H "token: $TOKEN" >/dev/null
N_DEL=$(q "SELECT COUNT(*) FROM audit_log WHERE uri='/staff/delete/$GID' AND username='admin'")
[ "$N_DEL" -ge 1 ] && ok "删除操作已入审计(含资源ID)" || bad "删除审计缺失" "$N_DEL"
R=$(q "SELECT COUNT(*) FROM staff WHERE username='guard_t'")
[ "$R" = "0" ] && ok "测试账号已删除" || bad "测试账号残留" "$R"

echo "===== 7. /auditLog/selectPage 与筛选 ====="
R=$(curl -s "$BASE/auditLog/selectPage?pageNum=1&pageSize=5" -H "token: $TOKEN")
expect "分页查询 200" '"code":"200"' "$R"
R=$(curl -s "$BASE/auditLog/selectPage?pageNum=1&pageSize=5&method=DELETE" -H "token: $TOKEN")
echo "$R" | grep -q '"method":"DELETE"' && ok "method 筛选生效" || bad "method 筛选无结果" "$(echo $R | head -c 120)"

echo "===== 8. 清理接口 ====="
R=$(curl -s -X DELETE $BASE/auditLog/clean/365 -H "token: $TOKEN")
expect "clean 接口 200" '"code":"200"' "$R"

echo "===== 9. 数据库备份与恢复演练 ====="
bash /opt/yu-fams/backup_mysql.sh
F=$(ls -t /opt/yu-fams/backup/xm-assets_*.sql.gz | head -1)
[ -s "$F" ] && gunzip -t "$F" && ok "备份文件完整 ($F $(stat -c%s $F)bytes)" || bad "备份文件异常" "$F"
mysql -uroot -e "DROP DATABASE IF EXISTS xm_restore_test; CREATE DATABASE xm_restore_test" 2>/dev/null
gunzip < "$F" | mysql -uroot xm_restore_test 2>/dev/null
NT=$(mysql -uroot xm_restore_test -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='xm_restore_test'" 2>/dev/null)
mysql -uroot -e "DROP DATABASE xm_restore_test" 2>/dev/null
[ "$NT" -ge 25 ] && ok "恢复演练通过（$NT 张表）" || bad "恢复表数异常" "$NT"
CRON=$(crontab -l | grep -c backup_mysql.sh)
[ "$CRON" -ge 1 ] && ok "cron 已安装" || bad "cron 未安装" ""

echo ""
echo "===== RESULT: PASS=$PASS FAIL=$FAIL ====="
echo DONE
