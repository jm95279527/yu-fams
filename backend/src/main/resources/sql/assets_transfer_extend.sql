-- 资产调拨扩展：支持存放地点变更；目标部门/责任人允许为空（支持仅变更地点等部分变更）
ALTER TABLE assets_transfer
    ADD COLUMN from_location VARCHAR(200) NULL COMMENT '原存放地点' AFTER from_department_name,
    ADD COLUMN to_location   VARCHAR(200) NULL COMMENT '新存放地点' AFTER to_department_name;

ALTER TABLE assets_transfer
    MODIFY COLUMN to_staff_id INT NULL,
    MODIFY COLUMN to_staff_name VARCHAR(50) NULL,
    MODIFY COLUMN to_department_id INT NULL,
    MODIFY COLUMN to_department_name VARCHAR(50) NULL;
