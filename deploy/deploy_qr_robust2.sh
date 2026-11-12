#!/bin/bash
set -e
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
SRC=/tmp/stage_qr
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH
cp -r $SRC/backend/main/java/. $BACK/src/main/java/
echo SYNC_OK
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back2.log 2>&1 || { tail -n 80 $SRC/build-back2.log; exit 1; }
echo MVN_OK
systemctl restart yufams
sleep 15
systemctl is-active yufams
echo STAGE_QR2_DONE
