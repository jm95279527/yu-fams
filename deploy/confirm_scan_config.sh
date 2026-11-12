#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "--- 库中扫码相关配置（应全部为默认值）---"
$M -e "select concat('  ',config_key,' = [',ifnull(config_value,''),']') from sys_config where config_key like 'scan_%' order by id"
echo "--- 公开接口 ---"
curl -s http://127.0.0.1:89/sysConfig/public | python3 -c '
import sys, json
d = json.load(sys.stdin)["data"]
print("  scanTitle      =", d["scanTitle"])
print("  scanFooter     =", d["scanFooter"])
print("  scanBorrowText =", d["scanBorrowText"])
print("  scanRepairText =", d["scanRepairText"])
f = d["scanFields"]
print("  scanFields     = %d 项, 含数量=%s, 含折旧方法=%s" % (len(f), "num" in f, "depreciate" in f))'
echo CONFIRM_DONE
