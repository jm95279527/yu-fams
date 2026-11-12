#!/bin/bash
DB="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e"
echo "=== TABLES ==="
$DB "show tables;" 2>/dev/null | tr '\n' ' '
echo
echo "=== assets columns ==="
$DB "select column_name,column_type from information_schema.columns where table_schema='xm-assets' and table_name='assets' order by ordinal_position;" 2>/dev/null
echo "=== assets status ==="
$DB "select status,count(*),round(sum(money),2) from assets group by status;" 2>/dev/null
echo "=== transfer ==="
$DB "select column_name from information_schema.columns where table_schema='xm-assets' and table_name='assets_transfer' order by ordinal_position;" 2>/dev/null | tr '\n' ' '
echo
$DB "select status,count(*) from assets_transfer group by status;" 2>/dev/null
echo "=== repair ==="
$DB "select column_name from information_schema.columns where table_schema='xm-assets' and table_name='assets_repair' order by ordinal_position;" 2>/dev/null | tr '\n' ' '
echo
$DB "select status,count(*) from assets_repair group by status;" 2>/dev/null
echo "=== receive ==="
$DB "select column_name from information_schema.columns where table_schema='xm-assets' and table_name='assets_receive' order by ordinal_position;" 2>/dev/null | tr '\n' ' '
echo
$DB "select status,count(*) from assets_receive group by status;" 2>/dev/null
echo "=== inventory_task ==="
$DB "select column_name from information_schema.columns where table_schema='xm-assets' and table_name='inventory_task' order by ordinal_position;" 2>/dev/null | tr '\n' ' '
echo
$DB "select status,count(*) from inventory_task group by status;" 2>/dev/null
echo "=== inventory_item ==="
$DB "select item_status,count(*) from inventory_item group by item_status;" 2>/dev/null
echo "=== company/department/category ==="
$DB "select count(*) from company; select count(*) from department; select count(*) from category;" 2>/dev/null
echo "=== assets sample ==="
$DB "select id,no,name,status,money,current_value,date,company_id,department_id,staff_id,location from assets limit 3;" 2>/dev/null
echo "=== assets count by company ==="
$DB "select a.company_id,c.name,count(*) from assets a left join company c on a.company_id=c.id group by a.company_id,c.name;" 2>/dev/null
echo DONE
