-- ============================================================
-- 申请提交即推送群通知（管理员看到通知再去审核）
-- 新增 5 个「提交」模板，默认启用
-- 事件：RECEIVE_SUBMIT 借用 / REPAIR_SUBMIT 维修 / ASSETS_IN_SUBMIT 入库
--       TRANSFER_SUBMIT 调拨 / SCRAP_SUBMIT 报废
-- ============================================================
INSERT INTO `notify_template` (`event_key`,`biz_type`,`event_name`,`enabled`,`title`,`content`,`create_time`) VALUES
('RECEIVE_SUBMIT','借用','借用申请提交',1,'新的资产借用申请待审核',
 '**新的资产借用申请待审核**\n> 资产：{assetsName}（{assetsNo}）\n> 借用人：{applicant}\n> 联系方式：{borrowerPhone}\n> 预计归还：{returnDate}\n> 备注：{comment}\n> 提交时间：{time}\n> 请到「资产借用」页审核',NOW()),

('REPAIR_SUBMIT','维修','报修申请提交',1,'新的资产报修申请待处理',
 '**新的资产报修申请待处理**\n> 资产：{assetsName}（{assetsCode}）\n> 报修人：{applicant}\n> 报修电话：{reporterPhone}\n> 报修理由：{reason}\n> 故障描述：{faultDesc}\n> 提交时间：{time}\n> 请到「资产维修」页处理',NOW()),

('ASSETS_IN_SUBMIT','入库','入库单提交',1,'新的资产入库单待审核',
 '**新的资产入库单待审核**\n> 资产：{assetsName}\n> 资产分类：{category}\n> 采购单号：{purchaseNo}\n> 数量：{num}\n> 金额：{money}\n> 提交人：{applicant}\n> 提交时间：{time}\n> 请到「资产入库」页审核',NOW()),

('TRANSFER_SUBMIT','调拨','调拨申请提交',1,'新的资产调拨申请待审批',
 '**新的资产调拨申请待审批**\n> 资产：{assetsName}（{assetsNo}）\n> 调拨：{fromText} → {toText}\n> 调拨原因：{reason}\n> 申请人：{applicant}\n> 提交时间：{time}\n> 请到「资产调拨」页审批',NOW()),

('SCRAP_SUBMIT','报废','报废申请提交',1,'新的资产报废申请待审批',
 '**新的资产报废申请待审批**\n> 资产：{assetsName}（{assetsNo}）\n> 报废类型：{scrapType}\n> 报废原因：{reason}\n> 申请人：{applicant}\n> 提交时间：{time}\n> 请到「资产报废」页审批',NOW()),

-- Excel 批量导入入库：只在导入完成时汇总推送一条
('ASSETS_IN_BATCH','入库','入库批量导入',1,'资产入库批量导入待审核',
 '**资产入库批量导入待审核**\n> 导入条数：{count} 条\n> 涉及资产：{detail}\n> 提交人：{applicant}\n> 提交时间：{time}\n> 请到「资产入库」页审核',NOW())
ON DUPLICATE KEY UPDATE `update_time` = NOW();
