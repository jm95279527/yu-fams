#!/bin/bash
M=/www/wwwroot/yufams/js/28.5bfc8e64.js
echo "===== Manager chunk 是否为新版（共享菜单缓存）====="
grep -o "getMyMenuTree\|resetMenuCache\|whitePaths\|checkPath\|grantedPaths" $M | sort | uniq -c
echo "===== 其中 myMenus 调用上下文 ====="
grep -o ".\{120\}myMenus.\{60\}" $M | head -5
echo DONE
