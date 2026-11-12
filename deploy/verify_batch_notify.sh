#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
B=http://127.0.0.1:89
J='Content-Type: application/json'

echo "=== 1) 生成测试用 xlsx（python3 zipfile，无 openpyxl）==="
python3 - <<'PY'
import zipfile

HEADERS = ["资产名称","资产分类","规格型号","数量","初始价值","折旧方法","采购单号","供应商","存放地点","购置日期","验收日期","验收人","验收意见","备注"]
ROWS = [
    ["E2E导入A","办公设备","M1",1,"100.00","直线法","E2E-BATCH-01","供应商A","仓库A","2026-09-14","2026-09-14","张三","合格","E2E批量导入测试"],
    ["E2E导入B","办公设备","M2",2,"200.00","直线法","E2E-BATCH-02","供应商A","仓库A","2026-09-14","2026-09-14","张三","合格","E2E批量导入测试"],
    ["E2E导入C","办公设备","M3",3,"300.00","直线法","E2E-BATCH-03","供应商A","仓库A","2026-09-14","2026-09-14","张三","合格","E2E批量导入测试"],
]

def colname(i):
    s = ""
    i += 1
    while i:
        i, r = divmod(i - 1, 26)
        s = chr(65 + r) + s
    return s

def esc(t):
    return str(t).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

parts = []
parts.append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
parts.append('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>')
for ri, row in enumerate([HEADERS] + ROWS, start=1):
    cells = []
    for ci, val in enumerate(row):
        ref = "%s%d" % (colname(ci), ri)
        if isinstance(val, int):
            cells.append('<c r="%s"><v>%d</v></c>' % (ref, val))
        else:
            cells.append('<c r="%s" t="inlineStr"><is><t>%s</t></is></c>' % (ref, esc(val)))
    parts.append('<row r="%d">%s</row>' % (ri, ''.join(cells)))
parts.append('</sheetData></worksheet>')
sheet = ''.join(parts)

ct = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '</Types>')

rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>')

wb = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>')

wbrels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
          '</Relationships>')

with zipfile.ZipFile("/tmp/e2e_import.xlsx", "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", ct)
    z.writestr("_rels/.rels", rels)
    z.writestr("xl/workbook.xml", wb)
    z.writestr("xl/_rels/workbook.xml.rels", wbrels)
    z.writestr("xl/worksheets/sheet1.xml", sheet)
print("xlsx written")
PY
ls -l /tmp/e2e_import.xlsx

echo "=== 2) 准备机器人 + 导入 ==="
TOK=$(curl -s "$B/login" -H "$J" -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
H="token: $TOK"
curl -s -X POST "$B/robotConfig/add" -H "$H" -H "$J" \
  -d '{"name":"E2E临时","type":"wechat","webhookUrl":"https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=e2e-batch","enabled":true}' > /dev/null

echo -n "  导入结果: "
curl -s -X POST "$B/assetsIn/import" -H "$H" -F "file=@/tmp/e2e_import.xlsx" | head -c 200; echo
sleep 1
echo "  入库单落库条数: $($M -e "SELECT COUNT(*) FROM assets_in WHERE purchase_no LIKE 'E2E-BATCH-%';" 2>/dev/null)"
echo "--- 通知记录（应只有 1 条 ASSETS_IN_BATCH）---"
$M -e "SELECT CONCAT('  条数=',COUNT(*)) FROM notify_log;" 2>/dev/null
$M -e "SELECT CONCAT('  ',event_key,' | ',biz_type,' | ',status) FROM notify_log;" 2>/dev/null
$M -e "SELECT CONCAT('  内容=',REPLACE(content,CHAR(10),' / ')) FROM notify_log LIMIT 1;" 2>/dev/null

echo "=== 3) 清理 ==="
$M -e "DELETE FROM notify_log;" 2>/dev/null
$M -e "DELETE FROM robot_config;" 2>/dev/null
$M -e "DELETE FROM assets_in WHERE purchase_no LIKE 'E2E-BATCH-%';" 2>/dev/null
rm -f /tmp/e2e_import.xlsx
$M -e "SELECT CONCAT('  assets_in残留=',COUNT(*),' log=',(SELECT COUNT(*) FROM notify_log),' robot=',(SELECT COUNT(*) FROM robot_config)) FROM assets_in WHERE purchase_no LIKE 'E2E-BATCH-%';" 2>/dev/null
echo DONE
