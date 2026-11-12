#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "=== 当前 robot_config ==="
$M -e "SELECT CONCAT('  id=',id,' name=',IFNULL(name,''),' url=',IFNULL(LEFT(webhook_url,60),''),' enabled=',enabled,' create=',IFNULL(create_time,'')) FROM robot_config;" 2>/dev/null
$M -e "SELECT CONCAT('  条数=',COUNT(*)) FROM robot_config;" 2>/dev/null
echo "=== 审计日志中是否有人新增过机器人（最近20条相关）==="
$M -e "SELECT CONCAT('  ',create_time,' ',method,' ',uri,' ',IFNULL(LEFT(params,90),''),' code=',IFNULL(result_code,'')) FROM audit_log WHERE uri LIKE '%robotConfig%' ORDER BY id DESC LIMIT 20;" 2>/dev/null
echo "=== 当前 notify_log ==="
$M -e "SELECT CONCAT('  条数=',COUNT(*)) FROM notify_log;" 2>/dev/null
echo DONE
