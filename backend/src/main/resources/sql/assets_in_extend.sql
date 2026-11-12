-- 资产入库单扩展：采购信息 + 验收信息 + 审核信息
ALTER TABLE `assets_in`
  ADD COLUMN `name` varchar(200) DEFAULT NULL COMMENT '资产名称' AFTER `assets_id`,
  ADD COLUMN `category` varchar(100) DEFAULT NULL COMMENT '资产分类' AFTER `name`,
  ADD COLUMN `model` varchar(200) DEFAULT NULL COMMENT '规格型号' AFTER `category`,
  ADD COLUMN `money` decimal(12,2) DEFAULT NULL COMMENT '初始价值(单价)' AFTER `num`,
  ADD COLUMN `depreciate` varchar(50) DEFAULT NULL COMMENT '折旧方法' AFTER `money`,
  ADD COLUMN `purchase_no` varchar(100) DEFAULT NULL COMMENT '采购单号' AFTER `depreciate`,
  ADD COLUMN `supplier` varchar(200) DEFAULT NULL COMMENT '供应商' AFTER `purchase_no`,
  ADD COLUMN `department_id` int(11) DEFAULT NULL COMMENT '使用部门ID' AFTER `supplier`,
  ADD COLUMN `manager_id` int(11) DEFAULT NULL COMMENT '责任人ID' AFTER `department_id`,
  ADD COLUMN `location` varchar(200) DEFAULT NULL COMMENT '存放地点' AFTER `manager_id`,
  ADD COLUMN `img` varchar(500) DEFAULT NULL COMMENT '资产图片' AFTER `location`,
  ADD COLUMN `accept_date` varchar(20) DEFAULT NULL COMMENT '验收日期' AFTER `date`,
  ADD COLUMN `accept_user` varchar(100) DEFAULT NULL COMMENT '验收人' AFTER `accept_date`,
  ADD COLUMN `accept_result` varchar(500) DEFAULT NULL COMMENT '验收意见' AFTER `accept_user`,
  ADD COLUMN `audit_user` varchar(100) DEFAULT NULL COMMENT '审核人' AFTER `status`,
  ADD COLUMN `audit_date` varchar(30) DEFAULT NULL COMMENT '审核日期' AFTER `audit_user`,
  ADD COLUMN `reject_reason` varchar(500) DEFAULT NULL COMMENT '驳回原因' AFTER `audit_date`;

-- 历史入库单补名称，避免空展示
UPDATE `assets_in` ai LEFT JOIN `assets` a ON ai.assets_id = a.id
SET ai.name = a.name, ai.category = a.category
WHERE ai.name IS NULL AND a.id IS NOT NULL;
