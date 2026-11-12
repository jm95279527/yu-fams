#!/bin/bash
echo "=== process ==="
ps -ef | grep java | grep -v grep
echo "=== find logs ==="
find /opt/yu-fams -name "*.log" -mmin -60 2>/dev/null
find / -name "nohup.out" -mmin -120 2>/dev/null | head
echo "=== application properties log path ==="
grep -ri "logging" /opt/yu-fams/Yu-FAMS-SpringBoot-master/src/main/resources/application*.yml /opt/yu-fams/Yu-FAMS-SpringBoot-master/src/main/resources/application*.properties 2>/dev/null | head
