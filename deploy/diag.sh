#!/bin/bash
echo "=== application.yml server port ==="
grep -A3 "server:" /opt/yu-fams/Yu-FAMS-SpringBoot-master/src/main/resources/application.yml | head
echo "=== nginx proxy ==="
grep -rn "proxy_pass\|89\|9091" /www/server/panel/vhost/nginx/*.conf /etc/nginx/conf.d/*.conf 2>/dev/null | head
echo "=== jar mtime ==="
ls -la /opt/yu-fams/Yu-FAMS-SpringBoot-master/target/springboot-0.0.1-SNAPSHOT.jar
echo "=== who listens 89 ==="
ss -tnlp 2>/dev/null | grep ':89'
