-- ============================================================
-- 扫码页「显示字段」可配置：在「系统管理 → 页面设置」里勾选
-- 默认值为当前已在显示的字段（数量 num、折旧方法 depreciate 默认不显示，勾上即增加）
-- ============================================================
INSERT INTO `sys_config` (`config_key`, `config_value`, `remark`) VALUES
('scan_fields',
 'no,category,company,model,status,date,money,departmentName,staffName,location,comment,img',
 '扫码页显示字段（逗号分隔）')
ON DUPLICATE KEY UPDATE `remark` = VALUES(`remark`);
