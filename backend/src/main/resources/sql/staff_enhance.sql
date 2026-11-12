-- 员工表增强：增加职位、入职日期、状态字段
ALTER TABLE staff ADD COLUMN position VARCHAR(100) DEFAULT NULL COMMENT '职位' AFTER department_id;
ALTER TABLE staff ADD COLUMN entry_date DATE DEFAULT NULL COMMENT '入职日期' AFTER position;
ALTER TABLE staff ADD COLUMN status VARCHAR(20) DEFAULT '在职' COMMENT '状态：在职/离职' AFTER entry_date;
