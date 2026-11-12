#!/bin/bash
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "
select a.id,a.no,a.name,a.department_id,a.staff_id,a.location,d.name dept,d.company_id,c.name company
from assets a left join department d on a.department_id=d.id left join company c on d.company_id=c.id
where a.status<>'报废' order by a.id limit 8;
select s.id,s.name,s.department_id,d.name dept,d.company_id from staff s
left join department d on s.department_id=d.id where s.status='在职' limit 15;
" 2>/dev/null
