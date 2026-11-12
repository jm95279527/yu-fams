#!/bin/bash
echo "--- BACKUP DIR ---"
ls -lh /opt/yu-fams/Yu-FAMS-SpringBoot-master/backup/ 2>/dev/null | tail -n 20
echo "--- CONFIG ---"
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "select config_key,config_value from sys_config where config_key like 'backup%';" 2>/dev/null
echo "--- MENU ---"
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "select m.id,m.name,m.path,m.parent_id,p.name parent from sys_menu m left join sys_menu p on m.parent_id=p.id where m.path like '%dataBackup%';" 2>/dev/null
echo "--- CRON LOG ---"
tail -n 20 /opt/yu-fams/Yu-FAMS-SpringBoot-master/backup/backup.log 2>/dev/null
