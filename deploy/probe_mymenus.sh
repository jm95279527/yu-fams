#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"
echo "=== /role/myMenus 返回的 path 列表 ==="
curl -s "$B/role/myMenus" -H "$H" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print('code',d.get('code'),'msg',d.get('msg'))
def walk(l, ind=0):
    for m in l or []:
        print(' '*ind + str(m.get('id')) + ' ' + str(m.get('name')) + ' path=' + str(m.get('path')) + ' api=' + str(m.get('api')))
        if m.get('children'): walk(m['children'], ind+2)
walk(d.get('data'))
"
echo "=== DB: 角色1 的菜单 ==="
$M -e "SELECT CONCAT(m.id,' ',m.name,' path=',IFNULL(m.path,''),' parent=',IFNULL(m.parent_id,0)) FROM sys_menu m JOIN sys_role_menu rm ON rm.menu_id=m.id WHERE rm.role_id=1 ORDER BY m.id;" 2>/dev/null
echo "=== DB: 菜单30的子项 ==="
$M -e "SELECT CONCAT(id,' ',name,' path=',IFNULL(path,''),' parent=',IFNULL(parent_id,0)) FROM sys_menu WHERE parent_id=30 ORDER BY sort,id;" 2>/dev/null
echo DONE
