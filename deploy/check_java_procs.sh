#!/bin/bash
echo "=== 当前 java 进程 ==="
ps -eo pid,ppid,lstart,cmd | grep springboot | grep -v grep
echo "=== 谁占着 :89 ==="
ss -lntp 2>/dev/null | grep :89
echo "=== 日志尾部（找端口占用/启动失败）==="
tail -20 /tmp/yu-fams-89.log
echo "=== 日志中的错误关键字 ==="
grep -n "Port 89\|already in use\|APPLICATION FAILED" /tmp/yu-fams-89.log | tail -5
echo DONE
