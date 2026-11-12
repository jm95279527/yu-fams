#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "Q1:"; $M -e "select count(*) from assets where num > 0" 2>&1
echo "Q2:"; $M -e "select count(*) from assets where status='正常'" 2>&1
echo "Q3:"; $M -e "select id from assets where num > 0 and status='正常' order by id limit 1" 2>&1
echo "Q4:"; $M -e 'select id from assets where num > 0 and status="正常" order by id limit 1' 2>&1
echo "Q5:"; $M -e "select id from assets where num>0 and status='正常' limit 1" 2>&1
echo "--- 借用/维修 现有数据 ---"
$M -e "select concat(id,'|',status,'|',return_status) from assets_receive order by id"
$M -e "select concat(id,'|',status) from assets_repair order by id"
echo DBG_DONE
