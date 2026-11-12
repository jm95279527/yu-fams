#!/bin/bash
# 借用到期提醒 触发验证（用工作目录 application.yml 临时把 cron 改为每分钟）
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
WD=/opt/yu-fams/Yu-FAMS-SpringBoot-master

printf 'borrow-remind-cron: "0 * * * * ?"\n' > $WD/application.yml
echo "-- 覆盖配置 --"
cat $WD/application.yml
systemctl restart yufams
C=000
for i in $(seq 1 20); do sleep 4; C=$(curl -s -o /dev/null -w '%{http_code}' -X POST $B/login); [ "$C" = "200" ] && break; done
echo "backend_up=$C"

BEFORE=$($M -e "select count(*) from notify_log where event_key='RECEIVE_DUE'")
NOW=$BEFORE
for i in $(seq 1 25); do sleep 8; NOW=$($M -e "select count(*) from notify_log where event_key='RECEIVE_DUE'"); [ "$NOW" -gt "$BEFORE" ] && break; done
echo "RECEIVE_DUE: before=$BEFORE after=$NOW (loops=$i)"
echo "-- 最新提醒记录 --"
$M -e "select concat(id,' | ',event_key,' | ',biz_type,' | ',status,' | ',title,' | robot=',ifnull(robot_name,'-')) from notify_log where event_key='RECEIVE_DUE' order by id desc limit 1"
echo "-- 提醒正文 --"
$M -e "select content from notify_log where event_key='RECEIVE_DUE' order by id desc limit 1"
echo "-- 任务日志 --"
journalctl -u yufams --since -6min 2>/dev/null | grep -E 'BorrowRemindTask|借用到期提醒' | tail -5

echo "-- 移除覆盖配置并重启（恢复每天 9:00）--"
rm -f $WD/application.yml
systemctl restart yufams
C=000
for i in $(seq 1 20); do sleep 4; C=$(curl -s -o /dev/null -w '%{http_code}' -X POST $B/login); [ "$C" = "200" ] && break; done
echo "backend_restored=$C"
ls -l $WD/application.yml 2>&1 | head -2
echo "REMIND_TEST_DONE"
