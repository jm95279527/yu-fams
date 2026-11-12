#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/stage13b
cp -r $SRC/backend/main/java/. $BACK/src/main/java/
cd $BACK
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH
mvn clean package -DskipTests -q > $SRC/build.log 2>&1
echo MVN_OK
systemctl restart yufams
sleep 15
systemctl is-active yufams
curl -s -o /dev/null -w "login89=%{http_code}\n" -X POST http://127.0.0.1:89/login
grep -n '未填写借用人' $BACK/src/main/java/com/example/task/BorrowRemindTask.java
echo REBUILD_DONE
