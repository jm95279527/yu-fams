#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/stage21
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

cp $SRC/backend/main/java/com/example/common/config/WebConfig.java $BACK/src/main/java/com/example/common/config/
grep -c '/error' $BACK/src/main/java/com/example/common/config/WebConfig.java

cd $BACK
mvn clean package -DskipTests -q > $SRC/build.log 2>&1
echo MVN_OK

systemctl restart yufams
sleep 15
systemctl is-active yufams
curl -s -o /dev/null -w "login89=%{http_code}\n" -X POST http://127.0.0.1:89/login
echo "--- 已取消/不存在的路径应为 404（而非 500）---"
printf "  POST /register          -> %s\n" "$(curl -s -o /dev/null -w '%{http_code}' -X POST http://127.0.0.1:89/register -H 'Content-Type: application/json' -d '{"username":"hacker","password":"123","role":"STAFF"}')"
printf "  GET  /zzz/notexist      -> %s\n" "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:89/zzz/notexist)"
printf "  GET  /sysConfig/public  -> %s\n" "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:89/sysConfig/public)"
printf "  POST /login             -> %s\n" "$(curl -s -o /dev/null -w '%{http_code}' -X POST http://127.0.0.1:89/login)"
printf "  GET  /assets/selectPage (无token) -> %s\n" "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:89/assets/selectPage)"
echo STAGE21_DONE
