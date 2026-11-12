#!/bin/bash
set -e
B=/opt/yu-fams/Yu-FAMS-SpringBoot-master
cp /tmp/AdminService.java $B/src/main/java/com/example/service/AdminService.java
cp /tmp/AdminController.java $B/src/main/java/com/example/controller/AdminController.java
cd $B
mvn clean package -DskipTests -s /opt/yu-fams/m2-settings.xml 2>&1 | tail -5
systemctl restart yufams
sleep 4
systemctl is-active yufams
journalctl -u yufams -n 8 --no-pager | grep -E "Started|ERROR|Exception" | tail -5
echo DONE
