#!/bin/bash
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "update sys_config set config_value='' where config_key in ('backup_last_date','backup_last_time');" 2>/dev/null
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "select config_key, config_value from sys_config where config_key like 'backup_%' order by config_key;" 2>/dev/null
