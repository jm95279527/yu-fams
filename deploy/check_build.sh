#!/bin/bash
VUE=/opt/yu-fams/Yu-FAMS-Vue-master
echo "===== 源 router 中 rolePerm 行 ====="
grep -n "rolePerm" $VUE/src/router/index.js
echo "===== 源 RolePerm.vue 是否存在 ====="
ls -l $VUE/src/views/manager/RolePerm.vue
echo "===== dist 构建时间 ====="
ls -ld $VUE/dist
ls -l $VUE/dist/index.html
echo "===== dist chunk 中是否包含 RolePerm 关键字 ====="
grep -rl "分配菜单权限" $VUE/dist/js/ | head
echo "===== dist 中 rolePerm 路由指向 ====="
grep -ro "rolePerm[^\"]*" $VUE/dist/js/ | sort -u | head
echo "===== 已部署 index.html 时间 ====="
ls -l /www/wwwroot/yufams/index.html
echo "===== 部署目录是否有该chunk ====="
grep -rl "分配菜单权限" /www/wwwroot/yufams/js/ | head
echo DONE
