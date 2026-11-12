#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "=== 借用单（assets_receive）==="
$M -e "SELECT CONCAT('id=',id,' 借用人=',IFNULL(borrower_name,'(空)'),' 联系方式=',IFNULL(borrower_phone,'(空)'),' staff_id=',IFNULL(staff_id,'NULL'),' cmt=',IFNULL(comment,'')) FROM assets_receive ORDER BY id;" 2>/dev/null
echo "=== 报修单（assets_repair）==="
$M -e "SELECT CONCAT('id=',id,' 报修人=',IFNULL(reporter_name,'(空)'),' 电话=',IFNULL(reporter_phone,'(空)'),' staff_id=',IFNULL(staff_id,'NULL'),' reason=',IFNULL(reason,'')) FROM assets_repair ORDER BY id;" 2>/dev/null
echo "=== 是否存在测试残留（E2E/UI测试）==="
$M -e "SELECT CONCAT('receive残留=',COUNT(*)) FROM assets_receive WHERE comment LIKE '%E2E%' OR comment LIKE '%UI测试%' OR borrower_name LIKE '%测试%';" 2>/dev/null
$M -e "SELECT CONCAT('repair残留=',COUNT(*)) FROM assets_repair WHERE reason LIKE '%E2E%' OR reason LIKE '%UI测试%' OR reporter_name LIKE '%测试%';" 2>/dev/null
$M -e "SELECT CONCAT('notify_log=',COUNT(*)) FROM notify_log; SELECT CONCAT('robot_config=',COUNT(*)) FROM robot_config;" 2>/dev/null
echo "=== 数量为0的资产（借用时会提示“资产数量不足”，属既有规则）==="
$M -e "SELECT CONCAT('  id=',id,' name=',IFNULL(name,''),' num=',num) FROM assets WHERE num <= 0 ORDER BY id LIMIT 5;" 2>/dev/null
echo DONE
