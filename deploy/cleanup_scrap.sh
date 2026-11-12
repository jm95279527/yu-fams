#!/bin/bash
# 清理浏览器测试产生的报废数据
mysql -uroot -pYOUR_DB_PASSWORD xm-assets <<'SQL' 2>&1 | grep -v "Warning"
DELETE FROM assets_scrap;
DELETE FROM assets_detail WHERE operation_type='报废';
UPDATE assets SET status='正常' WHERE status='已报废';
SELECT id, no, status FROM assets WHERE id IN (104,105,106);
SELECT COUNT(*) AS scrap_left FROM assets_scrap;
SELECT COUNT(*) AS detail_left FROM assets_detail WHERE operation_type='报废';
SQL
echo "CLEANUP_DONE"
