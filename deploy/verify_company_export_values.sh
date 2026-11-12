#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')

echo "########## A. 入库导出值 ##########"
IID=$($M -e "select id from assets_in order by id desc limit 1")
DEPT=$($M -e "select d.id from department d join company c on d.company_id=c.id order by d.id limit 1")
CNAME=$($M -e "select c.name from department d join company c on d.company_id=c.id where d.id=$DEPT")
$M -e "update assets_in set department_id=$DEPT where id=$IID"
curl -s "$B/assetsIn/export?token=$TOK" -o /tmp/in_co.xlsx
python3 - "$CNAME" <<'PY'
import sys,zipfile,re
want=sys.argv[1]
z=zipfile.ZipFile('/tmp/in_co.xlsx')
xml=''
for n in z.namelist():
    if 'sharedStrings' in n or 'worksheets/sheet' in n:
        xml+=z.read(n).decode('utf-8')
texts=re.findall(r'<t[^>]*>([^<]*)</t>',xml)
print('want_company=',want,' found=', want in texts)
print('all_texts=',texts)
PY
rm -f /tmp/in_co.xlsx
$M -e "update assets_in set department_id=NULL where id=$IID"

echo ""
echo "########## B. 调拨导出值 ##########"
AID=$($M -e "select id from assets where department_id is not null order by id desc limit 1")
FROM_DEPT=$($M -e "select department_id from assets where id=$AID")
FROM_COMPANY=$($M -e "select c.name from department d join company c on d.company_id=c.id where d.id=$FROM_DEPT")
TO_DEPT=$($M -e "select d.id from department d join company c on d.company_id=c.id where d.id<>$FROM_DEPT and c.id<>(select company_id from department where id=$FROM_DEPT) order by d.id limit 1")
TO_COMPANY=$($M -e "select c.name from department d join company c on d.company_id=c.id where d.id=$TO_DEPT")
$M -e "insert into assets_transfer (assets_id,assets_name,assets_no,transfer_time,transfer_staff_id,transfer_staff_name,from_department_id,from_department_name,from_location,to_department_id,to_department_name,reason,status,create_time,update_time) select a.id,a.name,a.no,now(),1,'测试',d.id,concat(c.name,'-',d.name),a.location,$TO_DEPT,(select name from department where id=$TO_DEPT),'公司字段值验证','待审批',now(),now() from assets a join department d on a.department_id=d.id join company c on d.company_id=c.id where a.id=$AID"
TID=$($M -e "select id from assets_transfer where reason='公司字段值验证' order by id desc limit 1")
curl -s "$B/assetsTransfer/export?token=$TOK" -o /tmp/tf_co.xlsx
python3 - "$FROM_COMPANY" "$TO_COMPANY" <<'PY'
import sys,zipfile,re
z=zipfile.ZipFile('/tmp/tf_co.xlsx')
xml=''
for n in z.namelist():
    if 'sharedStrings' in n or 'worksheets/sheet' in n:
        xml+=z.read(n).decode('utf-8')
texts=re.findall(r'<t[^>]*>([^<]*)</t>',xml)
print('from_company=',sys.argv[1],' found=',sys.argv[1] in texts)
print('to_company=',sys.argv[2],' found=',sys.argv[2] in texts)
PY
rm -f /tmp/tf_co.xlsx
$M -e "delete from assets_transfer where id=$TID"
echo "cleaned transfer_id=$TID"
$M -e "select concat('transfer_left=',count(*)) from assets_transfer where reason='公司字段值验证'"
echo VERIFY_VALUES_DONE
