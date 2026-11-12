#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOK_LEN=${#TOK}"

echo ""
echo "########## A. 库中公司-部门-员工关系样例 ##########"
$M -e "select concat('asset=',a.id,' | company=',ifnull(c.name,'(无)'),' | dept=',ifnull(d.name,'(无)'),' | staff=',ifnull(s.name,'(无)'),' | staff_dept=',ifnull(s.department_id,'-')) from assets a left join department d on a.department_id=d.id left join company c on d.company_id=c.id left join staff s on a.staff_id=s.id where a.department_id is not null order by a.id limit 5"

echo ""
echo "########## B. 资产分页接口返回所属公司 ##########"
AID=$($M -e "select id from assets where department_id is not null order by id desc limit 1")
CID=$($M -e "select d.company_id from assets a join department d on a.department_id=d.id where a.id=$AID")
CNAME=$($M -e "select name from company where id=$CID")
echo "sample asset=$AID companyId=$CID companyName=$CNAME"
curl -s "$B/assets/selectPage?pageNum=1&pageSize=10" -H "token: $TOK" | python3 -c '
import sys,json
rows=json.load(sys.stdin)["data"]["list"]
print("rows=",len(rows))
for r in rows[:5]:
    print("  asset",r["id"],"companyId=",r.get("companyId"),"companyName=",r.get("companyName"),"deptName=",r.get("departmentName"))
'

echo ""
echo "-- 按公司筛选（应只返回该公司资产）--"
curl -s "$B/assets/selectPage?pageNum=1&pageSize=200&companyId=$CID" -H "token: $TOK" | python3 -c '
import sys,json
rows=json.load(sys.stdin)["data"]["list"]
bad=[r["id"] for r in rows if r.get("companyId")!='"$CID"']
print("filtered_rows=",len(rows),"  mismatched=",bad)
if rows: print("  first:",rows[0]["companyName"],"/",rows[0]["departmentName"])
'
echo "-- SQL 对照（该公司资产数）--"
$M -e "select concat('sql_count=',count(*)) from assets a join department d on a.department_id=d.id where d.company_id=$CID"

echo ""
echo "########## C. 扫码接口返回所属公司 ##########"
curl -s "$B/qr/asset/$AID" | python3 -c '
import sys,json
d=json.load(sys.stdin)["data"]
print("companyName=",d.get("companyName")," departmentName=",d.get("departmentName"))
'

echo ""
echo "########## D. 导出包含所属公司列 ##########"
curl -s "$B/assets/export?token=$TOK" -o /tmp/assets_company_export.xlsx
python3 - <<'PY'
import zipfile,re
z=zipfile.ZipFile('/tmp/assets_company_export.xlsx')
names=z.namelist()
xml=''
for n in names:
    if n.startswith('xl/sharedStrings'):
        xml+=z.read(n).decode('utf-8')
if not xml:
    for n in names:
        if 'worksheets/sheet' in n:
            xml+=z.read(n).decode('utf-8')
found='所属公司' in xml
print('headers_found_company=',found)
if found:
    import re
    texts=re.findall(r'<t[^>]*>([^<]*)</t>',xml)
    idx=texts.index('所属公司') if '所属公司' in texts else -1
    print('  表头:',texts[:18])
PY
rm -f /tmp/assets_company_export.xlsx

echo ""
echo "########## E. 公开配置 scanFields 含 company ##########"
curl -s $B/sysConfig/public | python3 -c '
import sys,json
d=json.load(sys.stdin)["data"]
print("scanFields=",d.get("scanFields"))
print("contains_company=","company" in d.get("scanFields",[]))
'

echo VERIFY28_DONE
