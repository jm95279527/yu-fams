#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
curl -s "$B/assetField/selectAll" -H "token: $TOK" -o /tmp/cf_off.json
python3 - <<'PY'
import json
rows=json.load(open('/tmp/cf_off.json'))['data']
reset={'name':'资产名称','no':'资产编号','departmentName':'使用部门','staffName':'责任人'}
for r in rows:
    if r['fieldKey'] in reset: r['label']=reset[r['fieldKey']]
    if r['fieldKey']=='custom1':
        r['label']='自定义字段1'; r['fieldType']='text'; r['options']=''; r['enabled']=0
    if r['fieldKey']=='custom2':
        r['label']='自定义字段2'; r['fieldType']='text'; r['options']=''; r['enabled']=0
    if r['fieldKey']=='custom3':
        r['label']='自定义字段3'; r['fieldType']='text'; r['options']=''; r['enabled']=0
json.dump(rows, open('/tmp/cf_off_save.json','w'), ensure_ascii=False)
PY
curl -s -X PUT "$B/assetField/save" -H "token: $TOK" -H 'Content-Type: application/json' -d @/tmp/cf_off_save.json; echo
$M -e "update assets set custom1=NULL,custom2=NULL,custom3=NULL where id=125"
rm -f /tmp/cf_on.json /tmp/cf_on_save.json /tmp/cf_asset.json /tmp/cf_off.json /tmp/cf_off_save.json
echo "-- 核对 --"
curl -s "$B/assetField/public" | python3 -c '
import sys,json
rows=json.load(sys.stdin)["data"]
print("labels=",{r["fieldKey"]:r["label"] for r in rows if r["fieldKey"] in ("name","no","departmentName","staffName")})
print("custom_count=",len([r for r in rows if not r["isSystem"]]))
'
curl -s $B/sysConfig/public | python3 -c '
import sys,json
f=json.load(sys.stdin)["data"]["scanFields"]
print("scan_has_custom=", any(x.startswith("custom") for x in f))
'
$M -e "select concat('asset125 custom=',ifnull(custom1,'NULL'),'/',ifnull(custom2,'NULL'),'/',ifnull(custom3,'NULL')) from assets where id=125"
echo CF_TEST_OFF_DONE
