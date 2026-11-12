-- ============================================================
-- 角色权限模块：角色表 / 菜单表 / 角色菜单关联表
-- 权限粒度：菜单级。admin 账户通过 role_id 关联角色；STAFF 员工保持固定菜单
-- ============================================================

-- 角色表
CREATE TABLE IF NOT EXISTS sys_role (
  id INT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
  name VARCHAR(64) NOT NULL COMMENT '角色名称',
  code VARCHAR(64) NOT NULL COMMENT '角色标识（如 SUPER_ADMIN）',
  description VARCHAR(255) COMMENT '角色描述',
  sort INT DEFAULT 0 COMMENT '排序',
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  UNIQUE KEY uk_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统角色';

-- 菜单表
CREATE TABLE IF NOT EXISTS sys_menu (
  id INT PRIMARY KEY COMMENT '菜单ID（固定编号）',
  parent_id INT DEFAULT 0 COMMENT '父菜单ID，0=顶级',
  name VARCHAR(64) NOT NULL COMMENT '菜单名称',
  path VARCHAR(128) COMMENT '路由路径（目录为空）',
  api VARCHAR(255) COMMENT '该菜单控制的后端接口路径前缀，多个用逗号分隔',
  icon VARCHAR(64) COMMENT '图标 class',
  type TINYINT DEFAULT 2 COMMENT '类型：1=目录 2=菜单',
  sort INT DEFAULT 0 COMMENT '排序',
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统菜单';

-- 角色菜单关联表
CREATE TABLE IF NOT EXISTS sys_role_menu (
  role_id INT NOT NULL COMMENT '角色ID',
  menu_id INT NOT NULL COMMENT '菜单ID',
  PRIMARY KEY (role_id, menu_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色菜单关联';

-- admin 表增加角色ID（角色权限用；role 列保留，仍为 ADMIN/STAFF 用户类型）
ALTER TABLE admin ADD COLUMN role_id INT NULL COMMENT '系统角色ID' AFTER role;

-- ============================================================
-- 菜单种子（与前端 Manager.vue 菜单一致）
-- ============================================================
INSERT INTO sys_menu (id, parent_id, name, path, api, icon, type, sort) VALUES
  -- 驾驶舱（顶级单菜单）
  (1,  0,  '资产驾驶舱',        '/home',          '/dashboard',                       'el-icon-data-analysis', 2, 1),
  -- 资产管理目录
  (10, 0,  '资产管理',          NULL,             NULL,                                'el-icon-box',           1, 10),
  (11, 10, '固定资产台账',      '/assets',        '/assets,/asset,/assetsDetail',     NULL,                    2, 1),
  (12, 10, '资产入库',          '/assetsIn',      '/assetsIn',                        NULL,                    2, 2),
  (13, 10, '资产调拨',          '/assetsTransfer','/assetsTransfer',                  NULL,                    2, 3),
  (14, 10, '资产领用',          '/assetsReceive', '/assetsReceive',                   NULL,                    2, 4),
  (15, 10, '资产盘点',          '/assetsInventory','/assetsInventory,/inventory',     NULL,                    2, 5),
  (16, 10, '资产维修',          '/assetsRepair',  '/assetsRepair',                    NULL,                    2, 6),
  (17, 10, '资产报废',          '/assetsScrap',   '/assetsScrap',                     NULL,                    2, 7),
  (18, 10, '个人资产',          '/staffAssets',   '/staffAssets',                     NULL,                    2, 8),
  -- 基础资料目录
  (20, 0,  '基础资料',          NULL,             NULL,                                'el-icon-notebook-2',    1, 20),
  (21, 20, '资产分类',          '/category',      '/category',                        NULL,                    2, 1),
  (22, 20, '部门信息',          '/department',    '/department',                      NULL,                    2, 2),
  (23, 20, '资产编码规则',      '/numberRule',    '/numberRule',                      NULL,                    2, 3),
  (24, 20, '自定义字段',        '/customFields',  NULL,                                NULL,                    2, 4),
  -- 系统集成目录
  (30, 0,  '系统集成',          NULL,             NULL,                                'el-icon-connection',     1, 30),
  -- 权限管理目录
  (40, 0,  '权限管理',          NULL,             NULL,                                'el-icon-key',           1, 40),
  (41, 40, '角色权限',          '/rolePerm',      '/role,/menu',                      NULL,                    2, 1),
  (42, 40, '管理员信息',        '/admin',         '/admin',                           NULL,                    2, 2),
  (43, 40, '员工信息',          '/staff',         '/staff',                           NULL,                    2, 3),
  -- 系统管理目录
  (50, 0,  '系统管理',          NULL,             NULL,                                'el-icon-setting',       1, 50),
  (51, 50, '公告信息',          '/notice',        '/notice',                          NULL,                    2, 1),
  (52, 50, '日志审计',          '/auditLog',      '/assetsDetail',                    NULL,                    2, 2);

-- ============================================================
-- 角色种子
-- ============================================================
INSERT INTO sys_role (id, name, code, description, sort) VALUES
  (1, '超级管理员', 'SUPER_ADMIN', '拥有系统全部菜单权限，可管理角色与管理员', 1),
  (2, '资产管理员', 'ASSET_ADMIN', '负责资产全流程与基础资料，不能分配权限和查看审计日志', 2),
  (3, '只读人员',   'VIEWER',      '仅可查看资产驾驶舱、固定资产台账和公告', 3);

-- 超级管理员：全部菜单（代码中也对 SUPER_ADMIN 直接放行全部菜单）
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, id FROM sys_menu;

-- 资产管理员：驾驶舱 + 资产管理全部 + 基础资料全部 + 集成 + 公告（无权限管理、无日志审计）
INSERT INTO sys_role_menu (role_id, menu_id) VALUES
  (2,1),
  (2,10),(2,11),(2,12),(2,13),(2,14),(2,15),(2,16),(2,17),(2,18),
  (2,20),(2,21),(2,22),(2,23),(2,24),
  (2,30),(2,31),
  (2,50),(2,51);

-- 只读人员：驾驶舱 + 台账 + 公告
INSERT INTO sys_role_menu (role_id, menu_id) VALUES
  (3,1),
  (3,10),(3,11),
  (3,50),(3,51);

-- 现有 admin（id=4 系统管理员）绑定超级管理员角色
UPDATE admin SET role_id = 1 WHERE id = 4;
