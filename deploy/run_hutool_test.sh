#!/bin/bash
set -e
M2=/root/.m2/repository
CP=$(find $M2 -name "*.jar" | tr '\n' ':')
cd /tmp
javac -cp "$CP" HutoolTest.java
java -cp ".:$CP" HutoolTest
echo DONE
