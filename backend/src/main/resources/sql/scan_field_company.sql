-- ============================================================
-- 扫码页字段新增「所属公司」：把 company 追加到已保存的 scan_fields
-- 仅当已配置过字段（非空）且尚未包含 company 时追加，避免覆盖用户已取消的全不选
-- ============================================================
UPDATE `sys_config`
SET `config_value` = CONCAT(`config_value`, ',company')
WHERE `config_key` = 'scan_fields'
  AND `config_value` IS NOT NULL
  AND `config_value` <> ''
  AND FIND_IN_SET('company', `config_value`) = 0;
