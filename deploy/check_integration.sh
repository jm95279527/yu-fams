#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
echo "=== 集成相关表是否存在 / 行数 ==="
for t in wechat_work_config dingtalk_config third_party_user; do
  CNT=$($M -N -e "select count(*) from $t" 2>/dev/null)
  if [ -z "$CNT" ]; then echo "  $t : 不存在"; else echo "  $t : $CNT 行"; fi
done
echo "=== wechat_work_config 内容 ==="
$M -e "select * from wechat_work_config" 2>/dev/null
echo "=== dingtalk_config 内容 ==="
$M -e "select * from dingtalk_config" 2>/dev/null
echo "=== third_party_user 内容 ==="
$M -e "select * from third_party_user" 2>/dev/null
echo "=== 菜单 31 ==="
$M -e "select id,parent_id,name,path,api from sys_menu where id=31"
echo "=== sys_role_menu 中 menu_id=31 ==="
$M -e "select role_id,menu_id from sys_role_menu where menu_id=31"
echo "=== department.wx_dept_id / staff.wx_userid 是否有非空值 ==="
$M -N -e "select concat('department.wx_dept_id 非空行数=',count(*)) from department where wx_dept_id is not null"
$M -N -e "select concat('staff.wx_userid 非空行数=',count(*)) from staff where wx_userid is not null"
echo CHECK_INTEGRATION_DONE
