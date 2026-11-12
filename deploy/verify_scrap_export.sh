#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets"
echo "=== assets_scrap 列 ==="
$M -N -e "SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION) FROM information_schema.columns WHERE table_schema='xm-assets' AND table_name='assets_scrap';" 2>/dev/null
echo "=== 插入临时报废记录 ==="
$M -e "INSERT INTO assets_scrap (id, assets_id, assets_no, assets_name, category, model, money, depreciate, department_name, staff_name, location, scrap_type, reason, residual_value, apply_time, applicant_name, status, comment) VALUES (99991, 107, 'TMP-VERIFY', '临时验证资产', '办公设备', 'X1', 1000.00, '直线法', 'hena', '', '办公室', '正常报废', '导出验证', 0.00, '2026-09-14 15:20:00', '系统管理员', '待审批', 'TMP');" 2>&1 | head -3
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "=== 报废导出内容检查 ==="
curl -s -o /tmp/sc.xlsx "$B/assetsScrap/export?token=$TOK"
python3 - <<'PY'
import zipfile, xml.etree.ElementTree as ET
NS='{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
z=zipfile.ZipFile('/tmp/sc.xlsx')
ss=[]
if 'xl/sharedStrings.xml' in z.namelist():
    r=ET.fromstring(z.read('xl/sharedStrings.xml'))
    for si in r.findall(NS+'si'):
        ss.append(''.join(t.text or '' for t in si.iter(NS+'t')))
sh=ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
rows=sh.find(NS+'sheetData').findall(NS+'row')
def cells(rw):
    out=[]
    for c in rw.findall(NS+'c'):
        v=c.find(NS+'v'); txt='' if v is None else v.text
        if c.get('t')=='s' and txt not in (None,''): txt=ss[int(txt)]
        out.append('' if txt is None else txt)
    return out
print('rows=%d' % len(rows))
if rows:
    print('表头(%d): %s' % (len(cells(rows[0])), ','.join(cells(rows[0]))))
if len(rows)>1:
    print('数据: %s' % ','.join(cells(rows[1])))
PY
echo "=== 清理临时记录 ==="
$M -e "DELETE FROM assets_scrap WHERE id=99991;" 2>/dev/null
$M -N -e "SELECT CONCAT('assetsScrap_rows=',COUNT(*)) FROM assets_scrap;" 2>/dev/null
echo DONE
