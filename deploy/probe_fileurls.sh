#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "=== 各表含 http:// 的列（发现写死地址的存量数据）==="
for t in assets admin staff assets_in category department; do
  cols=$($M -e "SELECT GROUP_CONCAT(COLUMN_NAME) FROM information_schema.columns WHERE table_schema='xm-assets' AND table_name='$t' AND DATA_TYPE IN ('varchar','text');" 2>/dev/null)
  [ -z "$cols" ] && continue
  echo "--- $t : $cols"
  for c in $(echo "$cols" | tr ',' ' '); do
    n=$($M -e "SELECT COUNT(*) FROM \`$t\` WHERE \`$c\` LIKE 'http%';" 2>/dev/null)
    [ "$n" != "0" ] && echo "     $t.$c -> $n 行"
  done
done
echo "=== 样例 ==="
$M -e "SELECT id,img FROM assets WHERE img LIKE 'http%' LIMIT 2;" 2>/dev/null
$M -e "SELECT id,avatar FROM admin WHERE avatar LIKE 'http%' LIMIT 2;" 2>/dev/null
echo DONE
