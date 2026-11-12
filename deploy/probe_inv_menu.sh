#!/bin/bash
export MYSQL_PWD=YOUR_DB_PASSWORD
echo "== inventory menus =="
mysql -uroot xm-assets -N -e "SELECT id,name,path,api,type,parent_id FROM sys_menu WHERE path LIKE '%inventory%' OR name LIKE '%盘点%'" 2>/dev/null
echo "== role assignment of inventory menu =="
mysql -uroot xm-assets -N -e "SELECT r.name, m.name FROM sys_role_menu rm JOIN sys_role r ON r.id=rm.role_id JOIN sys_menu m ON m.id=rm.menu_id WHERE m.path LIKE '%inventory%'" 2>/dev/null
echo DONE
