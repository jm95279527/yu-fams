#!/bin/bash
# 死代码清理后的回归验证
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOKLEN=${#TOK}"
TOD=$(date +%F)

echo ""
echo "########## A. 菜单：集成入口已消失，其余功能菜单健在 ##########"
curl -s "$B/role/myMenus" -H "token: $TOK" | python3 -c '
import sys, json
tree = json.load(sys.stdin)["data"]
def walk(list, depth=0):
    for m in list:
        print("  " + "  "*depth + str(m.get("id")) + " " + str(m.get("name")) + "  " + str(m.get("path") or ""))
        if m.get("children"): walk(m["children"], depth+1)
walk(tree)'
echo "  -- 是否还存在「企业微信/钉钉」字样 --"
curl -s "$B/role/myMenus" -H "token: $TOK" | grep -c '企业微信' || echo "  0（已无）"

echo ""
echo "########## B. /integration 接口已下线 ##########"
for u in /integration/wechat/authUrl /integration/config; do
  printf "  %-34s -> %s\n" "$u" "$(curl -s -o /dev/null -w '%{http_code}' "$B$u" -H "token: $TOK")"
done
printf "  %-34s -> %s\n" "（未带token） /integration/wechat/authUrl" "$(curl -s -o /dev/null -w '%{http_code}' "$B/integration/wechat/authUrl")"

echo ""
echo "########## C. 员工/部门 CRUD 回归（本次改了两张 mapper）##########"
echo "  -- 部门 selectAll（含 label）--"
curl -s "$B/department/selectAll" -H "token: $TOK" | python3 -c '
import sys,json
d=json.load(sys.stdin)["data"]
print("   部门数 =", len(d))
for x in d[:3]: print("   ", x["id"], x["name"], "| label =", x.get("label"), "| companyId =", x.get("companyId"))'
echo "  -- 新增部门 -->"
curl -s -X POST $B/department/add -H "token: $TOK" -H 'Content-Type: application/json' \
  -d '{"name":"ZZ清理验证部","companyId":4,"level":1}'; echo
DID=$($M -e "select id from department where name='ZZ清理验证部' order by id desc limit 1")
echo "   新部门 id=$DID"
echo "  -- 修改部门 -->"
curl -s -X PUT $B/department/update -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"id\":$DID,\"name\":\"ZZ清理验证部2\",\"address\":\"测试地址\"}"; echo
$M -e "select concat('   改后：',name,' | ',ifnull(address,'-')) from department where id=$DID"
echo "  -- 员工 新增/查询/修改 -->"
curl -s -X POST $B/staff/add -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"username\":\"zzclean_a\",\"name\":\"清理验证员工\",\"password\":\"123\",\"status\":\"在职\",\"departmentId\":$DID,\"phone\":\"13800001234\"}"; echo
SID=$($M -e "select id from staff where username='zzclean_a' limit 1")
echo "   员工 id=$SID"
curl -s -X PUT $B/staff/update -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"id\":$SID,\"position\":\"测试岗位\"}"; echo
$M -e "select concat('   改后：',name,' | 部门=',ifnull(d.name,'-'),' | 职位=',ifnull(s.position,'-'),' | 电话=',ifnull(s.phone,'-')) from staff s left join department d on s.department_id=d.id where s.id=$SID"
echo "  -- 员工 selectPage（验证 Base_Column_List 去 wx_userid 后可用）--"
curl -s "$B/staff/selectPage?pageNum=1&pageSize=5" -H "token: $TOK" | python3 -c '
import sys,json
d=json.load(sys.stdin)["data"]
print("   total =", d["total"], " 第一条 =", (d["list"][0]["name"] if d["list"] else "-"))'
echo "  -- 员工一键离职回归 --"
curl -s -X PUT $B/staff/leave/$SID -H "token: $TOK"; echo
$M -e "select concat('   状态=',status,' 离职日期=',ifnull(leave_date,'-')) from staff where id=$SID"

echo ""
echo "########## D. 其余业务列表接口自检 ##########"
for u in /assets/selectPage /assetsIn/selectPage /assetsReceive/selectPage /assetsRepair/selectPage /assetsScrap/selectPage /assetsTransfer/selectPage /assetsInventory/selectPage /company/selectAll /category/selectAll /robotConfig/selectAll /notify/templates /auditLog/selectPage; do
  printf "  %-32s -> %s\n" "$u" "$(curl -s -o /dev/null -w '%{http_code}' "$B$u?pageNum=1&pageSize=5" -H "token: $TOK")"
done

echo ""
echo "########## E. 前端产物里已无集成相关代码 ##########"
grep -rl 'wechat-callback' /www/wwwroot/yufams/ 2>/dev/null && echo "  警告：产物仍含 wechat-callback" || echo "  前端产物已无 wechat-callback"
grep -rl 'Integration' /www/wwwroot/yufams/js/ 2>/dev/null | head -3 && echo "  （上面是命中的文件）" || echo "  前端产物 js 中已无 Integration"

echo ""
echo "########## F. 清理测试数据 ##########"
$M -e "delete from staff where username='zzclean_a'"
$M -e "delete from department where name like 'ZZ清理验证部%'"
echo "   staff_left=$($M -e "select count(*) from staff")  dept_left=$($M -e "select count(*) from department where name like 'ZZ清理验证部%'")"
echo "   dept_total=$($M -e "select count(*) from department")  company_total=$($M -e "select count(*) from company")"
echo VERIFY17_DONE
