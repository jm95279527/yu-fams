-- ============================================================
-- 报修表单调整：
-- 1) 报修理由与故障描述合并为一个字段（统一用 fault_desc，旧数据回退用 reason）
-- 2) 增加报修照片（非必填）
-- ============================================================

SET @s = (SELECT IF(
  (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'assets_repair' AND column_name = 'img') = 0,
  'ALTER TABLE `assets_repair` ADD COLUMN `img` varchar(255) DEFAULT NULL COMMENT ''报修照片'' AFTER `fault_desc`',
  'SELECT 1'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- 通知模板：两行合并为一行「故障描述」
UPDATE `notify_template`
   SET `content` = REPLACE(`content`, '> 报修理由：{reason}\n> 故障描述：{faultDesc}', '> 故障描述：{faultDesc}')
 WHERE `event_key` LIKE 'REPAIR%' AND `content` LIKE '%报修理由%';
