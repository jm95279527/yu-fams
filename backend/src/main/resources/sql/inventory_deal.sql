-- 资产盘点增强：差异处理闭环字段
ALTER TABLE inventory_item
  ADD COLUMN deal_status   VARCHAR(10)  NULL COMMENT '差异处理状态：待处理/已处理（正常与未盘项为空）' AFTER item_status,
  ADD COLUMN deal_type     VARCHAR(30)  NULL COMMENT '处理方式' AFTER deal_status,
  ADD COLUMN deal_remark   VARCHAR(300) NULL COMMENT '处理说明' AFTER deal_type,
  ADD COLUMN deal_user_id  INT          NULL COMMENT '处理人ID' AFTER deal_remark,
  ADD COLUMN deal_user     VARCHAR(50)  NULL COMMENT '处理人姓名' AFTER deal_user_id,
  ADD COLUMN deal_time     VARCHAR(30)  NULL COMMENT '处理时间' AFTER deal_user;

ALTER TABLE inventory_task
  ADD COLUMN pending_diff_count INT NOT NULL DEFAULT 0 COMMENT '待处理差异数' AFTER abnormal_count;
