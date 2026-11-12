#!/bin/bash
cd /www/wwwroot/yufams || exit 1
echo "-- index.html 引用的入口文件 --"
grep -oE 'js/[A-Za-z0-9._-]+\.js' index.html | sort -u
echo "-- 校验入口文件 --"
for f in $(grep -oE 'js/[A-Za-z0-9._-]+\.js' index.html | sort -u); do
  if [ -f "$f" ]; then echo "OK   $f"; else echo "MISS $f"; fi
done
echo "-- app.js 中 946 的引用 --"
grep -oE '946[^"]{0,24}' js/app.6bd74f2b.js | head -5
echo "-- js 目录中的 946 文件数 --"
ls -1 js | grep -c 946
ls -1 js | grep 946 | head -5
echo "-- js 文件总数 --"
ls -1 js | wc -l
echo "-- 当前实际构建时间 --"
ls -l --time-style=+%F_%T js/app.6bd74f2b.js
