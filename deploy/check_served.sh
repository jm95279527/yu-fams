#!/bin/bash
echo "===== nginx served index.html ====="
curl -s http://127.0.0.1:88/index.html | grep -o 'js/app\.[a-z0-9]*\.js'
echo "===== deployed index.html on disk ====="
grep -o 'js/app\.[a-z0-9]*\.js' /www/wwwroot/yufams/index.html
APP=$(ls /www/wwwroot/yufams/js/app.*.js | grep -v map | head -1)
echo "===== app chunk: $APP ====="
echo "--- 守卫白名单特征 adminPerson/staffPerson 出现次数:"
grep -o "adminPerson" $APP | wc -l
echo "--- myMenus 出现次数:"
grep -o "role/myMenus" $APP | wc -l
echo "--- beforeEach 特征:"
grep -o "beforeEach" $APP | wc -l
echo "--- 403 重定向上下文:"
grep -o ".\{80\}/403.\{80\}" $APP | head -5
echo "--- getMyMenuTree/resetMenuCache:"
grep -o "getMyMenuTree\|resetMenuCache" $APP | sort | uniq -c
echo DONE
