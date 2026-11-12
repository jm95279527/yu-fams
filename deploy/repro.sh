#!/bin/bash
echo "=== login attempt ==="
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:89/user/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}'
echo "=== log tail (exceptions) ==="
grep -A40 "Exception\|ERROR\|Caused by" /tmp/yu-fams-89.log | tail -80
