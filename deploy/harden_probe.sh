#!/bin/bash
export MYSQL_PWD=YOUR_DB_PASSWORD
mysql -uroot xm-assets -N -e "SHOW TABLES" 2>/dev/null
echo "-- sys_menu log rows --"
mysql -uroot xm-assets -N -e "SELECT id,name,path,api FROM sys_menu WHERE name LIKE '%日志%' OR path LIKE '%log%'" 2>/dev/null
echo "-- crontab --"
crontab -l 2>/dev/null || echo "no crontab"
echo "-- backup dir --"
ls -la /opt/yu-fams/backup 2>/dev/null || echo "no backup dir"
echo DONE
