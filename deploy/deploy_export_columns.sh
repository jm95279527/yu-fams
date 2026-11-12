#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/exportcol
echo "===== 1. 备份原文件 ====="
mkdir -p $SRC/bak
for f in AssetsController AssetsInController AssetsScrapController; do
  cp $BACK/src/main/java/com/example/controller/$f.java $SRC/bak/$f.java
done
echo "===== 2. 差异对比（确认仅本次改动）====="
for f in AssetsController AssetsInController AssetsScrapController; do
  echo "--- $f ---"
  diff $SRC/bak/$f.java $SRC/$f.java || true
done
echo "===== 3. 覆盖源文件 ====="
cp $SRC/AssetsController.java $BACK/src/main/java/com/example/controller/
cp $SRC/AssetsInController.java $BACK/src/main/java/com/example/controller/
cp $SRC/AssetsScrapController.java $BACK/src/main/java/com/example/controller/
echo copied
echo "===== 4. 构建后端 ====="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build.log 2>&1
echo "build exit=$?"
tail -6 $SRC/build.log
ls -l $BACK/target/springboot-0.0.1-SNAPSHOT.jar
echo "===== 5. 重启后端 ====="
bash /tmp/restart89.sh
echo DONE
