-- 盘点单手机扫码入口：新增 access_code 访问码
ALTER TABLE inventory_task ADD COLUMN access_code VARCHAR(64) NULL COMMENT '手机盘点访问码' AFTER id;

-- 历史盘点任务补访问码
UPDATE inventory_task SET access_code = REPLACE(UUID(), '-', '') WHERE access_code IS NULL OR access_code = '';

ALTER TABLE inventory_task MODIFY COLUMN access_code VARCHAR(64) NOT NULL COMMENT '手机盘点访问码';

ALTER TABLE inventory_task ADD UNIQUE INDEX uk_inventory_access_code (access_code);
