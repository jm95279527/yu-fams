-- 盘点明细增加资产型号快照（盘点报告展示）
ALTER TABLE inventory_item ADD COLUMN model VARCHAR(100) NULL COMMENT '资产型号（快照）' AFTER assets_name;

-- 历史盘点明细回填型号
UPDATE inventory_item ii
JOIN assets a ON ii.assets_id = a.id
SET ii.model = a.model
WHERE ii.model IS NULL;
