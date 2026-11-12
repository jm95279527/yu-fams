#!/bin/bash
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
echo "=== 服务器上的 add 源码 ==="
sed -n '34,52p' $BACK/src/main/java/com/example/service/AssetsReceiveService.java
echo "=== jar 时间 ==="
ls -l $BACK/target/springboot-0.0.1-SNAPSHOT.jar
echo "=== TokenUtils.getCurrentUser ==="
sed -n '1,80p' $BACK/src/main/java/com/example/utils/TokenUtils.java
echo DONE
