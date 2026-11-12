-- ============================================================
-- 分子公司 + 部门挂公司 + 公司信息菜单
-- ============================================================

-- 公司表
CREATE TABLE IF NOT EXISTS `company` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `name` varchar(100) NOT NULL COMMENT '公司名称',
  `sort` int DEFAULT 0 COMMENT '排序',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` varchar(20) DEFAULT NULL,
  `update_time` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='分子公司';

-- 部门增加所属公司
SET @s = (SELECT IF(
  (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'department' AND column_name = 'company_id') = 0,
  'ALTER TABLE `department` ADD COLUMN `company_id` int DEFAULT NULL COMMENT ''所属公司ID''',
  'SELECT 1'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- 菜单：公司信息（挂「基础资料」parent_id=20 下，固定编号 55）
INSERT INTO `sys_menu` (`id`,`parent_id`,`name`,`path`,`api`,`icon`,`type`,`sort`)
SELECT 55,20,'公司信息','/company','/company',NULL,2,5 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT * FROM `sys_menu`) m WHERE m.`path` = '/company');

-- 已有「基础资料(id=20)」权限的角色同步获得
INSERT IGNORE INTO `sys_role_menu` (`role_id`,`menu_id`)
SELECT rm.`role_id`, 55 FROM `sys_role_menu` rm WHERE rm.`menu_id` = 20;
