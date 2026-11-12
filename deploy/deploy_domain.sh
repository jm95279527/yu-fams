#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/domainfix
echo "===== 1. 备份并对比 ====="
cp $BACK/src/main/resources/application.yml $SRC/application.yml.bak
diff $SRC/application.yml.bak $SRC/application.yml || true
echo "===== 2. 覆盖 ====="
cp $SRC/application.yml $BACK/src/main/resources/
echo "===== 3. 构建后端 ====="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build.log 2>&1
echo "build exit=$?"
tail -3 $SRC/build.log
echo "===== 4. 重启 ====="
bash /tmp/restart89.sh
echo DONE
