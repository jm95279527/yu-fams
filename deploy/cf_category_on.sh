#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOK_LEN=${#TOK}"

echo "=== 新增一级 ==="
curl -s -X POST "$B/category/add" -H "token: $TOK" -H 'Content-Type: application/json' \
  -d '{"pid":0,"name":"测试电子设备","code":"TESTP"}'; echo
PID=$($M -N -e "select id from category where name='测试电子设备' limit 1")
echo "parent_id=$PID"

echo "=== 新增二级 A/B ==="
curl -s -X POST "$B/category/add" -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"pid\":$PID,\"name\":\"测试电脑\",\"code\":\"TESTC1\"}"; echo
curl -s -X POST "$B/category/add" -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"pid\":$PID,\"name\":\"测试打印机\",\"code\":\"TESTC2\"}"; echo

echo "=== 三级分类应被拒绝 ==="
CID=$($M -N -e "select id from category where name='测试电脑' limit 1")
curl -s -X POST "$B/category/add" -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"pid\":$CID,\"name\":\"测试三级\",\"code\":\"TESTC3\"}"; echo

echo "=== 重名应被拒绝 ==="
curl -s -X POST "$B/category/add" -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"pid\":0,\"name\":\"测试电脑\",\"code\":\"TESTC4\"}"; echo

echo "=== 删除有子分类的一级应被拒绝 ==="
curl -s -X DELETE "$B/category/delete/$PID" -H "token: $TOK"; echo

echo "=== 当前分类列表 ==="
curl -s "$B/category/selectAll" -H "token: $TOK" | python3 -c '
import sys,json
rows=json.load(sys.stdin)["data"]
for r in rows:
    print(" ",r["id"],"|",r["name"],"| code=",r.get("code"),"| pid=",r.get("pid"),"| parent=",r.get("parentName"))
'
echo CF_CATEGORY_ON_DONE
