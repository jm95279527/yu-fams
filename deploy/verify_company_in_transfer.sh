#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOK_LEN=${#TOK}"

echo ""
echo "########## A. 资产入库：公司输出与筛选 ##########"
$M -e "select concat('assets_in 总数=',count(*)) from assets_in"
CID=$($M -e "select d.company_id from assets_in i join department d on i.department_id=d.id where d.company_id is not null order by i.id desc limit 1")
echo "sample_company_id=${CID:-none}"
$M -e "select concat(i.id,' | company=',ifnull(c.name,'(无)'),' | dept=',ifnull(d.name,'(无)'),' | manager=',ifnull(s.name,'(无)')) from assets_in i left join department d on i.department_id=d.id left join company c on d.company_id=c.id left join staff s on i.manager_id=s.id order by i.id desc limit 5"
echo "-- 分页接口返回 --"
curl -s "$B/assetsIn/selectPage?pageNum=1&pageSize=100" -H "token: $TOK" | python3 -c '
import sys,json
rows=json.load(sys.stdin)["data"]["list"]
print("rows=",len(rows))
for r in rows[:5]:
    print("  in",r["id"],"companyId=",r.get("companyId"),"companyName=",r.get("companyName"),"deptName=",r.get("departmentName"))
'
if [ -n "$CID" ]; then
  echo "-- 按公司筛选 --"
  curl -s "$B/assetsIn/selectPage?pageNum=1&pageSize=200&companyId=$CID" -H "token: $TOK" | python3 -c '
import sys,json
rows=json.load(sys.stdin)["data"]["list"]
bad=[r["id"] for r in rows if r.get("companyId")!='"$CID"']
print("filtered_rows=",len(rows),"  mismatched=",bad)
'
  echo "-- SQL 对照 --"
  $M -e "select concat('sql_count=',count(*)) from assets_in i join department d on i.department_id=d.id where d.company_id=$CID"
fi
echo "-- 导出表头 --"
curl -s "$B/assetsIn/export?token=$TOK" -o /tmp/assets_in_company.xlsx
python3 - <<'PY'
import zipfile,re
z=zipfile.ZipFile('/tmp/assets_in_company.xlsx')
xml=''
for n in z.namelist():
    if 'sharedStrings' in n or 'worksheets/sheet' in n:
        xml+=z.read(n).decode('utf-8')
texts=re.findall(r'<t[^>]*>([^<]*)</t>',xml)
print('headers_found_company=', ('所属公司' in texts))
print('  表头:',texts[:12])
PY
rm -f /tmp/assets_in_company.xlsx

echo ""
echo "########## B. 资产调拨：调拨前/后公司 ##########"
$M -e "select concat('assets_transfer 总数=',count(*)) from assets_transfer"
$M -e "select concat(t.id,' | from_dept=',ifnull(t.from_department_name,'(无)'),' | to_dept=',ifnull(t.to_department_name,'(无)')) from assets_transfer t order by t.id desc limit 5"
echo "-- 分页接口返回 --"
curl -s "$B/assetsTransfer/selectPage?pageNum=1&pageSize=20" -H "token: $TOK" | python3 -c '
import sys,json
rows=json.load(sys.stdin)["data"]["list"]
print("rows=",len(rows))
for r in rows[:5]:
    print("  tf",r["id"],"fromCompany=",r.get("fromCompanyName"),"toCompany=",r.get("toCompanyName"),"fromDept=",r.get("fromDepartmentName"),"toDept=",r.get("toDepartmentName"))
'
echo "-- 导出表头 --"
curl -s "$B/assetsTransfer/export?token=$TOK" -o /tmp/assets_tf_company.xlsx
python3 - <<'PY'
import zipfile,re
z=zipfile.ZipFile('/tmp/assets_tf_company.xlsx')
xml=''
for n in z.namelist():
    if 'sharedStrings' in n or 'worksheets/sheet' in n:
        xml+=z.read(n).decode('utf-8')
texts=re.findall(r'<t[^>]*>([^<]*)</t>',xml)
print('headers_found_from_company=', ('调拨前公司' in texts))
print('headers_found_to_company=', ('调拨后公司' in texts))
print('  表头:',texts[:20])
PY
rm -f /tmp/assets_tf_company.xlsx

echo ""
echo "########## C. 二维码页面显示选项含公司 ##########"
curl -s $B/sysConfig/public | python3 -c '
import sys,json
d=json.load(sys.stdin)["data"]
print("scanFields=",d.get("scanFields"))
print("contains_company=","company" in d.get("scanFields",[]))
'

echo VERIFY29_DONE
