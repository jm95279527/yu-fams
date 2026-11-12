#!/bin/bash
export MYSQL_PWD=YOUR_DB_PASSWORD
echo "== assets overview =="
mysql -uroot xm-assets -N -e "SELECT id,no,name,status,department_id FROM assets ORDER BY id" 2>/dev/null
echo "== login test =="
sleep 3
curl -s -X POST http://localhost:89/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | head -c 250
echo ""
echo DONE
