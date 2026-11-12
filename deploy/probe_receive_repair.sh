#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "=== 接口实测（带 token）==="
for U in "/assetsReceive/selectPage?pageNum=1&pageSize=10" "/assetsRepair/selectPage?pageNum=1&pageSize=10"; do
  printf "%-50s " "$U"
  curl -s "$B$U&token=$TOK" | head -c 300; echo
done
echo "=== 数据行数 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "
SELECT CONCAT('assets_receive=',COUNT(*)) FROM assets_receive;
SELECT CONCAT('assets_repair=',COUNT(*)) FROM assets_repair;" 2>/dev/null
echo "=== sys_menu 中相关菜单 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "
SELECT CONCAT(id,'|',IFNULL(name,''),'|',IFNULL(path,''),'|',IFNULL(api,''),'|',IFNULL(role,'')) FROM sys_menu WHERE path LIKE '%Receive%' OR path LIKE '%Repair%' OR api LIKE '%assetsReceive%' OR api LIKE '%assetsRepair%';" 2>/dev/null
echo "=== 当前管理员角色 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SELECT CONCAT('admin_role=',role) FROM admin;" 2>/dev/null
echo "=== 表结构 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SELECT CONCAT('receive cols: ',GROUP_CONCAT(COLUMN_NAME)) FROM information_schema.columns WHERE table_schema='xm-assets' AND table_name='assets_receive';" 2>/dev/null
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SELECT CONCAT('repair cols: ',GROUP_CONCAT(COLUMN_NAME)) FROM information_schema.columns WHERE table_schema='xm-assets' AND table_name='assets_repair';" 2>/dev/null
echo DONE
