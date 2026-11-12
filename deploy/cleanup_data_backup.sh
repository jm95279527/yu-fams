#!/bin/bash
BK=/opt/yu-fams/Yu-FAMS-SpringBoot-master/backup
rm -f $BK/backup_*.zip
rm -rf /opt/yu-fams/Yu-FAMS-SpringBoot-master/files_prev_*
rm -f /tmp/dl_backup.zip
echo "=== 备份目录 ==="
ls -lh $BK
echo "=== 配置 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "select config_key,config_value from sys_config where config_key like 'backup_%' order by config_key;" 2>/dev/null
echo "=== 菜单权限 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "select role_id,menu_id from sys_role_menu where menu_id=57;" 2>/dev/null
echo "=== 前端产物 ==="
grep -rl '数据备份' /www/wwwroot/yufams/js | head -n 2
curl -s -o /dev/null -w 'page=%{http_code}\n' http://127.0.0.1:88/dataBackup
echo CLEANUP_BACKUP_DONE
