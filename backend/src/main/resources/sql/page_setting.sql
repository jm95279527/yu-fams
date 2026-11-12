-- ============================================================
-- 「页面设置」：站点级可配置项（系统名称/登录壁纸/Logo/页脚等）
-- ============================================================

CREATE TABLE IF NOT EXISTS `sys_config` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `config_key` varchar(50) NOT NULL COMMENT '配置键',
  `config_value` varchar(500) DEFAULT NULL COMMENT '配置值',
  `remark` varchar(200) DEFAULT NULL COMMENT '说明',
  `update_time` varchar(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='页面/站点配置';

-- 默认配置（留空表示使用系统内置默认值）
INSERT INTO `sys_config` (`config_key`, `config_value`, `remark`) VALUES
('system_name',       '固定资产管理系统',                       '系统名称（后台顶栏、登录页标题、浏览器标签）'),
('browser_title',     '固定资产管理系统',                       '浏览器标签标题（留空则跟随系统名称）'),
('login_subtitle',    '欢迎使用',                               '登录页副标题'),
('login_bg',          '',                                        '登录页壁纸图片地址（留空用内置背景图）'),
('logo',              '',                                        'Logo 图片地址（留空用内置 Logo）'),
('footer_text',       '',                                        '页脚版权信息（留空则不显示页脚）'),
('dashboard_welcome', '欢迎使用固定资产管理系统',                '驾驶舱欢迎词（显示为「您好，XXX！欢迎词」）')
ON DUPLICATE KEY UPDATE `remark` = VALUES(`remark`), `update_time` = NOW();

-- 菜单：页面设置（挂「系统管理」parent_id=50 下，固定编号 56）
INSERT INTO `sys_menu` (`id`,`parent_id`,`name`,`path`,`api`,`icon`,`type`,`sort`)
SELECT 56,50,'页面设置','/pageSetting','/sysConfig',NULL,2,3 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT * FROM `sys_menu`) m WHERE m.`path` = '/pageSetting');

-- 已拥有「系统管理(id=50)」权限的角色同步获得
INSERT IGNORE INTO `sys_role_menu` (`role_id`,`menu_id`)
SELECT rm.`role_id`, 56 FROM `sys_role_menu` rm WHERE rm.`menu_id` = 50;
