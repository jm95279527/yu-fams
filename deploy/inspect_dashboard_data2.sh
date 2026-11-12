#!/bin/bash
DB="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e"
echo "=== department columns ==="
$DB "select column_name from information_schema.columns where table_schema='xm-assets' and table_name='department' order by ordinal_position;" 2>/dev/null | tr '\n' ' '
echo
echo "=== department sample ==="
$DB "select id,name,company_id from department limit 5;" 2>/dev/null
echo "=== dates ==="
$DB "select date from assets order by id desc limit 10;" 2>/dev/null
echo "=== monthly ==="
$DB "select left(date,7) m,count(*),sum(money) from assets group by left(date,7) order by m desc limit 8;" 2>/dev/null
echo "=== category ==="
$DB "select category,count(*),sum(money) from assets group by category order by count(*) desc limit 8;" 2>/dev/null
echo "=== dept top ==="
$DB "select d.name,count(*) c,sum(a.money) v from assets a left join department d on a.department_id=d.id group by d.name order by c desc limit 8;" 2>/dev/null
echo "=== company ==="
$DB "select c.name,count(*) c,sum(a.money) v from assets a join department d on a.department_id=d.id join company c on d.company_id=c.id group by c.name;" 2>/dev/null
echo "=== receive statuses ==="
$DB "select status,return_status,count(*) from assets_receive group by status,return_status;" 2>/dev/null
echo "=== receive sample ==="
$DB "select id,borrower_name,date,return_date,status,return_status from assets_receive limit 5;" 2>/dev/null
echo "=== transfer statuses ==="
$DB "select status,count(*) from assets_transfer group by status;" 2>/dev/null
echo "=== inventory tasks ==="
$DB "select id,name,status,total_count,normal_count,loss_count,abnormal_count,profit_count,create_time from inventory_task;" 2>/dev/null
echo "=== assets_in ==="
$DB "select count(*) from assets_in;" 2>/dev/null
echo DONE
