#!/bin/bash
echo "===== 部署目录全部 chunk ====="
ls /www/wwwroot/yufams/js/ | grep -v map | sort
echo "===== 924 是否存在 ====="
ls /www/wwwroot/yufams/js/ | grep "^924" || echo "NO_924"
echo "===== 哪个 chunk 含无权限页特征（403组件） ====="
grep -l "权限不足\|无权限访问\|403" /www/wwwroot/yufams/js/*.js 2>/dev/null | grep -v map
echo "===== 直接请求旧chunk名看返回 ====="
curl -s -o /dev/null -w "%{http_code} %{content_type}\n" http://127.0.0.1:88/js/924.000000.js
echo DONE
