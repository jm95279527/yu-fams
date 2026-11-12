#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/qrcol
echo "===== 1. 备份并对比差异 ====="
cp $BACK/src/main/java/com/example/controller/AssetsController.java $SRC/AssetsController.java.bak
cp $BACK/src/main/resources/application.yml $SRC/application.yml.bak
diff $SRC/AssetsController.java.bak $SRC/AssetsController.java || true
diff $SRC/application.yml.bak $SRC/application.yml || true
echo "===== 2. 覆盖源文件 ====="
cp $SRC/AssetsController.java $BACK/src/main/java/com/example/controller/
cp $SRC/application.yml $BACK/src/main/resources/
echo copied
echo "===== 3. 构建后端 ====="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build.log 2>&1
echo "build exit=$?"
tail -4 $SRC/build.log
echo "===== 4. 重启后端 ====="
bash /tmp/restart89.sh
echo DONE
