#!/bin/bash
# 需求14 验证：员工批量导入 / 一键离职 / 离职标志
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOKLEN=${#TOK}"
TOD=$(date +%F)

echo ""
echo "########## A. 菜单归属 ##########"
$M -e "select concat('  id=',id,' parent=',parent_id,' sort=',sort,' ',name) from sys_menu where id in (20,21,22,23,24,43,55) order by parent_id,sort"

echo ""
echo "########## B. 员工导入模板 ##########"
CODE=$(curl -s -o /tmp/stafftpl.xlsx -w '%{http_code}' "$B/staff/template?token=$TOK")
echo "  http=$CODE  magic=$(head -c 2 /tmp/stafftpl.xlsx)  size=$(stat -c%s /tmp/stafftpl.xlsx)"

echo ""
echo "########## C. 员工批量导入 ##########"
python3 - <<'PY'
import zipfile
hdr=["工号","姓名","账号","性别","电话","邮箱","身份证号","部门","职位","学历","入职日期","状态","籍贯","家庭住址","紧急联系人","紧急联系电话","备注"]
rows=[
 ["ZZT001","测试员工甲","zztest_a","男","13800000011","","","赫玛科技-财务中心","会计","本科","2026-01-05","在职","","","","",""],
 ["ZZT002","测试员工乙","","女","","","","财务中心","出纳","","2026-02-01","","","","","","账号留空用工号"],
 ["ZZT003","测试员工丙","zztest_c","男","","","","不存在的部门","","","","在职","","","","","应失败"],
 ["","","zztest_d","","","","","","","","","","","","","","应失败-缺姓名"],
]
def esc(s): return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
def rowstr(i,vals):
    cells=''
    for j,v in enumerate(vals):
        if v=="" : continue
        cells+='<c r="%s%d" t="inlineStr"><is><t>%s</t></is></c>'%(chr(65+j) if j<26 else 'A'+chr(65+j-26),i,esc(v))
    return '<row r="%d">%s</row>'%(i,cells)
sheet='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>'
sheet+=rowstr(1,hdr)
for i,r in enumerate(rows,2): sheet+=rowstr(i,r)
sheet+='</sheetData></worksheet>'
ct='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>'
rels='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'
wb='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>'
wbr='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>'
z=zipfile.ZipFile("/tmp/staff14.xlsx","w",zipfile.ZIP_DEFLATED)
z.writestr("[Content_Types].xml",ct); z.writestr("_rels/.rels",rels)
z.writestr("xl/workbook.xml",wb); z.writestr("xl/_rels/workbook.xml.rels",wbr)
z.writestr("xl/worksheets/sheet1.xml",sheet); z.close()
print("XLSX_OK")
PY
echo "  -- 首次导入 --"
curl -s -X POST $B/staff/import -H "token: $TOK" -F "file=@/tmp/staff14.xlsx"; echo
echo "  -- 库中结果 --"
$M -e "select concat('  ',s.id,' | ',s.emp_no,' | ',s.name,' | 账号=',s.username,' | 部门=',ifnull(d.name,'-'),'(',ifnull(d.company_id,'-'),')',' | 状态=',s.status,' | pwd=',ifnull(s.password,'-')) from staff s left join department d on s.department_id=d.id where s.username like 'zztest%' or s.emp_no like 'ZZT%' order by s.id"
echo "  -- 密码是否为默认密码123的MD5 --"
$M -e "select concat('  md5(123)=',md5('123'))"
echo "  -- 重复导入（应全部跳过）--"
curl -s -X POST $B/staff/import -H "token: $TOK" -F "file=@/tmp/staff14.xlsx"; echo

echo ""
echo "########## D. 一键离职 ##########"
IDA=$($M -e "select id from staff where username='zztest_a' limit 1")
IDB=$($M -e "select id from staff where username='ZZT002' limit 1")
echo "  IDA=$IDA IDB=$IDB"
echo "  -- 单个离职 IDA --"
curl -s -X PUT $B/staff/leave/$IDA -H "token: $TOK"; echo
$M -e "select concat('  ',name,' status=',status,' leave_date=',ifnull(leave_date,'NULL')) from staff where id=$IDA"
echo "  -- 重复离职（应报错）--"
curl -s -X PUT $B/staff/leave/$IDA -H "token: $TOK"; echo
echo "  -- 批量离职 [IDA(已离职), IDB] --"
curl -s -X PUT $B/staff/leave/batch -H "token: $TOK" -H 'Content-Type: application/json' -d "[$IDA,$IDB]"; echo
$M -e "select concat('  ',name,' status=',status,' leave_date=',ifnull(leave_date,'NULL')) from staff where id in ($IDA,$IDB)"

echo ""
echo "########## E. 离职标志（资产台账责任人）##########"
curl -s -X POST $B/assets/add -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"name\":\"测试离职标志资产\",\"category\":\"测试分类\",\"no\":\"ZZTEST-14\",\"num\":1,\"date\":\"$TOD\",\"status\":\"正常\",\"staffId\":$IDA,\"location\":\"测试\"}" > /dev/null
echo "  -- 台账里的责任人（应带「（离职）」）--"
curl -s "$B/assets/selectPage?pageNum=1&pageSize=5&name=测试离职标志资产" -H "token: $TOK" \
 | python3 -c 'import sys,json
d=json.load(sys.stdin)["data"]["list"]
for x in d: print("   id=%s 资产=%s 责任人=%s"%(x["id"],x["name"],x.get("staffName")))'
echo "  -- 在职员工不应带标志（另建一个在职员工确认）--"
IDC=$($M -e "select id from staff where username='ZZT002' limit 1")
echo "  （IDB 已离职，故其台账责任人应带标志；跳过）"
echo "  -- 员工下拉/员工列表的姓名不应被污染（应仍是纯姓名）--"
curl -s "$B/staff/selectAll" -H "token: $TOK" | python3 -c 'import sys,json
d=json.load(sys.stdin)["data"]
for x in d:
    if (x.get("username") or "").startswith("zztest") or str(x.get("empNo") or "").startswith("ZZT"):
        print("   id=%s name=%r status=%s"%(x["id"],x["name"],x["status"]))'
echo "  -- 维修/借用/入库/报废/调拨/盘点 接口 SQL 语法自检（应均 200）--"
for u in /assetsRepair/selectPage /assetsReceive/selectPage /assetsIn/selectPage /assetsScrap/selectPage /assetsTransfer/selectPage /assetsInventory/selectPage; do
  printf "   %-32s -> %s\n" "$u" "$(curl -s -o /dev/null -w '%{http_code}' "$B$u?pageNum=1&pageSize=5" -H "token: $TOK")"
done
printf "   %-32s -> %s\n" "/assetsInventory/items/1" "$(curl -s -o /dev/null -w '%{http_code}' "$B/assetsInventory/items/1" -H "token: $TOK")"

echo ""
echo "########## F. 清理 ##########"
$M -e "delete from assets where no='ZZTEST-14'"
for u in zztest_a ZZT002 zztest_c zztest_d; do
  $M -e "delete from staff where username='$u'"
done
$M -e "delete from staff where emp_no like 'ZZT%'"
echo "  staff_left=$($M -e "select count(*) from staff where username like 'zztest%' or emp_no like 'ZZT%'")"
echo "  asset_left=$($M -e "select count(*) from assets where no='ZZTEST-14'")"
echo "  staff_total=$($M -e "select count(*) from staff")  assets_total=$($M -e "select count(*) from assets")"
echo VERIFY14_DONE
