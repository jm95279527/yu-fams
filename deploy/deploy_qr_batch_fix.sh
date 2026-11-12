#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/qrcol2
echo "===== 1. 备份并对比差异 ====="
cp $BACK/src/main/java/com/example/controller/AssetsController.java $SRC/AssetsController.java.bak
diff $SRC/AssetsController.java.bak $SRC/AssetsController.java || true
echo "===== 2. 覆盖 ====="
cp $SRC/AssetsController.java $BACK/src/main/java/com/example/controller/
echo copied
echo "===== 3. 构建 ====="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build.log 2>&1
echo "build exit=$?"
tail -4 $SRC/build.log
echo "===== 4. 重启 ====="
bash /tmp/restart89.sh
echo DONE
