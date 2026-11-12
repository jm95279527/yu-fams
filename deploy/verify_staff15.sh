#!/bin/bash
# 需求15 验证：员工导入模板新增「公司」列 + 公司维度部门匹配
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOKLEN=${#TOK}"

echo ""
echo "########## A. 模板是否含「公司」列 ##########"
CODE=$(curl -s -o /tmp/stafftpl15.xlsx -w '%{http_code}' "$B/staff/template?token=$TOK")
echo "  http=$CODE magic=$(head -c 2 /tmp/stafftpl15.xlsx) size=$(stat -c%s /tmp/stafftpl15.xlsx)"
python3 - <<'PY'
import zipfile, re
z = zipfile.ZipFile('/tmp/stafftpl15.xlsx')
parts = [n for n in z.namelist() if '公司' in z.read(n).decode('utf-8', 'ignore')]
print("  含「公司」的部件:", parts)
for n in z.namelist():
    if n.endswith('sharedStrings.xml'):
        s = z.read(n).decode('utf-8')
        items = re.findall(r'<t[^>]*>([^<]*)</t>', s)
        print("  模板表头共 %d 列:" % len(items))
        print("   ", items)
        print("  是否包含「公司」列:", '公司' in items,
              " 位置(0基):", items.index('公司') if '公司' in items else -1)
PY

echo ""
echo "########## B. 按「公司」维度匹配部门 ##########"
echo "  -- 相关部门的真实 id --"
$M -e "select concat('   公司=',c.name,' 部门=',d.name,' -> departmentId=',d.id) from department d join company c on d.company_id=c.id where d.name='财务中心' order by c.name"
python3 - <<'PY'
import zipfile
hdr=["工号","姓名","账号","性别","电话","邮箱","身份证号","公司","部门","职位","学历","入职日期","状态","籍贯","家庭住址","紧急联系人","紧急联系电话","备注"]
rows=[
 ["ZZC001","公司验证甲","zzc_a","男","","","","赫玛科技","财务中心","","","","在职","","","","",""],
 ["ZZC002","公司验证乙","zzc_b","女","","","","堡格丽","财务中心","","","","","","","","",""],
 ["ZZC003","公司验证丙","zzc_c","","","","","不存在的公司","财务中心","","","","","","","","",""],
 ["ZZC004","公司验证丁","zzc_d","","","","","赫玛科技","","","","","","","","","",""],
 ["ZZC005","公司验证戊","zzc_e","","","","","","财务中心","","","","","","","","",""],
]
def esc(s): return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
def rowstr(i,vals):
    cells=''
    for j,v in enumerate(vals):
        if v=="": continue
        cells+='<c r="%s%d" t="inlineStr"><is><t>%s</t></is></c>'%(chr(65+j),i,esc(v))
    return '<row r="%d">%s</row>'%(i,cells)
sheet='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>'
sheet+=rowstr(1,hdr)
for i,r in enumerate(rows,2): sheet+=rowstr(i,r)
sheet+='</sheetData></worksheet>'
ct='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>'
rels='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'
wb='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>'
wbr='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>'
z=zipfile.ZipFile("/tmp/staff15.xlsx","w",zipfile.ZIP_DEFLATED)
z.writestr("[Content_Types].xml",ct); z.writestr("_rels/.rels",rels)
z.writestr("xl/workbook.xml",wb); z.writestr("xl/_rels/workbook.xml.rels",wbr)
z.writestr("xl/worksheets/sheet1.xml",sheet); z.close()
print("  XLSX_OK")
PY
echo "  -- 导入 --"
curl -s -X POST $B/staff/import -H "token: $TOK" -F "file=@/tmp/staff15.xlsx"; echo
echo "  -- 库中结果 --"
$M -e "select concat('   ',s.emp_no,' | ',s.name,' | 账号=',s.username,' | 公司=',ifnull(c.name,'-'),' | 部门=',ifnull(d.name,'-'),' | departmentId=',ifnull(s.department_id,'NULL')) from staff s left join department d on s.department_id=d.id left join company c on d.company_id=c.id where s.username like 'zzc_%' order by s.id"

echo ""
echo "########## C. 清理 ##########"
$M -e "delete from staff where username like 'zzc_%'"
echo "  staff_left=$($M -e "select count(*) from staff where username like 'zzc_%'")  staff_total=$($M -e "select count(*) from staff")"
echo VERIFY15_DONE
