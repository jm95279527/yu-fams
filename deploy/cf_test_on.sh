#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
curl -s "$B/assetField/selectAll" -H "token: $TOK" -o /tmp/cf_on.json
python3 - <<'PY'
import json
rows=json.load(open('/tmp/cf_on.json'))['data']
for r in rows:
    if r['fieldKey']=='name': r['label']='设备名称'
    if r['fieldKey']=='no': r['label']='设备编号'
    if r['fieldKey']=='departmentName': r['label']='所属部门'
    if r['fieldKey']=='staffName': r['label']='使用人'
    if r['fieldKey']=='custom1':
        r['label']='保修到期'; r['fieldType']='date'; r['enabled']=1
    if r['fieldKey']=='custom2':
        r['label']='资产等级'; r['fieldType']='select'; r['options']='高,中,低'; r['enabled']=1
    if r['fieldKey']=='custom3':
        r['label']='供应商联系人'; r['fieldType']='text'; r['enabled']=1
json.dump(rows, open('/tmp/cf_on_save.json','w'), ensure_ascii=False)
PY
curl -s -X PUT "$B/assetField/save" -H "token: $TOK" -H 'Content-Type: application/json' -d @/tmp/cf_on_save.json; echo
echo '{"id":125,"custom1":"2027-12-31","custom2":"高","custom3":"张工"}' > /tmp/cf_asset.json
curl -s -X PUT "$B/assets/update" -H "token: $TOK" -H 'Content-Type: application/json' -d @/tmp/cf_asset.json; echo
$M -e "select concat('asset125 custom=',ifnull(custom1,'-'),'/',ifnull(custom2,'-'),'/',ifnull(custom3,'-')) from assets where id=125"
echo CF_TEST_ON_DONE
