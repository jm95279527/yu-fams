#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOK_LEN=${#TOK}"

echo ""
echo "########## A. 入库单：临时挂到有公司的部门后验证 ##########"
IID=$($M -e "select id from assets_in order by id desc limit 1")
OLD_DEPT=$($M -e "select ifnull(department_id,'NULL') from assets_in where id=$IID")
OLD_MGR=$($M -e "select ifnull(manager_id,'NULL') from assets_in where id=$IID")
DEPT=$($M -e "select d.id from department d join company c on d.company_id=c.id where c.id is not null order by d.id limit 1")
STAFF=$($M -e "select id from staff where department_id=$DEPT and status='在职' limit 1")
CNAME=$($M -e "select c.name from department d join company c on d.company_id=c.id where d.id=$DEPT")
echo "assets_in id=$IID old_dept=$OLD_DEPT old_mgr=$OLD_MGR -> dept=$DEPT staff=${STAFF:-none} company=$CNAME"
$M -e "update assets_in set department_id=$DEPT, manager_id=${STAFF:-NULL} where id=$IID"
echo "-- 接口返回 --"
curl -s "$B/assetsIn/selectPage?pageNum=1&pageSize=100" -H "token: $TOK" | python3 -c '
import sys,json
rows=json.load(sys.stdin)["data"]["list"]
for r in rows:
    if r["id"]=='"$IID"':
        print("  in",r["id"],"companyId=",r.get("companyId"),"companyName=",r.get("companyName"),"deptName=",r.get("departmentName"),"manager=",r.get("managerName"))
'
echo "-- 导出内容 --"
curl -s "$B/assetsIn/export?token=$TOK" -o /tmp/in_co.xlsx
python3 - <<'PY'
import zipfile,re
z=zipfile.ZipFile('/tmp/in_co.xlsx')
xml=''
for n in z.namelist():
    if 'sharedStrings' in n or 'worksheets/sheet' in n:
        xml+=z.read(n).decode('utf-8')
texts=re.findall(r'<t[^>]*>([^<]*)</t>',xml)
print('header_company=', '所属公司' in texts, ' value_company=', '"$CNAME"' in texts)
print('  表头:',texts[:14])
PY
rm -f /tmp/in_co.xlsx
echo "-- 还原 --"
if [ "$OLD_DEPT" = "NULL" ]; then $M -e "update assets_in set department_id=NULL where id=$IID"; else $M -e "update assets_in set department_id=$OLD_DEPT where id=$IID"; fi
if [ "$OLD_MGR" = "NULL" ]; then $M -e "update assets_in set manager_id=NULL where id=$IID"; else $M -e "update assets_in set manager_id=$OLD_MGR where id=$IID"; fi
$M -e "select concat('restored: dept=',ifnull(department_id,'NULL'),' mgr=',ifnull(manager_id,'NULL')) from assets_in where id=$IID"

echo ""
echo "########## B. 调拨单：插入待审批测试记录后验证 ##########"
AID=$($M -e "select id from assets where department_id is not null order by id desc limit 1")
FROM_DEPT=$($M -e "select department_id from assets where id=$AID")
FROM_COMPANY=$($M -e "select c.name from department d join company c on d.company_id=c.id where d.id=$FROM_DEPT")
TO_DEPT=$($M -e "select d.id from department d join company c on d.company_id=c.id where d.id<>$FROM_DEPT and c.id<>(select company_id from department where id=$FROM_DEPT) order by d.id limit 1")
TO_COMPANY=$($M -e "select c.name from department d join company c on d.company_id=c.id where d.id=$TO_DEPT")
echo "asset=$AID from_dept=$FROM_DEPT($FROM_COMPANY) -> to_dept=$TO_DEPT($TO_COMPANY)"
$M -e "insert into assets_transfer (assets_id,assets_name,assets_no,transfer_time,transfer_staff_id,transfer_staff_name,from_department_id,from_department_name,from_location,to_department_id,to_department_name,reason,status,create_time,update_time) select a.id,a.name,a.no,now(),1,'测试',d.id,concat(c.name,'-',d.name),a.location,$TO_DEPT,(select name from department where id=$TO_DEPT),'公司字段验证','待审批',now(),now() from assets a join department d on a.department_id=d.id join company c on d.company_id=c.id where a.id=$AID"
TID=$($M -e "select id from assets_transfer where reason='公司字段验证' order by id desc limit 1")
echo "transfer_id=$TID"
echo "-- 列表接口 --"
curl -s "$B/assetsTransfer/selectPage?pageNum=1&pageSize=20" -H "token: $TOK" | python3 -c '
import sys,json
rows=json.load(sys.stdin)["data"]["list"]
for r in rows:
    if r["id"]=='"$TID"':
        print("  tf",r["id"],"fromCompanyName=",r.get("fromCompanyName"),"toCompanyName=",r.get("toCompanyName"),"fromDept=",r.get("fromDepartmentName"),"toDept=",r.get("toDepartmentName"))
'
echo "-- 详情接口 --"
curl -s "$B/assetsTransfer/selectById/$TID" -H "token: $TOK" | python3 -c '
import sys,json
r=json.load(sys.stdin)["data"]
print("  detail fromCompanyName=",r.get("fromCompanyName"),"toCompanyName=",r.get("toCompanyName"))
'
echo "-- 导出内容 --"
curl -s "$B/assetsTransfer/export?token=$TOK" -o /tmp/tf_co.xlsx
python3 - <<'PY'
import zipfile,re
z=zipfile.ZipFile('/tmp/tf_co.xlsx')
xml=''
for n in z.namelist():
    if 'sharedStrings' in n or 'worksheets/sheet' in n:
        xml+=z.read(n).decode('utf-8')
texts=re.findall(r'<t[^>]*>([^<]*)</t>',xml)
print('header_from_company=', '调拨前公司' in texts, ' header_to_company=', '调拨后公司' in texts)
print('value_from_company=', '"$FROM_COMPANY"' in texts, ' value_to_company=', '"$TO_COMPANY"' in texts)
print('  表头:',texts[:20])
PY
rm -f /tmp/tf_co.xlsx
echo "-- 清理并确认资产未变 --"
$M -e "delete from assets_transfer where id=$TID"
$M -e "select concat('transfer_left=',count(*)) from assets_transfer where reason='公司字段验证'"
$M -e "select concat('asset ',id,' dept=',ifnull(department_id,'NULL'),' staff=',ifnull(staff_id,'NULL')) from assets where id=$AID"

echo VERIFY29E2E_DONE
