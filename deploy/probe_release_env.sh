#!/bin/bash
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"

echo "===== 版本 ====="
java -version 2>&1 | head -2
mvn -version 2>&1 | head -1
node -v 2>/dev/null || echo "node:none"
npm -v 2>/dev/null || echo "npm:none"
mysql --version
nginx -v 2>&1

echo "===== 后端结构 ====="
ls -la $BACK | head -20
echo "-- pom 摘要 --"
grep -nE '<artifactId>|<version>|<java.version>|<packaging>' $BACK/pom.xml | head -30

echo "===== 前端结构 ====="
ls -la $FRONT | head -25
echo "-- package.json --"
cat $FRONT/package.json
echo "-- .env.production --"
cat $FRONT/.env.production 2>/dev/null
cat $FRONT/.env.development 2>/dev/null

echo "===== application.yml ====="
cat $BACK/src/main/resources/application.yml

echo "===== systemd ====="
systemctl cat yufams 2>/dev/null

echo "===== nginx vhost ====="
cat /www/server/panel/vhost/nginx/yufams.conf 2>/dev/null

echo "===== 上传目录 & 大小 ====="
grep -nE 'upload|file' $BACK/src/main/java/com/example/controller/FileController.java | head -20
du -sh /opt/yu-fams/* 2>/dev/null
du -sh $BACK/target 2>/dev/null
du -sh $FRONT/node_modules 2>/dev/null

echo "===== 数据库 ====="
$M -e "select concat('tables=',count(*)) from information_schema.tables where table_schema='xm-assets'"
$M -e "select concat(table_name,' rows~',table_rows,' data=',round(data_length/1024/1024,2),'M idx=',round(index_length/1024/1024,2),'M') from information_schema.tables where table_schema='xm-assets' order by table_rows desc limit 15"
echo "-- 关键索引 --"
$M -e "select concat(table_name,'.',index_name,' [',group_concat(column_name order by seq_in_index),'] unique=',non_unique=0) from information_schema.statistics where table_schema='xm-assets' and table_name in ('assets','assets_receive','assets_repair','assets_transfer','assets_scrap','audit_log','staff','department') group by table_name,index_name order by table_name,index_name"

echo "===== 定时任务/备份 ====="
crontab -l 2>/dev/null
ls -lh /opt/yu-fams/backup 2>/dev/null | tail -5

echo "===== 日志 ====="
journalctl -u yufams -n 5 --no-pager 2>/dev/null | tail -5
ls -lh /opt/yu-fams/*.log 2>/dev/null
echo PROBE_DONE
