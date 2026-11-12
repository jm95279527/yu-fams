#!/bin/bash
# DROP 之后的回归验证
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOKLEN=${#TOK}"

echo ""
echo "=== 1) 服务端源码里已无任何残留引用（应全为 0）==="
for kw in wx_userid wx_dept_id wxUserid wxDeptId wechat_work_config dingtalk_config third_party_user IntegrationController WechatWork; do
  n=$(grep -rl "$kw" $BACK/src/main $FRONT/src 2>/dev/null | wc -l)
  printf "  %-24s 命中文件数 = %s\n" "$kw" "$n"
done

echo ""
echo "=== 2) 登录 + 菜单（系统集成应只剩 机器人配置/通知信息）==="
curl -s "$B/role/myMenus" -H "token: $TOK" | python3 -c '
import sys, json
tree = json.load(sys.stdin)["data"]
for m in tree:
    if m.get("name") == "系统集成":
        print("  系统集成 ->", [c["name"] for c in (m.get("children") or [])])
print("  顶级菜单 ->", [m["name"] for m in tree])'

echo ""
echo "=== 3) 员工 CRUD 回归（表结构已变更）==="
curl -s -X POST $B/staff/add -H "token: $TOK" -H 'Content-Type: application/json' \
  -d '{"username":"zzdrop_a","name":"DROP验证员工","password":"123","status":"在职","phone":"13800002222"}'; echo
SID=$($M -e "select id from staff where username='zzdrop_a' limit 1")
echo "  新增 id=$SID"
curl -s -X PUT $B/staff/update -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"id\":$SID,\"position\":\"DROP验证岗位\"}"; echo
$M -e "select concat('  改后：姓名=',s.name,' 职位=',ifnull(s.position,'-'),' 电话=',ifnull(s.phone,'-')) from staff s where s.id=$SID"
curl -s "$B/staff/selectPage?pageNum=1&pageSize=10" -H "token: $TOK" | python3 -c '
import sys,json
d=json.load(sys.stdin)["data"]
print("  selectPage total =", d["total"])
for x in d["list"]: print("   ", x["id"], x["name"], "|", x.get("departmentName"))'
curl -s -X PUT $B/staff/leave/$SID -H "token: $TOK"; echo
$M -e "select concat('  离职后：',status,' ',ifnull(leave_date,'-')) from staff where id=$SID"

echo ""
echo "=== 4) 部门 CRUD 回归（表结构已变更）==="
curl -s -X POST $B/department/add -H "token: $TOK" -H 'Content-Type: application/json' \
  -d '{"name":"ZZDROP验证部","companyId":4,"level":1}'; echo
DID=$($M -e "select id from department where name='ZZDROP验证部' order by id desc limit 1")
echo "  新增 id=$DID"
curl -s -X PUT $B/department/update -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"id\":$DID,\"address\":\"DROP验证地址\"}"; echo
$M -e "select concat('  改后：',d.name,' 公司=',ifnull(c.name,'-'),' 地址=',ifnull(d.address,'-')) from department d left join company c on d.company_id=c.id where d.id=$DID"
curl -s "$B/department/selectAll" -H "token: $TOK" | python3 -c '
import sys,json
d=json.load(sys.stdin)["data"]
print("  部门总数 =", len(d))
print("  样例 label =", d[0].get("label") if d else "-")'

echo ""
echo "=== 5) 各业务接口自检 ==="
for u in /assets/selectPage /assetsIn/selectPage /assetsReceive/selectPage /assetsRepair/selectPage /assetsScrap/selectPage /assetsTransfer/selectPage /assetsInventory/selectPage /company/selectAll /category/selectAll /numberRule/selectAll /robotConfig/selectAll /notify/templates /auditLog/selectPage; do
  printf "  %-32s -> %s\n" "$u" "$(curl -s -o /dev/null -w '%{http_code}' "$B$u?pageNum=1&pageSize=5" -H "token: $TOK")"
done

echo ""
echo "=== 6) 清理测试数据 ==="
$M -e "delete from staff where username='zzdrop_a'"
$M -e "delete from department where name='ZZDROP验证部'"
echo "  测试员工剩余 = $($M -e "select count(*) from staff where username='zzdrop_a'")"
echo "  测试部门剩余 = $($M -e "select count(*) from department where name='ZZDROP验证部'")"
echo "  真实员工（应保留 2 人）："
$M -e "select concat('    ',s.id,' ',s.name,' | ',ifnull(d.name,'-'),' | ',ifnull(s.status,'-')) from staff s left join department d on s.department_id=d.id order by s.id"
echo "  部门总数 = $($M -e "select count(*) from department")   公司总数 = $($M -e "select count(*) from company")"
echo VERIFY18_DONE
