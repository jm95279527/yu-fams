#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "--- 库中配置 ---"
$M -e "select concat('  scan_fields = [',ifnull(config_value,''),']') from sys_config where config_key='scan_fields'"
echo "--- 公开接口 ---"
curl -s http://127.0.0.1:89/sysConfig/public | python3 -c '
import sys, json
d = json.load(sys.stdin)["data"]
f = d["scanFields"]
print("  scanFields =", f)
print("  共 %d 项，含数量 num=%s，含折旧方法 depreciate=%s" % (len(f), "num" in f, "depreciate" in f))'
echo CONFIRM_DONE
