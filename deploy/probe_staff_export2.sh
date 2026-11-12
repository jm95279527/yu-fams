#!/bin/bash
ls -la /tmp/rf_staff.xlsx
file -b /tmp/rf_staff.xlsx
head -c 300 /tmp/rf_staff.xlsx
echo ""
echo "== find hutool anywhere =="
find / -name "hutool-all*.jar" -o -name "hutool-poi*.jar" 2>/dev/null | grep -v proc | head -5
echo "== jar libs in built jar =="
unzip -l /opt/yu-fams/Yu-FAMS-SpringBoot-master/target/springboot-0.0.1-SNAPSHOT.jar 2>/dev/null | grep -i "hutool" | head -5
echo DONE
