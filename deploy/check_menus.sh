#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "=== /role/myMenus ==="
curl -s "$B/role/myMenus" -H "token:$TOK" | head -c 1200
echo
echo "=== 菜单路径清单 ==="
curl -s "$B/role/myMenus" -H "token:$TOK" | python3 -c "
import sys,json
j=json.load(sys.stdin)
paths=[]
def walk(ms):
    for m in ms or []:
        if m.get('path'): paths.append(m['path'])
        walk(m.get('children'))
walk(j.get('data'))
print('code=',j.get('code'),'count=',len(paths))
print(paths)
"
