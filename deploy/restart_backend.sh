#!/bin/bash
pkill -f 'springboot' || true
sleep 2
nohup java -jar /opt/yu-fams/Yu-FAMS-SpringBoot-master/target/springboot-0.0.1-SNAPSHOT.jar > /tmp/yu-fams.log 2>&1 &
disown
echo "started pid $!"
