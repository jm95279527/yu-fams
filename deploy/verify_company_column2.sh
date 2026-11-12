#!/bin/bash
# 「公司」列专项验证 v2（修正 xlsx 解析）
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOKLEN=${#TOK}"

echo ""
echo "########## 1. 模板表头（按列字母逐列对照）##########"
curl -s -o /tmp/tpl_c.xlsx "$B/staff/template?token=$TOK"
python3 - <<'PY'
import zipfile, re
z = zipfile.ZipFile('/tmp/tpl_c.xlsx')
def shared_strings():
    if 'xl/sharedStrings.xml' not in z.namelist(): return []
    xml = z.read('xl/sharedStrings.xml').decode('utf-8')
    out = []
    for si in re.findall(r'<si>(.*?)</si>', xml, re.S):
        out.append(''.join(re.findall(r'<t[^>]*>(.*?)</t>', si, re.S)))
    return out
SS = shared_strings()
sheet = z.read('xl/worksheets/sheet1.xml').decode('utf-8')
def rows_of(xml):
    return re.findall(r'<row[^>]*r="(\d+)"[^>]*>(.*?)</row>', xml, re.S)
def cells(rowxml):
    d = {}
    for m in re.finditer(r'<c\s+r="([A-Z]+)(\d+)"([^>]*)>(.*?)</c>', rowxml, re.S):
        col, attrs, inner = m.group(1), m.group(3), m.group(4)
        if 't="inlineStr"' in attrs:
            v = ''.join(re.findall(r'<t[^>]*>(.*?)</t>', inner, re.S))
        elif 't="s"' in attrs:
            i = re.search(r'<v>(.*?)</v>', inner, re.S)
            v = SS[int(i.group(1))] if i else ''
        else:
            v = (re.search(r'<v>(.*?)</v>', inner, re.S) or [None,''])[1] if re.search(r'<v>(.*?)</v>', inner, re.S) else ''
        d[col] = v
    return d
rs = rows_of(sheet)
hdr = cells(rs[0][1])
cols = sorted(hdr.keys(), key=lambda c: (len(c), c))
print("  模板总行数 =", len(rs), " 表头列数 =", len(cols))
for i, c in enumerate(cols, 1):
    print("   %2d. %-2s = %s%s" % (i, c, hdr[c], "    <<<<<< 公司列" if hdr[c] == '公司' else ""))
print("  >>> 含「公司」列：", '公司' in hdr.values())
ci = cols.index([c for c in cols if hdr[c] == '公司'][0])
print("  >>> 位置：第 %d 列，前一列=%s，后一列=%s" % (ci+1, hdr[cols[ci-1]], hdr[cols[ci+1]]))
print()
print("  示例行（按列字母输出，空列跳过）：")
for r, xml in rs[1:]:
    cs = cells(xml)
    print("   行%s: %s" % (r, '  '.join("%s=%s" % (c, cs[c]) for c in cols if cs.get(c))))
PY

echo ""
echo "########## 2. 跨公司同名部门（用于消歧对照）##########"
$M -e "select concat('  ',c.name,' - ',d.name,' = departmentId ',d.id) from department d join company c on d.company_id=c.id where d.name in (select name from department group by name having count(*)>1) order by d.name, c.name"
$M -e "select concat(c.name,'|',d.name,'|',d.id) from department d join company c on d.company_id=c.id where d.name in (select name from department group by name having count(*)>1) order by d.name, c.name" > /tmp/pairs.txt

echo ""
echo "########## 3. 造文件并导入（核心：同名部门按公司区分）##########"
python3 - <<'PY'
import zipfile
pairs = []
for line in open('/tmp/pairs.txt', encoding='utf-8'):
    line = line.strip()
    if not line: continue
    p = line.split('|')
    if len(p) == 3: pairs.append((p[0], p[1], p[2]))
print("  同名部门对照：", pairs)
hdr = ["工号","姓名","账号","性别","电话","邮箱","身份证号","公司","部门","职位","学历","入职日期","状态","籍贯","家庭住址","紧急联系人","紧急联系电话","备注"]
rows = []
if len(pairs) >= 2:
    (c1,d1,id1), (c2,d2,id2) = pairs[0], pairs[1]
    print("  用例：甲→%s/%s(期望id=%s)  乙→%s/%s(期望id=%s)  同名部门=%s/%s" % (c1,d1,id1,c2,d2,id2,d1,d2))
    rows.append(["ZZCC1","公司列甲","zzcc_a","","","","", c1, d1, "", "", "", "在职", "", "", "", "", "公司+部门 → 期望 departmentId=%s" % id1])
    rows.append(["ZZCC2","公司列乙","zzcc_b","","","","", c2, d2, "", "", "", "", "", "", "", "", "公司+部门 → 期望 departmentId=%s（同名部门）" % id2])
    rows.append(["ZZCC3","公司列丙","zzcc_c","","","","", "", d1, "", "", "", "", "", "", "", "", "只填部门 → 按部门名匹配"])
    rows.append(["ZZCC4","公司列丁","zzcc_d","","","","", "不存在的公司XX", d1, "", "", "", "", "", "", "", "", "公司不存在 → 期望失败"])
    rows.append(["ZZCC5","公司列戊","zzcc_e","","","","", c1, "", "", "", "", "", "", "", "", "只填公司 → 期望失败"])
else:
    print("  !! 没有跨公司同名部门，改用单公司用例")
    rows.append(["ZZCC1","公司列甲","zzcc_a","","","","", pairs[0][0] if pairs else "", pairs[0][1] if pairs else "", "", "", "", "在职", "", "", "", "", "公司+部门"])
    rows.append(["ZZCC5","公司列戊","zzcc_e","","","","", pairs[0][0] if pairs else "", "", "", "", "", "", "", "", "", "只填公司 → 期望失败"])
def esc(s): return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
def rowstr(i, vals):
    out = ''
    for j, v in enumerate(vals):
        if v == "": continue
        out += '<c r="%s%d" t="inlineStr"><is><t>%s</t></is></c>' % (chr(65+j), i, esc(v))
    return '<row r="%d">%s</row>' % (i, out)
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
print("  XLSX_OK，用例数 =", len(rows))
PY
echo "  -- 导入返回 --"
curl -s -X POST $B/staff/import -H "token: $TOK" -F "file=@/tmp/staff_ccc.xlsx"; echo

echo ""
echo "########## 4. 导入结果比对 ##########"
$M -e "select concat('  ',s.emp_no,' | ',s.name,' | 公司=',ifnull(c.name,'(空)'),' | 部门=',ifnull(d.name,'(空)'),' | departmentId=',ifnull(s.department_id,'NULL')) from staff s left join department d on s.department_id=d.id left join company c on d.company_id=c.id where s.username like 'zzcc_%' order by s.id"
echo "  （ZZCC4/ZZCC5 应不在列表中，说明这两行被正确拦截）"

echo ""
echo "########## 5. 清理 ##########"
$M -e "delete from staff where username like 'zzcc_%'"
echo "  剩余测试员工 = $($M -e "select count(*) from staff where username like 'zzcc_%'")  员工总数 = $($M -e "select count(*) from staff")"
echo VERIFY_CC2_DONE
