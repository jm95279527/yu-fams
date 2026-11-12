#!/bin/bash
export MYSQL_PWD=YOUR_DB_PASSWORD
mysqlq(){ mysql -uroot xm-assets -N -e "$1" 2>/dev/null; }
echo "== admin user row =="
mysqlq "SELECT id,username,name,role FROM admin WHERE username='admin'"
echo "== roles =="
mysqlq "SELECT id,name,flag FROM sys_role"
echo "== menu 15 roles =="
mysqlq "SELECT r.id,r.name FROM sys_role_menu rm JOIN sys_role r ON r.id=rm.role_id WHERE rm.menu_id=15"
echo "== all inventory-ish menus =="
mysqlq "SELECT id,name,path,api FROM sys_menu WHERE path LIKE '%inventory%' OR path LIKE '%Inventory%'"
echo DONE
