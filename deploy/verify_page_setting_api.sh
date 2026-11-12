#!/bin/bash
# 「页面设置」验证 第一步：接口 + 上传壁纸/Logo + 写入测试配置
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOKLEN=${#TOK}"

echo ""
echo "=== 1) 菜单是否已挂到「系统管理」下 ==="
curl -s "$B/role/myMenus" -H "token: $TOK" | python3 -c '
import sys, json
for m in json.load(sys.stdin)["data"]:
    if m.get("name") == "系统管理":
        print("  系统管理 ->", [(c["id"], c["name"], c["path"]) for c in (m.get("children") or [])])'

echo ""
echo "=== 2) 造两张测试图片并上传（测图片链路）==="
python3 - <<'PY'
import zlib, struct
def png(w, h, rgb):
    raw = b''.join(b'\x00' + bytes(rgb) * w for _ in range(h))
    def chunk(t, d):
        c = t + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    ihdr = struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr)
            + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))
open('/tmp/testbg.png', 'wb').write(png(80, 45, (28, 84, 150)))
open('/tmp/testlogo.png', 'wb').write(png(40, 40, (198, 62, 62)))
print("  PNG 已生成：", __import__('os').path.getsize('/tmp/testbg.png'), __import__('os').path.getsize('/tmp/testlogo.png'))
PY
BG=$(curl -s -X POST $B/files/upload -H "token: $TOK" -F "file=@/tmp/testbg.png" | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"])')
LG=$(curl -s -X POST $B/files/upload -H "token: $TOK" -F "file=@/tmp/testlogo.png" | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"])')
echo "  壁纸URL=$BG"
echo "  LogoURL=$LG"
echo "  壁纸可访问: $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:89$BG)"
echo "  Logo可访问: $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:89$LG)"

echo ""
echo "=== 3) 读取配置（页面设置页用）==="
curl -s "$B/sysConfig/selectAll" -H "token: $TOK" | python3 -c '
import sys,json
for x in json.load(sys.stdin)["data"]:
    print("  %-20s = %-30s # %s" % (x["configKey"], x["configValue"], x.get("remark")))'

echo ""
echo "=== 4) 保存测试配置 ==="
cat > /tmp/cfg.json <<JSON
[
  {"configKey":"system_name","configValue":"赫玛资产管理系统"},
  {"configKey":"browser_title","configValue":"赫玛资产-页面设置验证"},
  {"configKey":"login_subtitle","configValue":"欢迎来到赫玛科技"},
  {"configKey":"login_bg","configValue":"$BG"},
  {"configKey":"logo","configValue":"$LG"},
  {"configKey":"footer_text","configValue":"© 2026 赫玛科技 版权所有"},
  {"configKey":"dashboard_welcome","configValue":"欢迎使用赫玛资产管理系统"}
]
JSON
cat /tmp/cfg.json
curl -s -X PUT $B/sysConfig/save -H "token: $TOK" -H 'Content-Type: application/json' -d @/tmp/cfg.json; echo

echo ""
echo "=== 5) 公开接口是否返回新值（免登录）==="
curl -s "$B/sysConfig/public" | python3 -m json.tool --no-ensure-ascii

echo ""
echo "=== 6) 非法配置键应被拒绝 ==="
curl -s -X PUT $B/sysConfig/save -H "token: $TOK" -H 'Content-Type: application/json' \
  -d '[{"configKey":"hack_key","configValue":"x"}]'; echo

echo ""
echo "=== 7) 库中最终值 ==="
$M -e "select concat('  ',config_key,' = ',ifnull(config_value,'(空)'),'  @',ifnull(update_time,'-')) from sys_config order by id"
echo PREP_DONE
