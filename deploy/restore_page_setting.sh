#!/bin/bash
# 恢复默认配置 + 清理验证用的临时图片
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')

echo "=== 1) 恢复为内置默认值（壁纸/Logo/页脚留空）==="
cat > /tmp/cfg_reset.json <<'JSON'
[
  {"configKey":"system_name","configValue":"固定资产管理系统"},
  {"configKey":"browser_title","configValue":"固定资产管理系统"},
  {"configKey":"login_subtitle","configValue":"欢迎使用"},
  {"configKey":"login_bg","configValue":""},
  {"configKey":"logo","configValue":""},
  {"configKey":"footer_text","configValue":""},
  {"configKey":"dashboard_welcome","configValue":"欢迎使用固定资产管理系统"}
]
JSON
curl -s -X PUT $B/sysConfig/save -H "token: $TOK" -H 'Content-Type: application/json' -d @/tmp/cfg_reset.json; echo
echo "  -- 恢复后的公开配置 --"
curl -s "$B/sysConfig/public" | python3 -m json.tool --no-ensure-ascii

echo ""
echo "=== 2) 清理验证用的临时图片 ==="
find /opt/yu-fams -name '*testbg.png' -o -name '*testlogo.png' 2>/dev/null
for f in $(find /opt/yu-fams -name '*testbg.png' -o -name '*testlogo.png' 2>/dev/null); do rm -f "$f"; done
echo "  剩余：$(find /opt/yu-fams -name '*testbg.png' -o -name '*testlogo.png' 2>/dev/null | wc -l)"

echo ""
echo "=== 3) 库中最终值 ==="
$M -e "select concat('  ',config_key,' = [',ifnull(config_value,''),']') from sys_config order by id"
echo RESTORE_DONE
