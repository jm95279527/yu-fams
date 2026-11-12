#!/bin/bash
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
WWW=/www/wwwroot/yufams
echo "=== 源码路由 ==="
grep -n "customFields" $FRONT/src/router/index.js
echo "=== CustomFields.vue 是否存在 ==="
ls -l $FRONT/src/views/manager/CustomFields.vue
echo "=== dist 中包含「字段标识」的文件 ==="
grep -rl "字段标识" $WWW/js | head -5
echo "=== dist 中包含「功能建设中」的文件 ==="
grep -rl "功能建设中" $WWW/js | head -5
echo "=== index.html 引用的 app.js ==="
grep -oE 'js/app\.[A-Za-z0-9]+\.js' $WWW/index.html
echo "=== app.js 中的 customFields 片段 ==="
grep -oE 'customFields[^,]{0,120}' $WWW/js/app.*.js | head -5
echo "=== 构建时间 ==="
ls -l --time-style=+%F_%T $WWW/js/app.*.js
