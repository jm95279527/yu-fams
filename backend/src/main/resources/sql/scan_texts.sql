-- ============================================================
-- 扫码页「固定文字」可配置：在「系统管理 → 页面设置」里修改
-- 留空则使用内置默认文字
-- ============================================================
INSERT INTO `sys_config` (`config_key`, `config_value`, `remark`) VALUES
('scan_title',       '资产信息',         '扫码页卡片标题'),
('scan_footer',      '固定资产管理系统', '扫码页底部文字'),
('scan_borrow_text', '申请借用',         '扫码页借用按钮文字'),
('scan_repair_text', '申请报修',         '扫码页报修按钮文字')
ON DUPLICATE KEY UPDATE `remark` = VALUES(`remark`);
