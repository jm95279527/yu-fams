#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/stage21
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "=== backup ==="
cp $BACK/src/main/java/com/example/common/config/JwtInterceptor.java /tmp/stage21bak/ 2>/dev/null || { mkdir -p /tmp/stage21bak; cp $BACK/src/main/java/com/example/common/config/JwtInterceptor.java /tmp/stage21bak/; }
echo BACKUP_OK

echo "=== copy ==="
cp $SRC/backend/main/java/com/example/common/config/JwtInterceptor.java $BACK/src/main/java/com/example/common/config/
cp $SRC/backend/main/java/com/example/common/config/WebConfig.java $BACK/src/main/java/com/example/common/config/
grep -n 'DispatcherType' $BACK/src/main/java/com/example/common/config/JwtInterceptor.java

echo "=== build ==="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build2.log 2>&1
echo MVN_OK

echo "=== restart ==="
systemctl restart yufams
sleep 15
systemctl is-active yufams
echo "--- 路径语义检查 ---"
printf "  POST /register          -> %s （期望 404）\n" "$(curl -s -o /dev/null -w '%{http_code}' -X POST http://127.0.0.1:89/register -H 'Content-Type: application/json' -d '{"username":"hacker","password":"123","role":"STAFF"}')"
printf "  GET  /zzz/notexist      -> %s （期望 404）\n" "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:89/zzz/notexist)"
printf "  GET  /sysConfig/public  -> %s （期望 200）\n" "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:89/sysConfig/public)"
printf "  POST /login(空body)     -> %s （期望 200）\n" "$(curl -s -o /dev/null -w '%{http_code}' -X POST http://127.0.0.1:89/login)"
echo "--- 鉴权是否仍然生效（已映射接口无 token 应回 401 业务码）---"
echo -n "  GET /assets/selectPage 无token -> "
curl -s http://127.0.0.1:89/assets/selectPage; echo
echo -n "  GET /sysConfig/selectAll 无token -> "
curl -s http://127.0.0.1:89/sysConfig/selectAll; echo
echo SEMANTIC_DONE
