-- ============================================================
-- 基础资料 → 自定义字段
-- 1) 资产字段配置表（系统字段改名 + 10 个自定义字段位）
-- 2) assets 表新增 custom1 ~ custom10
-- 3) 菜单 24「自定义字段」绑定接口并授权资产管理员
-- 可重复执行：不会覆盖已修改的字段名称
-- ============================================================

CREATE TABLE IF NOT EXISTS `asset_field_config` (
  `id` int NOT NULL AUTO_INCREMENT,
  `field_key` varchar(50) NOT NULL COMMENT '字段标识：系统字段=实体属性名，自定义字段=custom1..custom10',
  `label` varchar(50) NOT NULL COMMENT '显示名称',
  `field_type` varchar(20) NOT NULL DEFAULT 'text' COMMENT 'text/number/date/select',
  `options` varchar(500) DEFAULT NULL COMMENT '下拉选项，逗号分隔',
  `enabled` tinyint NOT NULL DEFAULT 1 COMMENT '1启用 0停用',
  `is_system` tinyint NOT NULL DEFAULT 0 COMMENT '1系统字段 0自定义字段',
  `sort_num` int NOT NULL DEFAULT 0,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_field_key` (`field_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资产字段配置';

-- 系统字段（排序与台账展示顺序一致）
INSERT INTO `asset_field_config` (`field_key`, `label`, `field_type`, `enabled`, `is_system`, `sort_num`) VALUES
('no',             '资产编号', 'text', 1, 1, 10),
('name',           '资产名称', 'text', 1, 1, 20),
('category',       '资产分类', 'text', 1, 1, 30),
('img',            '资产图片', 'text', 1, 1, 40),
('model',          '资产型号', 'text', 1, 1, 50),
('num',            '数量',     'number', 1, 1, 60),
('date',           '购置日期', 'date', 1, 1, 70),
('money',          '初始价值', 'number', 1, 1, 80),
('depreciate',     '折旧方法', 'text', 1, 1, 90),
('companyName',    '所属公司', 'text', 1, 1, 100),
('departmentName', '使用部门', 'text', 1, 1, 110),
('staffName',      '责任人',   'text', 1, 1, 120),
('location',       '存放地点', 'text', 1, 1, 130),
('status',         '资产状态', 'text', 1, 1, 140),
('comment',        '备注',     'text', 1, 1, 150)
ON DUPLICATE KEY UPDATE `id` = `id`;

-- 自定义字段位（默认停用，在页面上填写名称并启用后生效）
INSERT INTO `asset_field_config` (`field_key`, `label`, `field_type`, `enabled`, `is_system`, `sort_num`) VALUES
('custom1',  '自定义字段1',  'text', 0, 0, 201),
('custom2',  '自定义字段2',  'text', 0, 0, 202),
('custom3',  '自定义字段3',  'text', 0, 0, 203),
('custom4',  '自定义字段4',  'text', 0, 0, 204),
('custom5',  '自定义字段5',  'text', 0, 0, 205),
('custom6',  '自定义字段6',  'text', 0, 0, 206),
('custom7',  '自定义字段7',  'text', 0, 0, 207),
('custom8',  '自定义字段8',  'text', 0, 0, 208),
('custom9',  '自定义字段9',  'text', 0, 0, 209),
('custom10', '自定义字段10', 'text', 0, 0, 210)
ON DUPLICATE KEY UPDATE `id` = `id`;

-- assets 表新增自定义字段列（可重复执行）
DROP PROCEDURE IF EXISTS `add_asset_custom_columns`;
DELIMITER //
CREATE PROCEDURE `add_asset_custom_columns`()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 10 DO
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'assets'
        AND column_name = CONCAT('custom', i)
    ) THEN
      SET @ddl = CONCAT('ALTER TABLE assets ADD COLUMN custom', i, ' VARCHAR(255) NULL');
      PREPARE stmt FROM @ddl;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END IF;
    SET i = i + 1;
  END WHILE;
END//
DELIMITER ;
CALL `add_asset_custom_columns`();
DROP PROCEDURE `add_asset_custom_columns`;

-- 菜单 24「自定义字段」绑定接口；资产管理员可维护基础资料
UPDATE `sys_menu` SET `api` = '/assetField' WHERE `id` = 24;
INSERT IGNORE INTO `sys_role_menu` (`role_id`, `menu_id`) VALUES (2, 24);
