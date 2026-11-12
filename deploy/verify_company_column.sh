#!/bin/bash
# 专项验证：员工导入模板的「公司」列是否已生效（模板列 + 导入消歧）
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOKLEN=${#TOK}"

echo ""
echo "########## 1. 下载模板并解出真实表头 ##########"
CODE=$(curl -s -o /tmp/tpl_c.xlsx -w '%{http_code}' "$B/staff/template?token=$TOK")
echo "  HTTP=$CODE  magic=$(head -c 2 /tmp/tpl_c.xlsx)  size=$(stat -c%s /tmp/tpl_c.xlsx)"
python3 - <<'PY'
import zipfile, re
z = zipfile.ZipFile('/tmp/tpl_c.xlsx')
shared = []
if 'xl/sharedStrings.xml' in z.namelist():
    shared = re.findall(r'<si>(?:<t[^>]*>(.*?)</t>|<r><t[^>]*>(.*?)</t></r>)+?</si>', z.read('xl/sharedStrings.xml').decode('utf-8'))
    shared = [a or b for a, b in shared]
sheet = z.read('xl/worksheets/sheet1.xml').decode('utf-8')
rows = re.findall(r'<row[^>]*r="(\d+)"[^>]*>(.*?)</row>', sheet, re.S)
def cells(rowxml):
    out = []
    for m in re.finditer(r'<c r="([A-Z]+)(\d+)"(?:[^>]*t="(\w+)")?[^>]*>(.*?)</c>', rowxml, re.S):
        col, r, t, inner = m.group(1), m.group(2), m.group(3), m.group(4)
        if t == 'inlineStr':
            v = ''.join(re.findall(r'<t[^>]*>(.*?)</t>', inner, re.S))
        else:
            idx = re.search(r'<v>(.*?)</v>', inner, re.S)
            v = shared[int(idx.group(1))] if idx and idx.group(1).isdigit() and int(idx.group(1)) < len(shared) else ''
        out.append((col, v))
    return out
print("  xlsx 共 %d 行" % len(rows))
for r, xml in rows:
    cs = cells(xml)
    if r == '1':
        print("  表头（%d 列）：" % len(cs))
        for i, (c, v) in enumerate(cs, 1):
            mark = "   <== 就是这一列" if v == '公司' else ""
            print("    %2d. %-3s %s%s" % (i, c, v, mark))
        print("  >>> 是否含「公司」列：", any(v == '公司' for _, v in cs))
        print("  >>> 「公司」在第 %d 列，紧邻其后是：%s" % (
            [i for i, (c, v) in enumerate(cs, 1) if v == '公司'][0],
            cs[[i for i, (c, v) in enumerate(cs) if v == '公司'][0] + 1][1] if True else ''))
    else:
        print("  示例行 %s：%s" % (r, ' | '.join(v for _, v in cs)))
PY

echo ""
echo "########## 2. 准备验证数据：找出跨公司同名的部门 ##########"
$M -e "select concat('  公司=',c.name,'  部门=',d.name,'  -> departmentId=',d.id) from department d join company c on d.company_id=c.id where d.name in (select name from department group by name having count(*) > 1) order by d.name, c.name" > /tmp/dup.txt
cat /tmp/dup.txt
$M -e "select concat('  公司=',c.name,'  部门=',d.name,'  -> departmentId=',d.id) from department d join company c on d.company_id=c.id where d.name in (select name from department group by name having count(*) > 1) order by d.name, c.name" > /tmp/dupdept.tsv

echo ""
echo "########## 3. 造导入文件（重点测「公司」列消歧）##########"
python3 - <<'PY'
import zipfile
pairs = []
for line in open('/tmp/dupdept.tsv', encoding='utf-8'):
    line = line.strip()
    if not line: continue
    comp = line.split('  公司=')[1].split('  部门=')[0]
    dept = line.split('  部门=')[1].split('  ->')[0]
    pairs.append((comp, dept))
print("  同名部门对：", pairs)
hdr = ["工号","姓名","账号","性别","电话","邮箱","身份证号","公司","部门","职位","学历","入职日期","状态","籍贯","家庭住址","紧急联系人","紧急联系电话","备注"]
rows = []
if len(pairs) >= 2:
    c1, d1 = pairs[0]
    c2, d2 = pairs[1]
    rows.append(["ZZCC1","公司列甲","zzcc_a","","","","", c1, d1, "", "", "", "在职", "", "", "", "", "填了公司+部门→应在 %s 下" % c1])
    rows.append(["ZZCC2","公司列乙","zzcc_b","","","","", c2, d2, "", "", "", "", "", "", "", "", "填了公司+部门→应在 %s 下（同名部门）" % c2])
    rows.append(["ZZCC3","公司列丙","zzcc_c","","","","", "", d1, "", "", "", "", "", "", "", "", "只填部门→按部门名匹配"])
    rows.append(["ZZCC4","公司列丁","zzcc_d","","","","", "不存在的公司XX", d1, "", "", "", "", "", "", "", "", "公司不存在→应失败"])
    rows.append(["ZZCC5","公司列戊","zzcc_e","","","","", c1, "", "", "", "", "", "", "", "", "只填公司→应失败"])
else:
    print("  !! 未找到跨公司同名部门，跳过消歧用例")
def esc(s): return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
def rowstr(i, vals):
    cells = ''
    for j, v in enumerate(vals):
        if v == "": continue
        cells += '<c r="%s%d" t="inlineStr"><is><t>%s</t></is></c>' % (chr(65+j), i, esc(v))
    return '<row r="%d">%s</row>' % (i, cells)
sheet = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>'
sheet += rowstr(1, hdr)
for i, r in enumerate(rows, 2): sheet += rowstr(i, r)
sheet += '</sheetData></worksheet>'
ct = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>'
rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'
wb = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>'
wbr = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>'
z = zipfile.ZipFile('/tmp/staff_ccc.xlsx', 'w', zipfile.ZIP_DEFLATED)
z.writestr("[Content_Types].xml", ct); z.writestr("_rels/.rels", rels)
z.writestr("xl/workbook.xml", wb); z.writestr("xl/_rels/workbook.xml.rels", wbr)
z.writestr("xl/worksheets/sheet1.xml", sheet); z.close()
print("  XLSX_OK，共 %d 条用例" % len(rows))
PY

echo ""
echo "########## 4. 执行导入 ##########"
curl -s -X POST $B/staff/import -H "token: $TOK" -F "file=@/tmp/staff_ccc.xlsx"; echo

echo ""
echo "########## 5. 库中结果 ##########"
$M -e "select concat('  ',s.emp_no,' | ',s.name,' | 公司=',ifnull(c.name,'(空)'),' | 部门=',ifnull(d.name,'(空)'),' | departmentId=',ifnull(s.department_id,'NULL')) from staff s left join department d on s.department_id=d.id left join company c on d.company_id=c.id where s.username like 'zzcc_%' order by s.id"
echo "  -- 期望对照：填了公司的应落在对应公司下，同名部门不能串 --"
$M -e "select concat('  ',c.name,' - ',d.name,' = id ',d.id) from department d join company c on d.company_id=c.id where d.name in (select name from department group by name having count(*) > 1) order by d.name, c.name"

echo ""
echo "########## 6. 清理 ##########"
$M -e "delete from staff where username like 'zzcc_%'"
echo "  剩余测试员工 = $($M -e "select count(*) from staff where username like 'zzcc_%'")"
echo "  员工总数 = $($M -e "select count(*) from staff")"
echo VERIFY_COMPANY_COL_DONE
