#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "=== 各下拉数据源行数 ==="
for t in category staff assets department company number_rule assets_receive assets_repair assets_in; do
  echo "$t = $($M -e "select count(*) from $t")"
done
echo ""
echo "=== category 表内容 ==="
$M -e "select concat(id,' | ',ifnull(name,'-'),' | ',ifnull(code,'-')) from category"
echo ""
echo "=== number_rule 内容 ==="
$M -e "select concat(id,' | enabled=',ifnull(enabled,'NULL'),' | pattern=',ifnull(pattern,'-')) from number_rule" 2>&1
echo ""
echo "=== 借用/维修 现存 ==="
$M -e "select concat(id,' | assets=',assets_id,' | ',status,' | ',return_status) from assets_receive order by id"
$M -e "select concat(id,' | ',status) from assets_repair order by id"
echo ""
echo "=== 分类被删除的审计记录（10:06 前后）==="
$M -e "select concat(id,' | ',create_time,' | ',method,' | ',uri,' | ',ifnull(params,'')) from audit_log where uri like '/category%' order by id desc limit 10"
echo DBG6_DONE
