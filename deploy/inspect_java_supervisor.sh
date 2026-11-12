#!/bin/bash
echo "=== 当前 java 进程 ==="
ps -eo pid,ppid,lstart,cmd | grep -E "springboot|java" | grep -v grep
echo "=== 谁占 89 ==="
ss -lntp 2>/dev/null | grep :89
echo "=== restart89.sh 内容 ==="
cat /tmp/restart89.sh 2>/dev/null
echo "=== crontab ==="
crontab -l 2>/dev/null
echo "=== 是否有 systemd 相关 ==="
systemctl list-units --type=service 2>/dev/null | grep -iE "java|yufams|spring" || echo "无"
echo "=== 是否有 watchdog/守护脚本 ==="
ls -l /opt/yu-fams/*.sh 2>/dev/null
grep -rl "springboot-0.0.1-SNAPSHOT" /etc/cron* /opt/yu-fams 2>/dev/null | head -10
echo DONE
