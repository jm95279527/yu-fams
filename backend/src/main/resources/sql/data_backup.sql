-- 数据备份功能：系统管理 → 数据备份 菜单 + 默认配置
INSERT INTO sys_menu(id, parent_id, name, path, api, icon, type, sort)
SELECT 57, 50, '数据备份', '/dataBackup', '/dataBackup', 'el-icon-folder-opened', 2, 4
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE id = 57 OR path = '/dataBackup');

INSERT INTO sys_role_menu(role_id, menu_id)
SELECT 1, 57
FROM DUAL
WHERE EXISTS (SELECT 1 FROM sys_menu WHERE id = 57)
  AND NOT EXISTS (SELECT 1 FROM sys_role_menu WHERE role_id = 1 AND menu_id = 57);

INSERT INTO sys_config(config_key, config_value, remark, update_time)
SELECT 'backup_enabled', '0', '定时备份开关：1开启 0关闭', DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_config WHERE config_key = 'backup_enabled');

INSERT INTO sys_config(config_key, config_value, remark, update_time)
SELECT 'backup_time', '02:00', '定时备份时间 HH:mm', DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_config WHERE config_key = 'backup_time');

INSERT INTO sys_config(config_key, config_value, remark, update_time)
SELECT 'backup_keep', '7', '定时备份保留份数', DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_config WHERE config_key = 'backup_keep');
