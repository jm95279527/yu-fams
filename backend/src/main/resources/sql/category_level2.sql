-- ============================================================
-- 资产分类支持二级关联
-- category.pid：上级分类ID，0 表示一级分类
-- 现有分类自动作为一级分类，不影响已有资产
-- 可重复执行
-- ============================================================

DROP PROCEDURE IF EXISTS `add_category_pid`;
DELIMITER //
CREATE PROCEDURE `add_category_pid`()
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'category' AND column_name = 'pid'
  ) THEN
    ALTER TABLE `category`
      ADD COLUMN `pid` INT NOT NULL DEFAULT 0 COMMENT '上级分类ID，0=一级分类' AFTER `code`;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'category' AND index_name = 'idx_category_pid'
  ) THEN
    ALTER TABLE `category` ADD INDEX `idx_category_pid` (`pid`);
  END IF;
END//
DELIMITER ;

CALL `add_category_pid`();
DROP PROCEDURE `add_category_pid`;

-- 修正历史空值
UPDATE `category` SET `pid` = 0 WHERE `pid` IS NULL;
