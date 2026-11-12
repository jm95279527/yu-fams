# Yu-FAMS 固定资产管理系统

Yu-FAMS 是一套面向企业内部的固定资产全生命周期管理系统，覆盖资产台账、领用借用、调拨、报废、盘点、提醒通知与数据备份等业务。

## 技术栈

| 层次 | 技术 |
| --- | --- |
| 后端 | Spring Boot 2.5.9、MyBatis、PageHelper、Hutool、ZXing、JWT（JDK 8） |
| 前端 | Vue 2.6、Element UI 2.15、Axios、ECharts（Node.js 14+） |
| 数据库 | MySQL 8.0（库名 `xm-assets`） |
| 部署 | Nginx 静态站点 + Spring Boot systemd 服务 |

## 仓库结构

```
backend/                Spring Boot 后端源码
  src/main/java/        业务代码（controller/service/mapper/entity）
  src/main/resources/
    application.yml     数据库、端口、二维码域名等配置
    mapper/*.xml        MyBatis 映射
    sql/                数据库增量脚本（按功能命名）
frontend/               Vue 2 前端源码（src、public、package.json 等）
deploy/                 部署与运维脚本
  nginx-yufams.conf     Nginx 站点配置（88 端口，/api 反代后端）
  yufams.service        systemd 服务单元（后端 89 端口）
sql/xm-assets-base.sql.gz   基础库（表结构 + 初始菜单/角色等数据）
README.md               本文档
```

## 功能模块

- **资产台账**：增删改查、批量导入导出（含所属公司/使用部门/使用人/备注）、二维码、自定义字段、图片、编号规则
- **基础资料**：公司、部门、员工、资产分类、存放地点
- **资产业务**：领用、借用/归还、调拨（支持批量导入）、报废、维修
- **资产盘点**：按全部/部门/公司/分类创建盘点单，盘点二维码 + 手机扫码（已盘/未盘），差异处理、盘点报告（含资产型号）
- **系统管理**：用户、角色、菜单与接口级权限、系统配置、页面字段配置
- **消息提醒**：借用到期、盘点提醒
- **数据备份**：手动/定时全量备份（数据库 + 上传文件）、恢复、导入导出

## 全新部署步骤

### 1. 准备环境

- JDK 8、Maven 3.6+
- Node.js 14+（建议 16）、npm
- MySQL 8.0
- Nginx

### 2. 初始化数据库

```bash
# 创建数据库
mysql -uroot -p -e "CREATE DATABASE \`xm-assets\` DEFAULT CHARACTER SET utf8mb4;"

# 导入基础库（表结构 + 初始数据）
gunzip -c sql/xm-assets-base.sql.gz | mysql -uroot -p xm-assets
```

说明：`backend/src/main/resources/sql/` 下为各次迭代的增量脚本，全新部署使用上面的基础库即可；从旧版本升级时按脚本依次执行。基础库已包含初始菜单/角色等数据，首次部署后请按需在「系统管理 → 用户管理」中维护账号。

### 3. 构建并启动后端

```bash
cd backend
mvn clean package -DskipTests
# 产物：target/springboot-0.0.1-SNAPSHOT.jar

# 前台调试
java -jar target/springboot-0.0.1-SNAPSHOT.jar --server.port=89
```

使用 systemd 托管：

```bash
cp deploy/yufams.service /etc/systemd/system/yufams.service
# 按实际 JDK/安装路径修改 ExecStart 与 WorkingDirectory
systemctl daemon-reload
systemctl enable --now yufams
systemctl status yufams
```

> `application.yml` 默认端口为 9091，生产环境通过启动参数 `--server.port=89` 指定为 89。
> 如数据库账号、密码、地址不同，请同步修改 `application.yml`；`ip` 与 `front-base-url` 需改为扫码设备可访问的地址。

### 4. 构建并发布前端

```bash
cd frontend
npm install
npm run build
# 产物：dist/
```

将 `dist/` 内容发布到 Nginx 站点目录（示例：`/www/wwwroot/yufams`）：

```bash
rm -rf /www/wwwroot/yufams/*
cp -r dist/* /www/wwwroot/yufams/
chown -R www:www /www/wwwroot/yufams
```

### 5. 配置 Nginx

```bash
cp deploy/nginx-yufams.conf /etc/nginx/conf.d/yufams.conf
# 按实际发布目录、端口调整 root 与 proxy_pass
nginx -t && nginx -s reload
```

默认：前端 88 端口，`/api/` 反向代理到 `127.0.0.1:89/`，`/files/` 代理到后端上传目录。

### 6. 运行目录说明

- 后端工作目录下会自动使用 `files/` 存放上传的图片/附件，`backup/` 存放数据备份 zip；请确保服务账号有写权限。
- 二维码链接基于 `front-base-url` 生成，需保证扫码手机能访问该地址。

## 数据备份/恢复

登录后在「系统关联 → 数据备份」可手动备份、上传备份包、恢复、下载以及配置定时备份（数据库 + `files/` 上传文件）。备份文件位于后端工作目录的 `backup/`。

## 安全提示

- `backend/src/main/resources/application.yml` 含数据库、JWT 等配置；本仓库为私有仓库，转公开前请替换为占位值并轮换全部密钥。
- `sql/xm-assets-base.sql.gz` 含初始账号/菜单数据，请仅在受控环境使用。
- `deploy/` 下脚本包含服务器地址与运维命令，请勿外传。
