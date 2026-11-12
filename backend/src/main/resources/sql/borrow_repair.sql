-- ============================================================
-- 1) 资产领用 → 资产借用（文案）
-- 2) 借用单增加：借用人姓名（手工填写）、联系方式（手机号）
-- 3) 报修单增加：报修人姓名（手工填写）、报修电话
-- 4) 扫码页任何人可提交借用/报修（接口 /scan/** 已放行）
-- 注意：表名/列名/接口路径等内部标识保持不变，仅改用户可见文案
-- ============================================================

-- ---------- 借用单新增字段（重复执行安全）----------
SET @s = (SELECT IF(
  (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'assets_receive' AND column_name = 'borrower_name') = 0,
  'ALTER TABLE `assets_receive` ADD COLUMN `borrower_name` varchar(50) DEFAULT NULL COMMENT ''借用人姓名（手工填写）'' AFTER `staff_id`',
  'SELECT 1'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s = (SELECT IF(
  (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'assets_receive' AND column_name = 'borrower_phone') = 0,
  'ALTER TABLE `assets_receive` ADD COLUMN `borrower_phone` varchar(20) DEFAULT NULL COMMENT ''借用人联系方式'' AFTER `borrower_name`',
  'SELECT 1'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------- 报修单新增字段（重复执行安全）----------
SET @s = (SELECT IF(
  (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'assets_repair' AND column_name = 'reporter_name') = 0,
  'ALTER TABLE `assets_repair` ADD COLUMN `reporter_name` varchar(50) DEFAULT NULL COMMENT ''报修人姓名（手工填写）'' AFTER `staff_id`',
  'SELECT 1'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s = (SELECT IF(
  (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'assets_repair' AND column_name = 'reporter_phone') = 0,
  'ALTER TABLE `assets_repair` ADD COLUMN `reporter_phone` varchar(20) DEFAULT NULL COMMENT ''报修人联系方式'' AFTER `reporter_name`',
  'SELECT 1'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------- 菜单与通知模板文案：领用 → 借用 ----------
UPDATE `sys_menu` SET `name` = '资产借用' WHERE `id` = 14;

UPDATE `notify_template`
   SET `biz_type` = '借用',
       `event_name` = REPLACE(`event_name`, '领用', '借用'),
       `title` = REPLACE(`title`, '领用', '借用'),
       `content` = REPLACE(REPLACE(`content`, '领用', '借用'), '领用人', '借用人')
 WHERE `event_key` IN ('RECEIVE_PASS', 'RECEIVE_REJECT');

-- 通知内容补充联系方式（借用/报修）
UPDATE `notify_template`
   SET `content` = REPLACE(`content`, '> 借用人：{applicant}', '> 借用人：{applicant}\n> 联系方式：{borrowerPhone}')
 WHERE `event_key` LIKE 'RECEIVE%' AND `content` NOT LIKE '%{borrowerPhone}%';

UPDATE `notify_template`
   SET `content` = REPLACE(`content`, '> 报修人：{applicant}', '> 报修人：{applicant}\n> 报修电话：{reporterPhone}')
 WHERE `event_key` LIKE 'REPAIR%' AND `content` NOT LIKE '%{reporterPhone}%';
