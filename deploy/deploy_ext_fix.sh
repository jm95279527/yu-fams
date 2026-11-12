#!/bin/bash
set -e -o pipefail
BACK=/opt/yu-fams/Yu-FAMS-SpringBoot-master
FRONT=/opt/yu-fams/Yu-FAMS-Vue-master
SRC=/tmp/extfix

echo "===== 1. 备份 ====="
mkdir -p $SRC/bak
cp $BACK/src/main/java/com/example/controller/AssetsController.java $SRC/bak/
cp $BACK/src/main/java/com/example/controller/FileController.java $SRC/bak/
cp $BACK/src/main/resources/application.yml $SRC/bak/
cp $FRONT/.env.production $SRC/bak/env.production
cp /www/server/panel/vhost/nginx/yufams.conf $SRC/bak/yufams.conf
echo backed

echo "===== 2. 覆盖后端文件 ====="
cp $SRC/AssetsController.java $BACK/src/main/java/com/example/controller/
cp $SRC/FileController.java $BACK/src/main/java/com/example/controller/
cp $SRC/application.yml $BACK/src/main/resources/
echo copied

echo "===== 3. 前端 API 基址 -> 同源相对路径 ====="
printf "VUE_APP_BASEURL='/api'\n" > $FRONT/.env.production
cat $FRONT/.env.production

echo "===== 4. nginx: 88 站点加 /api 与 /files 反代 ====="
cat > /www/server/panel/vhost/nginx/yufams.conf <<'EOF'
server {
    listen 88;
    # 通配：外网映射进来时 Host 是公网 IP/域名，也要能命中本站点
    server_name _;

    root /www/wwwroot/yufams;
    index index.html;

    client_max_body_size 50m;
    access_log /www/wwwlogs/yufams.log;
    error_log  /www/wwwlogs/yufams.error.log;

    # 后端 API：/api/xxx -> 后端 /xxx（末尾斜杠会剥掉 /api 前缀）
    location /api/ {
        proxy_pass http://127.0.0.1:89/;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }

    # 上传的图片/附件
    location /files/ {
        proxy_pass http://127.0.0.1:89/files/;
        proxy_set_header Host $http_host;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
nginx -t

echo "===== 5. 构建后端 ====="
cd $BACK
mvn clean package -DskipTests -q > $SRC/build-back.log 2>&1
echo "backend build exit=$?"
tail -4 $SRC/build-back.log

echo "===== 6. 构建前端 ====="
cd $FRONT
npm run build > $SRC/build-front.log 2>&1
echo "frontend build exit=$?"
tail -4 $SRC/build-front.log

echo "===== 7. 发布前端 + reload ====="
rm -rf /www/wwwroot/yufams/*
cp -r $FRONT/dist/* /www/wwwroot/yufams/
nginx -s reload
echo "published"

echo "===== 8. 重启后端 ====="
bash /tmp/restart89.sh
echo DONE
