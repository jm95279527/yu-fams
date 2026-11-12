-- ============================================================
-- 员工信息菜单移入「基础资料」+ 基础资料排序调整 + 角色授权补齐
-- ============================================================

-- 1) 员工信息（id=43）从「权限管理(40)」移到「基础资料(20)」
UPDATE `sys_menu` SET `parent_id` = 20 WHERE `id` = 43;

-- 2) 基础资料下排序：公司 → 部门 → 员工 → 资产分类 → 编码规则 → 自定义字段
UPDATE `sys_menu` SET `sort` = 1 WHERE `id` = 55;  -- 公司信息
UPDATE `sys_menu` SET `sort` = 2 WHERE `id` = 22;  -- 部门信息
UPDATE `sys_menu` SET `sort` = 3 WHERE `id` = 43;  -- 员工信息
UPDATE `sys_menu` SET `sort` = 4 WHERE `id` = 21;  -- 资产分类
UPDATE `sys_menu` SET `sort` = 5 WHERE `id` = 23;  -- 资产编码规则
UPDATE `sys_menu` SET `sort` = 6 WHERE `id` = 24;  -- 自定义字段

-- 3) 已拥有「基础资料(20)」的角色同步获得「员工信息(43)」
INSERT IGNORE INTO `sys_role_menu` (`role_id`, `menu_id`)
SELECT rm.`role_id`, 43 FROM `sys_role_menu` rm WHERE rm.`menu_id` = 20;
