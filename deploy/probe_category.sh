#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
echo "=== category 表结构 ==="
$M -e "desc category"
echo "=== category 数据 ==="
$M -e "select * from category order by id"
echo "=== assets 分类分布 ==="
$M -e "select category,count(*) as cnt from assets group by category"
echo "=== assets 总数 ==="
$M -N -e "select count(*) from assets"
echo "=== number_rule ==="
$M -e "select * from number_rule"
echo "=== 引用 category 的后端文件 ==="
grep -rl "categoryMapper\|selectByName" /opt/yu-fams/Yu-FAMS-SpringBoot-master/src/main/java | sed 's#.*/##'
