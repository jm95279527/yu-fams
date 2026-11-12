-- ============================================================
-- 彻底删除已废弃的企微/钉钉集成数据对象
-- 前置：相关 Java/Vue 代码与「企业微信/钉钉集成」菜单已于 2026-10-15 移除；
--      执行前请先备份 /opt/yu-fams/backup/integration_dropped.sql.gz
-- ============================================================

-- 1) 三张集成配置表
DROP TABLE IF EXISTS `wechat_work_config`;
DROP TABLE IF EXISTS `dingtalk_config`;
DROP TABLE IF EXISTS `third_party_user`;

-- 2) 两个集成用字段（MySQL 不支持 DROP COLUMN IF EXISTS，用 information_schema 动态执行，保证可重复执行）
SET @s = (SELECT IF(
  (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'staff' AND column_name = 'wx_userid') > 0,
  'ALTER TABLE `staff` DROP COLUMN `wx_userid`',
  'SELECT 1'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s = (SELECT IF(
  (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'department' AND column_name = 'wx_dept_id') > 0,
  'ALTER TABLE `department` DROP COLUMN `wx_dept_id`',
  'SELECT 1'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
