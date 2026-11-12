#!/bin/bash
# 杀掉89端口旧进程，用89端口+日志文件重启
echo "killing old java..."
pkill -f 'springboot-0.0.1-SNAPSHOT' || true
sleep 3
echo "remaining java:"
ps -ef | grep springboot | grep -v grep || echo "none"
echo "starting on port 89..."
nohup java -jar /opt/yu-fams/Yu-FAMS-SpringBoot-master/target/springboot-0.0.1-SNAPSHOT.jar --server.port=89 > /tmp/yu-fams-89.log 2>&1 &
disown
echo "started pid $!"
sleep 1
echo "waiting for startup..."
for i in $(seq 1 30); do
  if curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:89/ | grep -q 200; then
    echo "UP after ${i}s"
    break
  fi
  sleep 1
done
