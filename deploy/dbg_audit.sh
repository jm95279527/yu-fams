#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
echo "--- 各表行数 ---"
for t in assets assets_in assets_receive assets_repair assets_scrap assets_transfer department company staff admin category; do
  echo "$t = $($M -e "select count(*) from $t")"
done
echo "--- 最近 30 条 DELETE /assets 审计 ---"
$M -e "select concat(id,' | ',create_time,' | ',username,' | ',method,' | ',uri,' | ',ifnull(params,'')) from audit_log where method='DELETE' and (uri like '/assets/%' or uri like '/assets?%' or uri='/assets') order by id desc limit 30"
echo "--- 最近 40 条审计（时间/uri/状态）---"
$M -e "select concat(id,' | ',create_time,' | ',username,' | ',method,' | ',uri,' | ',result_code) from audit_log order by id desc limit 40"
echo DBG3_DONE
