#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "=== 各表行数 ==="
for t in staff assets assets_receive assets_repair assets_in assets_scrap assets_transfer department company; do
  echo "  $t = $($M -e "select count(*) from $t")"
done
echo "=== 菜单（基础资料/权限管理）==="
$M -e "select concat('  ',m.parent_id,' > ',m.id,' | sort=',m.sort,' | ',m.name,' | ',ifnull(m.path,'-')) from sys_menu m where m.parent_id in (20,40) order by m.parent_id, m.sort"
echo "=== 角色-菜单授权（员工信息43）==="
$M -e "select concat('  role=',r.name,' -> menu43(',m.name,')') from sys_role_menu rm left join sys_role r on r.id=rm.role_id left join sys_menu m on m.id=rm.menu_id where rm.menu_id=43"
echo "=== 通知模板数 ==="
$M -e "select concat('  templates=',count(*)) from notify_template"
echo FINAL_CHECK_DONE
