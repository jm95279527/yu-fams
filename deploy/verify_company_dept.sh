#!/bin/bash
# 需求13 端到端验证：一物一码 / 借用状态 / 到期提醒 / 部门导入+分子公司
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
YML=/opt/yu-fams/Yu-FAMS-SpringBoot-master/src/main/resources/application.yml

TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOK_LEN=${#TOK}"

TOD=$(date +%F); YES=$(date -d yesterday +%F); TOM=$(date -d tomorrow +%F)
echo "DATES yes=$YES today=$TOD tom=$TOM"

echo ""
echo "########## A. 部门导入（自动建公司 + 多级部门）##########"
python3 - <<'PY'
import zipfile
rows=[("福建测试集团公司","财务部","","福州鼓楼"),
      ("福建测试集团公司","会计科","财务部",""),
      ("厦门测试分公司","生产部","","厦门集美")]
hdr=["公司名称","部门名称","上级部门","地址"]
def esc(s): return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
def rowstr(i,vals):
    cells=''
    for j,v in enumerate(vals):
        if v=="": continue
        cells+='<c r="%s%d" t="inlineStr"><is><t>%s</t></is></c>'%(chr(65+j),i,esc(v))
    return '<row r="%d">%s</row>'%(i,cells)
sheet='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>'
sheet+=rowstr(1,hdr)
for i,r in enumerate(rows,2): sheet+=rowstr(i,list(r))
sheet+='</sheetData></worksheet>'
ct='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>'
rels='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'
wb='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>'
wbr='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>'
z=zipfile.ZipFile("/tmp/dept13.xlsx","w",zipfile.ZIP_DEFLATED)
z.writestr("[Content_Types].xml",ct); z.writestr("_rels/.rels",rels)
z.writestr("xl/workbook.xml",wb); z.writestr("xl/_rels/workbook.xml.rels",wbr)
z.writestr("xl/worksheets/sheet1.xml",sheet); z.close()

# 上级部门不存在的异常文件
bad='<?xml version="1.0"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>'
bad+='<row r="1"><c r="A1" t="inlineStr"><is><t>公司名称</t></is></c><c r="B1" t="inlineStr"><is><t>部门名称</t></is></c><c r="C1" t="inlineStr"><is><t>上级部门</t></is></c></row>'
bad+='<row r="2"><c r="A2" t="inlineStr"><is><t>福建测试集团公司</t></is></c><c r="B2" t="inlineStr"><is><t>孤儿部门</t></is></c><c r="C2" t="inlineStr"><is><t>不存在的部门</t></is></c></row>'
bad+='</sheetData></worksheet>'
z2=zipfile.ZipFile("/tmp/dept13bad.xlsx","w")
z2.writestr("[Content_Types].xml",ct); z2.writestr("_rels/.rels",rels)
z2.writestr("xl/workbook.xml",wb); z2.writestr("xl/_rels/workbook.xml.rels",wbr)
z2.writestr("xl/worksheets/sheet1.xml",bad); z2.close()
print("XLSX_OK")
PY
echo "-- import --"
curl -s -X POST $B/department/import -H "token: $TOK" -F "file=@/tmp/dept13.xlsx"; echo
echo "-- 库中结果 --"
$M -e "select concat(d.id,' | ',c.name,' | ',d.name,' | level=',d.level,' | pid=',ifnull(d.pid,'-')) from department d join company c on d.company_id=c.id where c.name like '%测试%' order by d.id"
echo "-- 接口 selectAll 的 label（应为 公司-部门）--"
curl -s "$B/department/selectAll" -H "token: $TOK" | python3 -c 'import sys,json
d=json.load(sys.stdin)["data"]
for x in d:
    if x.get("companyName") and "测试" in x.get("companyName"): print("  ",x["id"],x["name"],"=>",x.get("label"))'
echo "-- 重复导入应跳过 --"
curl -s -X POST $B/department/import -H "token: $TOK" -F "file=@/tmp/dept13.xlsx"; echo
echo "-- 上级部门不存在应报错且不落库 --"
curl -s -X POST $B/department/import -H "token: $TOK" -F "file=@/tmp/dept13bad.xlsx"; echo
$M -e "select concat('孤儿部门数=',count(*)) from department where name='孤儿部门'"

echo ""
echo "########## B. 一物一码（入库 3 台 → 3 条资产，各自编号）##########"
curl -s -X POST $B/assetsIn/add -H "token: $TOK" -H 'Content-Type: application/json' \
  -d '{"name":"测试打印机13","category":"办公设备","model":"TP-13","num":3,"money":1000,"purchaseNo":"TEST13","supplier":"测试供应商","location":"测试仓库","date":"2026-09-14"}'; echo
IN_ID=$($M -e "select id from assets_in where name='测试打印机13' order by id desc limit 1")
echo "IN_ID=$IN_ID"
curl -s -X POST $B/assetsIn/audit/$IN_ID -H "token: $TOK" -H 'Content-Type: application/json' -d '{"pass":true}'; echo
echo "-- 生成的资产（应为 3 条，num 均为 1，no 各不相同）--"
$M -e "select concat(id,' | ',ifnull(no,'(空)'),' | num=',num,' | status=',status) from assets where name='测试打印机13' order by id"
$M -e "select concat('asset_rows=',count(*),'  distinct_no=',count(distinct no)) from assets where name='测试打印机13'"

echo ""
echo "########## C. 借用（按台借出 → 已借出 / 归还 → 正常）##########"
A1=$($M -e "select id from assets where name='测试打印机13' order by id asc limit 1")
A2=$($M -e "select id from assets where name='测试打印机13' order by id asc limit 1 offset 1")
A3=$($M -e "select id from assets where name='测试打印机13' order by id desc limit 1")
echo "A1=$A1 A2=$A2 A3=$A3"
mkborrow () {
  curl -s -X POST $B/assetsReceive/add -H "token: $TOK" -H 'Content-Type: application/json' \
    -d "{\"assetsId\":$1,\"borrowerName\":\"测试借用人\",\"borrowerPhone\":\"13800000000\",\"returnDate\":\"$2\",\"comment\":\"到期提醒测试\"}"
  echo ""
}
mkborrow $A1 $YES
mkborrow $A2 $TOD
mkborrow $A3 $TOM
$M -e "select concat(id,' | assets=',assets_id,' | ',borrower_name,' | ',return_date,' | ',status,' | ',return_status) from assets_receive where borrower_name='测试借用人' order by id"
RIDS=$($M -e "select id from assets_receive where borrower_name='测试借用人' order by id")
RID1=$(echo "$RIDS" | sed -n 1p); RID2=$(echo "$RIDS" | sed -n 2p); RID3=$(echo "$RIDS" | sed -n 3p)
for RID in $RIDS; do
  curl -s -X PUT $B/assetsReceive/update -H "token: $TOK" -H 'Content-Type: application/json' \
    -d "{\"id\":$RID,\"status\":\"通过\"}" > /dev/null
done
echo "-- 审核通过后（应为 num=0 / status=已借出）--"
$M -e "select concat(id,' | num=',num,' | status=',status) from assets where id in ($A1,$A2,$A3) order by id"
echo "-- 重复审核 A1（幂等，应仍为 num=0 / 已借出）--"
curl -s -X PUT $B/assetsReceive/update -H "token: $TOK" -H 'Content-Type: application/json' -d "{\"id\":$RID1,\"status\":\"通过\"}" > /dev/null
$M -e "select concat(id,' | num=',num,' | status=',status) from assets where id=$A1"
echo "-- 归还 A3（应 num=1 / status=正常）--"
curl -s -X PUT $B/assetsReceive/update -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"id\":$RID3,\"assetsId\":$A3,\"status\":\"通过\",\"returnStatus\":\"已归还\"}" > /dev/null
$M -e "select concat(id,' | num=',num,' | status=',status) from assets where id=$A3"
echo "-- 重复归还（幂等，应仍为 num=1）--"
curl -s -X PUT $B/assetsReceive/update -H "token: $TOK" -H 'Content-Type: application/json' \
  -d "{\"id\":$RID3,\"assetsId\":$A3,\"status\":\"通过\",\"returnStatus\":\"已归还\"}" > /dev/null
$M -e "select concat(id,' | num=',num,' | status=',status) from assets where id=$A3"

echo ""
echo "########## D. 借用到期提醒（临时改为每分钟触发）##########"
echo "-- 待提醒记录（应为 2 条：逾期 + 今日到期）--"
$M -e "select concat(id,' | assets=',assets_id,' | ',return_date,' | ',status,' | ',return_status) from assets_receive where return_status='未归还' and status='通过' and return_date <= date_format(date_add(curdate(), interval 1 day),'%Y-%m-%d') order by id"
BEFORE=$($M -e "select count(*) from notify_log where event_key='RECEIVE_DUE'")
sed -i 's|^borrow-remind-cron: .*|borrow-remind-cron: "0 * * * * ?"|' $YML
grep -n borrow-remind-cron $YML
systemctl restart yufams
NOW=$BEFORE
for i in $(seq 1 25); do sleep 8; NOW=$($M -e "select count(*) from notify_log where event_key='RECEIVE_DUE'"); if [ "$NOW" -gt "$BEFORE" ]; then break; fi; done
echo "RECEIVE_DUE logs: before=$BEFORE after=$NOW (loops=$i)"
echo "-- 最新一条提醒 --"
$M -e "select concat(event_key,' | ',biz_type,' | ',status,' | ',title,' | robot=',ifnull(robot_name,'-')) from notify_log where event_key='RECEIVE_DUE' order by id desc limit 1"
$M -e "select content from notify_log where event_key='RECEIVE_DUE' order by id desc limit 1"
echo "-- 恢复每天 9:00 并重启 --"
sed -i 's|^borrow-remind-cron: .*|borrow-remind-cron: "0 0 9 * * ?"|' $YML
grep -n borrow-remind-cron $YML
systemctl restart yufams
C=000
for i in $(seq 1 25); do sleep 5; C=$(curl -s -o /dev/null -w '%{http_code}' -X POST $B/login); if [ "$C" = "200" ]; then break; fi; done
echo "backend_after_restore_http=$C"

echo ""
echo "########## E. 清理测试数据 ##########"
$M -e "delete from notify_log where content like '%测试打印机13%' or content like '%测试借用人%'"
$M -e "delete from assets_receive where borrower_name='测试借用人'"
$M -e "delete from assets where name='测试打印机13'"
$M -e "delete from assets_in where name='测试打印机13'"
$M -e "delete from department where company_id in (select id from company where name like '%测试%')"
$M -e "delete from company where name like '%测试%'"
echo "-- 清理后核对（应全为 0）--"
$M -e "select concat('assets=',count(*)) from assets where name='测试打印机13'"
$M -e "select concat('assets_in=',count(*)) from assets_in where name='测试打印机13'"
$M -e "select concat('receive=',count(*)) from assets_receive where borrower_name='测试借用人'"
$M -e "select concat('dept=',count(*)) from department d join company c on d.company_id=c.id where c.name like '%测试%'"
$M -e "select concat('company=',count(*)) from company where name like '%测试%'"
$M -e "select concat('orphan_dept=',count(*)) from department where name='孤儿部门'"
echo "VERIFY13_DONE"
