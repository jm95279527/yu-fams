#!/bin/bash
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "ALTER TABLE assets_scrap MODIFY COLUMN depreciate VARCHAR(64) COMMENT '折旧方式（快照）';" 2>&1 | grep -v "Warning"
echo "ALTER_DONE"
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "SHOW COLUMNS FROM assets_scrap LIKE 'depreciate';" 2>&1 | grep -v "Warning"
