#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/stage23
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

mkdir -p /tmp/stage23bak
cp $BACK/src/main/java/com/example/common/config/JwtInterceptor.java /tmp/stage23bak/ 2>/dev/null || true

cp $SRC/backend/main/java/com/example/common/config/JwtInterceptor.java $BACK/src/main/java/com/example/common/config/
grep -n 'HandlerMethod' $BACK/src/main/java/com/example/common/config/JwtInterceptor.java

cd $BACK
mvn clean package -DskipTests -q > $SRC/build.log 2>&1
echo MVN_OK

systemctl restart yufams
sleep 15
systemctl is-active yufams

echo "--- 路径语义（期望：不存在=404，匿名白名单=200，受保护接口=401业务码）---"
printf "  POST /register                 -> %s\n" "$(curl -s -o /dev/null -w '%{http_code}' -X POST http://127.0.0.1:89/register -H 'Content-Type: application/json' -d '{"username":"hacker","password":"123","role":"STAFF"}')"
printf "  GET  /zzz/notexist             -> %s\n" "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:89/zzz/notexist)"
printf "  GET  /sysConfig/public         -> %s\n" "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:89/sysConfig/public)"
printf "  POST /login                    -> %s\n" "$(curl -s -o /dev/null -w '%{http_code}' -X POST http://127.0.0.1:89/login)"
printf "  GET  /qr/png                   -> %s\n" "$(curl -s -o /dev/null -w '%{http_code}' 'http://127.0.0.1:89/qr/png?size=100&text=abc')"
echo -n "  GET  /assets/selectPage 无token -> "
curl -s http://127.0.0.1:89/assets/selectPage; echo
echo -n "  GET  /sysConfig/selectAll 无token -> "
curl -s http://127.0.0.1:89/sysConfig/selectAll; echo
echo "--- 确认注册真的不可用（不应新建账号）---"
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "select concat('  staff 中 hacker 数量=',count(*)) from staff where username='hacker'"
echo DISPATCH2_DONE
