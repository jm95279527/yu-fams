#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "=== 清理前 ==="
$M -e "SELECT CONCAT('receive id=',id,' assets_id=',assets_id,' staff_id=',IFNULL(staff_id,'NULL'),' status=',IFNULL(status,''),' cmt=',IFNULL(comment,'')) FROM assets_receive;" 2>/dev/null
$M -e "SELECT CONCAT('assets id=',id,' num=',num) FROM assets WHERE id IN (26,101);" 2>/dev/null

# 只删本次测试产生的行（按备注精确匹配，避免误删手工录入数据）
$M -e "DELETE FROM assets_receive WHERE comment IN ('A启用模板','B停用模板','C拒绝验证');" 2>/dev/null
$M -e "DELETE FROM notify_log;" 2>/dev/null
$M -e "DELETE FROM robot_config;" 2>/dev/null
$M -e "UPDATE assets SET num=2 WHERE id=101;" 2>/dev/null
$M -e "UPDATE assets SET num=1 WHERE id=26;" 2>/dev/null

echo "=== 清理后 ==="
$M -e "SELECT CONCAT('receive id=',id,' assets_id=',assets_id,' cmt=',IFNULL(comment,'')) FROM assets_receive;" 2>/dev/null
$M -e "SELECT CONCAT('robot_config=',COUNT(*)) FROM robot_config; SELECT CONCAT('notify_log=',COUNT(*)) FROM notify_log; SELECT CONCAT('assets id=',id,' num=',num) FROM assets WHERE id IN (26,101); SELECT CONCAT('tpl=',event_key,' enabled=',enabled) FROM notify_template ORDER BY id;" 2>/dev/null
echo DONE
