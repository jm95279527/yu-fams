#!/bin/bash
set -e
API=http://127.0.0.1:89
DB="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -B"

TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')

echo "=== 字段标签 ==="
$DB -e "select field_key,label from asset_field_config where field_key in ('name','category','no','companyName','departmentName','staffName','location') order by sort_num" 2>/dev/null

L_NAME=$($DB -e "select label from asset_field_config where field_key='name'" 2>/dev/null)
L_CAT=$($DB -e "select label from asset_field_config where field_key='category'" 2>/dev/null)
L_NO=$($DB -e "select label from asset_field_config where field_key='no'" 2>/dev/null)
L_COMPANY=$($DB -e "select label from asset_field_config where field_key='companyName'" 2>/dev/null)
L_DEPT=$($DB -e "select label from asset_field_config where field_key='departmentName'" 2>/dev/null)
L_STAFF=$($DB -e "select label from asset_field_config where field_key='staffName'" 2>/dev/null)
L_LOC=$($DB -e "select label from asset_field_config where field_key='location'" 2>/dev/null)

IFS=$'\t' read -r COMPANY DEPT STAFF < <($DB -e "select c.name,d.name,s.name from staff s join department d on s.department_id=d.id join company c on d.company_id=c.id where s.status='在职' and d.company_id is not null order by s.id limit 1;" 2>/dev/null | head -n 1)
echo "公司=$COMPANY 部门=$DEPT 使用人=$STAFF"

echo "=== 模板表头 ==="
curl -s -o /tmp/asset_template.xlsx "$API/assets/template?token=$TOKEN"
python3 - <<'PY'
import zipfile, re
z = zipfile.ZipFile('/tmp/asset_template.xlsx')
xml = z.read('xl/sharedStrings.xml').decode('utf-8')
print([m for m in re.findall(r'<t[^>]*>(.*?)</t>', xml)])
PY

echo "=== 生成测试 Excel ==="
L_NAME="$L_NAME" L_CAT="$L_CAT" L_NO="$L_NO" L_COMPANY="$L_COMPANY" L_DEPT="$L_DEPT" L_STAFF="$L_STAFF" L_LOC="$L_LOC" \
COMPANY="$COMPANY" DEPT="$DEPT" STAFF="$STAFF" python3 - <<'PY'
import os, zipfile
from xml.sax.saxutils import escape
E = os.environ
headers = [E['L_NAME'], E['L_CAT'], E['L_NO'], E['L_COMPANY'], E['L_DEPT'], E['L_STAFF'], E['L_LOC']]
rows = [
    ['导入测试资产A', '办公设备', 'TESTIMP0001', E['COMPANY'], E['DEPT'], E['STAFF'], '测试地点'],
    ['导入测试资产B', '办公设备', 'TESTIMP0002', E['COMPANY'], '不存在部门XYZ', '', '测试地点'],
    ['导入测试资产C', '办公设备', 'TESTIMP0003', E['COMPANY'], '', '', '测试地点'],
    ['导入测试资产D', '办公设备', 'TESTIMP0004', '', '', '', '测试地点'],
    ['导入测试资产E', '办公设备', 'TESTIMP0005', '', '', E['STAFF'], '测试地点'],
]
def col(i):
    s = ''
    i += 1
    while i:
        i, r = divmod(i - 1, 26)
        s = chr(65 + r) + s
    return s
def cell(ci, ri, val):
    ref = col(ci) + str(ri)
    v = escape(str(val))
    return '<c r="%s" t="inlineStr"><is><t xml:space="preserve">%s</t></is></c>' % (ref, v)
def row_xml(ri, values):
    cells = ''.join(cell(ci, ri, v) for ci, v in enumerate(values))
    return '<row r="%d">%s</row>' % (ri, cells)

data = [headers] + rows
sheet = ''.join(row_xml(i + 1, r) for i, r in enumerate(data))
sheets = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
  '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' \
  '<sheetData>%s</sheetData></worksheet>' % sheet
wb = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
  '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" ' \
  'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' \
  '<sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>'
wbrels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
  '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' \
  '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>'
rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
  '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' \
  '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'
ct = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
  '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' \
  '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' \
  '<Default Extension="xml" ContentType="application/xml"/>' \
  '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' \
  '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>'
with zipfile.ZipFile('/tmp/asset_import_test.xlsx', 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', ct)
    z.writestr('_rels/.rels', rels)
    z.writestr('xl/workbook.xml', wb)
    z.writestr('xl/_rels/workbook.xml.rels', wbrels)
    z.writestr('xl/worksheets/sheet1.xml', sheets)
print('XLSX_OK')
PY

echo "=== 执行导入 ==="
curl -s -X POST $API/assets/import -H "token: $TOKEN" -F "file=@/tmp/asset_import_test.xlsx" | python3 -m json.tool

echo "=== 数据库结果 ==="
$DB -e "select id,no,name,department_id,staff_id,location from assets where no like 'TESTIMP%' order by id;" 2>/dev/null

echo "=== 清理测试数据 ==="
$DB -e "delete from assets where no like 'TESTIMP%';" 2>/dev/null
$DB -e "select count(*) from assets where no like 'TESTIMP%';" 2>/dev/null
rm -f /tmp/asset_import_test.xlsx /tmp/asset_template.xlsx
echo TEST_DONE
