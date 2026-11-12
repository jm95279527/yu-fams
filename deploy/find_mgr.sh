#!/bin/bash
echo "===== 哪些 chunk 含 role/myMenus ====="
grep -l "role/myMenus" /www/wwwroot/yufams/js/*.js 2>/dev/null | grep -v map
echo "===== 哪些 chunk 含 menuTree ====="
grep -l "menuTree" /www/wwwroot/yufams/js/*.js 2>/dev/null | grep -v map
echo "===== 28 chunk 头部特征 ====="
head -c 300 /www/wwwroot/yufams/js/28.5bfc8e64.js
echo ""
echo "===== 28 是否含 Manager 模板特征 ====="
grep -o "manager-header-left\|固定资产管理系统" /www/wwwroot/yufams/js/28.5bfc8e64.js | sort | uniq -c
echo DONE
