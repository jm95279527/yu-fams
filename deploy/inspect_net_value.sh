#!/bin/bash
DB="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e"
$DB "select count(*) total, sum(current_value is null) cv_null, sum(current_value=0) cv_zero, sum(depreciation_rate is not null) rate_not_null, sum(depreciate is not null) dep_not_null from assets;" 2>/dev/null
echo "--- samples ---"
$DB "select id,no,money,current_value,depreciate,depreciation_rate from assets where money is not null limit 8;" 2>/dev/null
echo "--- distinct depreciate ---"
$DB "select depreciate,count(*) from assets group by depreciate limit 10;" 2>/dev/null
echo DONE
