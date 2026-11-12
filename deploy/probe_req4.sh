#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e"
echo "=== department 表结构 ==="
$M "SHOW CREATE TABLE department\G" 2>/dev/null | head -20
echo "=== department 数据 ==="
$M "SELECT CONCAT('  id=',id,' name=',IFNULL(name,''),' parent=',IFNULL(parent_id,0)) FROM department ORDER BY id;" 2>/dev/null
echo "=== assets.num 分布 ==="
$M "SELECT CONCAT('  num=',num,' 条数=',COUNT(*)) FROM assets GROUP BY num ORDER BY num;" 2>/dev/null
echo "=== assets 编号样例 ==="
$M "SELECT CONCAT('  ',id,' | ',IFNULL(no,''),' | ',IFNULL(name,''),' | num=',num) FROM assets ORDER BY id LIMIT 8;" 2>/dev/null
echo "=== number_rule 配置 ==="
$M "SELECT * FROM number_rule\G" 2>/dev/null | head -25
echo "=== 到期未归还的借用单 ==="
$M "SELECT CONCAT('  id=',id,' return_date=',IFNULL(return_date,''),' return_status=',IFNULL(return_status,'')) FROM assets_receive WHERE return_status='未归还' ORDER BY id;" 2>/dev/null
echo DONE
