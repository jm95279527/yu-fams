#!/bin/bash
set -e
cd /opt/yu-fams/Yu-FAMS-SpringBoot-master
mvn -q dependency:build-classpath -Dmdep.outputFile=/tmp/cp.txt > /tmp/cp.log 2>&1
echo CP_OK
CP=$(cat /tmp/cp.txt)
javac -encoding UTF-8 -cp "$CP" -d /tmp /tmp/QrPhotoTest.java
echo COMPILE_OK
java -cp "/tmp:$CP" QrPhotoTest
