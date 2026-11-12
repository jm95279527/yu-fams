#!/bin/bash
APP=$(ls /www/wwwroot/yufams/js/app.*.js | grep -v map | head -1)
echo "===== 守卫完整片段 ====="
grep -o ".\{220\}return t(\"/403\")" $APP | head -2
echo ""
echo "===== getMyMenuTree 函数片段 ====="
grep -o "function [a-z]([a-z]){const [a-z]=JSON.parse(localStorage.getItem(\"xm-user\")[^\{]*\{[^;]*;[^;]*;[^;]*" $APP | head -3
echo DONE
