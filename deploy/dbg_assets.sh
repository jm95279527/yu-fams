#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "--- assets 全表 ---"
$M -e "select concat(id,' | ',ifnull(no,'-'),' | num=',ifnull(num,'NULL'),' | ',ifnull(status,'NULL'),' | ',ifnull(name,'-')) from assets order by id"
echo "--- 数量 ---"
$M -e "select concat('total=',count(*),' num_null=',sum(num is null),' num_zero=',sum(num=0),' num_pos=',sum(num>0)) from assets"
echo "--- status 分布 ---"
$M -e "select concat(ifnull(status,'NULL'),'=',count(*)) from assets group by status"
echo DBG2_DONE
