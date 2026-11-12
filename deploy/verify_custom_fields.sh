#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOK_LEN=${#TOK}"

echo ""
echo "########## A. 改名 + 启用自定义字段 ##########"
curl -s "$B/assetField/selectAll" -H "token: $TOK" -o /tmp/fields.json
python3 - <<'PY'
import json
rows=json.load(open('/tmp/fields.json'))['data']
for r in rows:
    if r['fieldKey']=='name': r['label']='设备名称'
    if r['fieldKey']=='no': r['label']='设备编号'
    if r['fieldKey']=='departmentName': r['label']='所属部门'
    if r['fieldKey']=='custom1':
        r['label']='保修到期'; r['fieldType']='date'; r['enabled']=1
    if r['fieldKey']=='custom2':
        r['label']='资产等级'; r['fieldType']='select'; r['options']='高,中,低'; r['enabled']=1
json.dump(rows, open('/tmp/field_save.json','w'), ensure_ascii=False)
print('payload_ok', len(rows))
PY
curl -s -X PUT "$B/assetField/save" -H "token: $TOK" -H 'Content-Type: application/json' -d @/tmp/field_save.json; echo
echo "-- 公开字段（应含新名称/自定义字段）--"
curl -s "$B/assetField/public" | python3 -c '
import sys,json
rows=json.load(sys.stdin)["data"]
for r in rows:
    if r["fieldKey"] in ("name","no","departmentName","custom1","custom2"):
        print("  ",r["fieldKey"],"=>",r["label"],"| type=",r["fieldType"],"| options=",r.get("options"))
print("  custom_count=",len([r for r in rows if not r["isSystem"]]))
'
echo "-- scan_fields 应自动追加 custom1/custom2 --"
curl -s $B/sysConfig/public | python3 -c '
import sys,json
f=json.load(sys.stdin)["data"]["scanFields"]
print("  scanFields=",f)
print("  has_custom=", "custom1" in f and "custom2" in f)
'

echo ""
echo "########## B. 资产自定义字段读写 ##########"
echo '{"id":125,"custom1":"2027-12-31","custom2":"高"}' > /tmp/asset_custom.json
curl -s -X PUT "$B/assets/update" -H "token: $TOK" -H 'Content-Type: application/json' -d @/tmp/asset_custom.json; echo
echo "-- selectById --"
curl -s "$B/assets/selectById/125" -H "token: $TOK" | python3 -c '
import sys,json
d=json.load(sys.stdin)["data"]
print("  custom1=",d.get("custom1")," custom2=",d.get("custom2"))
'
echo "-- 扫码接口 --"
curl -s "$B/qr/asset/125" | python3 -c '
import sys,json
d=json.load(sys.stdin)["data"]
print("  custom1=",d.get("custom1")," custom2=",d.get("custom2"))
'

echo ""
echo "########## C. 导出/模板列名同步 ##########"
curl -s "$B/assets/export?token=$TOK" -o /tmp/cf_export.xlsx
curl -s "$B/assets/template?token=$TOK" -o /tmp/cf_template.xlsx
python3 - <<'PY'
import zipfile,re
for path,name in [('/tmp/cf_export.xlsx','导出'),('/tmp/cf_template.xlsx','模板')]:
    z=zipfile.ZipFile(path)
    xml=''
    for n in z.namelist():
        if 'sharedStrings' in n or 'worksheets/sheet' in n:
            xml+=z.read(n).decode('utf-8')
    texts=re.findall(r'<t[^>]*>([^<]*)</t>',xml)
    print(name,' headers=',texts[:20])
    print('   new_labels=', all(x in texts for x in ['设备名称','设备编号','所属部门']))
    if name=='导出':
        print('   custom_values=', ('2027-12-31' in texts) and ('高' in texts))
        print('   custom_headers=', ('保修到期' in texts) and ('资产等级' in texts))
    else:
        print('   custom_headers=', ('保修到期' in texts) and ('资产等级' in texts))
PY
rm -f /tmp/cf_export.xlsx /tmp/cf_template.xlsx

echo ""
echo "########## D. 使用改名后的表头导入 ##########"
python3 - <<'PY'
import zipfile
rows=[["设备名称","设备编号","资产分类","保修到期","资产等级"],
      ["自定义字段测试机","TEST-CF-001","办公设备","2028-01-01","低"]]
def esc(s): return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
def rowstr(i,vals):
    cells=''
    for j,v in enumerate(vals):
        cells+='<c r="%s%d" t="inlineStr"><is><t>%s</t></is></c>'%(chr(65+j),i,esc(v))
    return '<row r="%d">%s</row>'%(i,cells)
sheet='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>'
for i,r in enumerate(rows,1): sheet+=rowstr(i,r)
sheet+='</sheetData></worksheet>'
ct='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>'
rels='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'
wb='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>'
wbr='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>'
z=zipfile.ZipFile('/tmp/cf_import.xlsx','w',zipfile.ZIP_DEFLATED)
z.writestr("[Content_Types].xml",ct); z.writestr("_rels/.rels",rels)
z.writestr("xl/workbook.xml",wb); z.writestr("xl/_rels/workbook.xml.rels",wbr)
z.writestr("xl/worksheets/sheet1.xml",sheet); z.close()
print("XLSX_OK")
PY
curl -s -X POST "$B/assets/import" -H "token: $TOK" -F "file=@/tmp/cf_import.xlsx"; echo
AID=$($M -e "select id from assets where no='TEST-CF-001' limit 1")
echo "imported_asset_id=${AID:-none}"
$M -e "select concat('  name=',name,' no=',no,' custom1=',ifnull(custom1,'NULL'),' custom2=',ifnull(custom2,'NULL')) from assets where no='TEST-CF-001'"

echo ""
echo "########## E. 还原配置与数据 ##########"
curl -s "$B/assetField/selectAll" -H "token: $TOK" -o /tmp/fields2.json
python3 - <<'PY'
import json
rows=json.load(open('/tmp/fields2.json'))['data']
reset={'name':'资产名称','no':'资产编号','departmentName':'使用部门'}
for r in rows:
    if r['fieldKey'] in reset: r['label']=reset[r['fieldKey']]
    if r['fieldKey']=='custom1':
        r['label']='自定义字段1'; r['fieldType']='text'; r['options']=''; r['enabled']=0
    if r['fieldKey']=='custom2':
        r['label']='自定义字段2'; r['fieldType']='text'; r['options']=''; r['enabled']=0
json.dump(rows, open('/tmp/field_reset.json','w'), ensure_ascii=False)
PY
curl -s -X PUT "$B/assetField/save" -H "token: $TOK" -H 'Content-Type: application/json' -d @/tmp/field_reset.json; echo
$M -e "update assets set custom1=NULL, custom2=NULL where id=125"
if [ -n "$AID" ]; then
  curl -s -X DELETE "$B/assets/delete/$AID" -H "token: $TOK" > /dev/null
fi
$M -e "update assets set custom1=NULL, custom2=NULL where no='TEST-CF-001'"
$M -e "delete from assets where no='TEST-CF-001'"
rm -f /tmp/cf_import.xlsx /tmp/fields.json /tmp/fields2.json /tmp/field_save.json /tmp/field_reset.json /tmp/asset_custom.json
echo "-- 还原后核对 --"
curl -s "$B/assetField/public" | python3 -c '
import sys,json
rows=json.load(sys.stdin)["data"]
print("  labels=",{r["fieldKey"]:r["label"] for r in rows if r["fieldKey"] in ("name","no","departmentName")})
print("  custom_count=",len([r for r in rows if not r["isSystem"]]))
'
curl -s $B/sysConfig/public | python3 -c '
import sys,json
f=json.load(sys.stdin)["data"]["scanFields"]
print("  scanFields_has_custom=", ("custom1" in f or "custom2" in f))
'
$M -e "select concat('  asset125 custom1=',ifnull(custom1,'NULL'),' custom2=',ifnull(custom2,'NULL')) from assets where id=125"
$M -e "select concat('  test_asset_left=',count(*)) from assets where no='TEST-CF-001'"
echo VERIFY_CUSTOM_FIELDS_DONE
