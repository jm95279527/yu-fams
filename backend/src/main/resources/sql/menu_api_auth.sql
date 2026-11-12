-- ============================================================
-- 接口级鉴权：为 sys_menu 增加 api 字段，记录该菜单控制的后端接口路径前缀
-- 多个前缀用逗号分隔；拦截器按当前角色被授予的菜单 api 前缀做前缀匹配
-- ============================================================

ALTER TABLE sys_menu ADD COLUMN api VARCHAR(255) DEFAULT NULL COMMENT '该菜单控制的后端接口路径前缀，多个用逗号分隔' AFTER path;

-- 菜单 → 后端接口前缀映射（与各 Controller @RequestMapping 对应）
UPDATE sys_menu SET api = '/dashboard'                       WHERE id = 1;   -- 资产驾驶舱
UPDATE sys_menu SET api = '/assets,/asset,/assetsDetail'     WHERE id = 11;  -- 固定资产台账（含操作日志只读）
UPDATE sys_menu SET api = '/assetsIn'                        WHERE id = 12;  -- 资产入库
UPDATE sys_menu SET api = '/assetsTransfer'                  WHERE id = 13;  -- 资产调拨
UPDATE sys_menu SET api = '/assetsReceive'                   WHERE id = 14;  -- 资产领用
UPDATE sys_menu SET api = '/assetsInventory,/inventory'      WHERE id = 15;  -- 资产盘点
UPDATE sys_menu SET api = '/assetsRepair'                    WHERE id = 16;  -- 资产维修
UPDATE sys_menu SET api = '/assetsScrap'                     WHERE id = 17;  -- 资产报废
UPDATE sys_menu SET api = '/staffAssets'                     WHERE id = 18;  -- 个人资产
UPDATE sys_menu SET api = '/category'                        WHERE id = 21;  -- 资产分类
UPDATE sys_menu SET api = '/department'                      WHERE id = 22;  -- 部门信息
UPDATE sys_menu SET api = '/numberRule'                      WHERE id = 23;  -- 资产编码规则
UPDATE sys_menu SET api = NULL                               WHERE id = 24;  -- 自定义字段（占位页无后端）
UPDATE sys_menu SET api = '/role,/menu'                      WHERE id = 41;  -- 角色权限
UPDATE sys_menu SET api = '/admin'                           WHERE id = 42;  -- 管理员信息
UPDATE sys_menu SET api = '/staff'                           WHERE id = 43;  -- 员工信息
UPDATE sys_menu SET api = '/notice'                          WHERE id = 51;  -- 公告信息
UPDATE sys_menu SET api = '/assetsDetail'                    WHERE id = 52;  -- 日志审计（操作日志）

-- 目录节点不需要 api
UPDATE sys_menu SET api = NULL WHERE type = 1;
