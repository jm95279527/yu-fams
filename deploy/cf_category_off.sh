#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
echo "=== 清理测试分类 ==="
$M -e "delete from category where name in ('测试三级','测试电脑','测试打印机','测试电子设备')"
echo "=== 剩余分类 ==="
$M -e "select id,name,code,pid from category order by id"
echo CF_CATEGORY_OFF_DONE
