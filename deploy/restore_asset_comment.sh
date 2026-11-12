#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "--- 改前 ---"
$M -e "select concat('  id=',id,' name=',name,' location=',ifnull(location,'NULL'),' comment=',ifnull(comment,'NULL'),' staff_id=',ifnull(staff_id,'NULL'),' status=',status,' img=',ifnull(img,'NULL'),' no=',no,' category=',ifnull(category,'-'),' department_id=',ifnull(department_id,'-')) from assets where id=125"
# 验证过程中前端原值回写把原本为 NULL 的备注写成了空字符串，这里还原为 NULL
$M -e "update assets set comment = NULL where id = 125 and comment = ''"
echo "--- 改后（备注应回到 NULL）---"
$M -e "select concat('  id=',id,' name=',name,' location=',ifnull(location,'NULL'),' comment=',ifnull(comment,'NULL'),' staff_id=',ifnull(staff_id,'NULL'),' status=',status,' img=',ifnull(img,'NULL'),' no=',no,' category=',ifnull(category,'-'),' department_id=',ifnull(department_id,'-')) from assets where id=125"
echo "--- 全表状态 ---"
$M -e "select concat('  资产数=',count(*)) from assets"
$M -e "select concat('  借用单数=',count(*)) from assets_receive"
$M -e "select concat('  报修单数=',count(*)) from assets_repair"
echo RESTORE_DONE
