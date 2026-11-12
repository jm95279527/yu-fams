#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/stage18
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
DA=/opt/yu-fams/backup
BK=$DA/integration_dropped_20261015.sql.gz

echo "=== 1. 备份三张集成表（建表语句 + 全部数据）==="
mkdir -p $DA
mysqldump -uroot -pYOUR_DB_PASSWORD --single-transaction --triggers \
  xm-assets wechat_work_config dingtalk_config third_party_user 2>/dev/null | gzip > $BK
gunzip -t $BK && echo BACKUP_OK
ls -la $BK
echo "--- 备份内含建表语句数量 ---"
zcat $BK | grep -c 'CREATE TABLE'
echo "--- 备份内关键数据（企微凭据）---"
zcat $BK | grep -o "ww32ee4002b20f705b" | head -1

echo ""
echo "=== 2. 执行 DROP（表 + 字段）==="
$M < $SRC/backend/main/resources/sql/drop_integration.sql
echo DROP_OK

echo ""
echo "=== 3. 核对删除结果（应全为 0）==="
for t in wechat_work_config dingtalk_config third_party_user; do
  echo "  表 $t 存在数 = $($M -N -e "select count(*) from information_schema.tables where table_schema=database() and table_name='$t'")"
done
echo "  staff.wx_userid 存在数 = $($M -N -e "select count(*) from information_schema.columns where table_schema=database() and table_name='staff' and column_name='wx_userid'")"
echo "  department.wx_dept_id 存在数 = $($M -N -e "select count(*) from information_schema.columns where table_schema=database() and table_name='department' and column_name='wx_dept_id'")"

echo ""
echo "=== 4. 同步 sql 目录 + 移除历史脚本 integration_tables.sql ==="
rm -f $BACK/src/main/resources/sql/integration_tables.sql
cp $SRC/backend/main/resources/sql/drop_integration.sql \
   $SRC/backend/main/resources/sql/cleanup_integration.sql \
   $SRC/backend/main/resources/sql/role_perm.sql \
   $SRC/backend/main/resources/sql/menu_api_auth.sql \
   $BACK/src/main/resources/sql/
echo "  服务端 integration_tables.sql 是否存在：$([ -f $BACK/src/main/resources/sql/integration_tables.sql ] && echo 是 || echo 否)"
echo "  服务端 sql 文件数：$(ls $BACK/src/main/resources/sql/ | wc -l)"
echo STAGE18_DONE
