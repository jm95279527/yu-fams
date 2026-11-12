#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "=== assets_receive 现状 ==="
$M -e "SELECT CONCAT('id=',id,' assets_id=',assets_id,' staff_id=',IFNULL(staff_id,'NULL'),' 借用人=',IFNULL(borrower_name,'(空)'),' status=',IFNULL(status,''),' return_status=',IFNULL(return_status,'')) FROM assets_receive ORDER BY id;" 2>/dev/null
echo "=== 资产库存 ==="
$M -e "SELECT CONCAT('id=',id,' name=',IFNULL(name,''),' num=',num) FROM assets WHERE id IN (SELECT DISTINCT assets_id FROM assets_receive) ORDER BY id;" 2>/dev/null
echo DONE
