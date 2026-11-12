#!/bin/bash
set -e
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/exportfix

echo "===== 1. 备份原文件并对比差异 ====="
mkdir -p $SRC/bak
cp $FRONT/src/utils/request.js $SRC/bak/request.js
cp $FRONT/src/views/manager/Assets.vue $SRC/bak/Assets.vue
cp $FRONT/src/views/manager/AssetsIn.vue $SRC/bak/AssetsIn.vue
echo "--- request.js diff ---"
diff $SRC/bak/request.js $SRC/request.js || true
echo "--- Assets.vue diff ---"
diff $SRC/bak/Assets.vue $SRC/Assets.vue || true
echo "--- AssetsIn.vue diff ---"
diff $SRC/bak/AssetsIn.vue $SRC/AssetsIn.vue || true

echo "===== 2. 覆盖源文件 ====="
cp $SRC/request.js $FRONT/src/utils/request.js
cp $SRC/Assets.vue $FRONT/src/views/manager/Assets.vue
cp $SRC/AssetsIn.vue $FRONT/src/views/manager/AssetsIn.vue
echo "copied"

echo "===== 3. 构建前端 ====="
cd $FRONT
npm run build > /tmp/exportfix/build.log 2>&1
echo "build exit=$?"
tail -6 /tmp/exportfix/build.log

echo "===== 4. 校验产物中已含修复 ====="
grep -c "responseType" $FRONT/dist/js/*.js 2>/dev/null | head -3 || true

echo "===== 5. 发布到 nginx 并 reload ====="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
nginx -s reload
echo "deployed at $(date)"
ls /www/wwwroot/yufams/js/ | head -5
echo DONE
