#!/bin/bash
set -e
M2=/root/.m2/repository
CP=/opt/yu-fams/Yu-FAMS-SpringBoot-master/target/classes:$(find $M2 -name "*.jar" | tr '\n' ':')
cd /tmp
javac -cp "$CP" StaffMapTest.java 2>/dev/null
java -cp ".:$CP" StaffMapTest 2>/dev/null
echo DONE
