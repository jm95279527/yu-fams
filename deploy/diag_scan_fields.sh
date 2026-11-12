#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "--- assets.status 取值分布 ---"
$M -e "select concat('  ',ifnull(status,'(空)'),' × ',count(*)) from assets group by status"
echo "--- assets 可编辑列 ---"
$M -e "select concat('  ',column_name,' ',column_type) from information_schema.columns where table_schema='xm-assets' and table_name='assets' and column_name in ('name','location','staff_id','status','comment','img','department_id')"
echo "--- 责任人下拉数据源（staff） ---"
$M -e "select concat('  ',id,' ',name) from staff order by id"
echo DIAG_SCAN_DONE
