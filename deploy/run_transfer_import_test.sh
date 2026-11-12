#!/bin/bash
set -e
API=http://127.0.0.1:89
CP=$(cat /tmp/cp.txt)

echo "=== 生成测试 Excel ==="
javac -encoding UTF-8 -cp "$CP" -d /tmp /tmp/TransferImportTest.java
java -cp "/tmp:$CP" TransferImportTest

TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')

echo "=== 模板表头 ==="
curl -s -o /tmp/transfer_template.xlsx "$API/assetsTransfer/template?token=$TOKEN"
python3 - <<'PY'
import zipfile, re
z = zipfile.ZipFile('/tmp/transfer_template.xlsx')
xml = z.read('xl/sharedStrings.xml').decode('utf-8')
print([m for m in re.findall(r'<t[^>]*>(.*?)</t>', xml)])
PY

echo "=== 执行导入 ==="
curl -s -X POST $API/assetsTransfer/import -H "token: $TOKEN" -F "file=@/tmp/transfer_import_test.xlsx" | python3 -m json.tool

echo "=== 数据库结果 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "
select id,assets_no,from_department_name,from_staff_name,from_location,
       to_department_name,to_staff_name,to_location,reason,status,transfer_staff_name
from assets_transfer where reason like '批量测试-%' order by id;
" 2>/dev/null

echo "=== 资产未变更（仍为原部门） ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "
select no,department_id,staff_id,location from assets where no in
('HMDZ0126100001','HMDZ0126100002','HMDZ0126100003','HMDZ0126100004','HMDZ0226100002','HMDZ0226100003');
" 2>/dev/null

echo "=== 清理测试数据 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -e "delete from assets_transfer where reason like '批量测试-%';" 2>/dev/null
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "select count(*) from assets_transfer where reason like '批量测试-%';" 2>/dev/null
rm -f /tmp/transfer_import_test.xlsx /tmp/transfer_template.xlsx /tmp/TransferImportTest.class
echo TEST_DONE
