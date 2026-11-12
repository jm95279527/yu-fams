-- ============================================================
-- 企微群机器人通知（替代通讯录同步方案）
-- 1) robot_config      群机器人配置（webhook）
-- 2) notify_template   通知模板（按 业务+事件 配置，可停用）
-- 3) notify_log        通知记录
-- 4) sys_menu          新增「机器人配置」「通知信息」菜单并授权
-- ============================================================

-- 群机器人配置表
CREATE TABLE IF NOT EXISTS `robot_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `name` varchar(100) NOT NULL COMMENT '机器人名称',
  `type` varchar(20) NOT NULL DEFAULT 'wechat' COMMENT '类型：wechat=企业微信群机器人',
  `webhook_url` varchar(500) NOT NULL COMMENT 'Webhook 地址',
  `secret` varchar(200) DEFAULT NULL COMMENT '加签密钥（机器人开启加签时填，未开启留空）',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='群机器人配置表';

-- 通知模板表
CREATE TABLE IF NOT EXISTS `notify_template` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `event_key` varchar(50) NOT NULL COMMENT '事件标识（如 SCRAP_PASS）',
  `biz_type` varchar(30) NOT NULL COMMENT '业务类型',
  `event_name` varchar(50) NOT NULL COMMENT '事件名称',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `title` varchar(200) DEFAULT NULL COMMENT '消息标题模板',
  `content` varchar(1000) DEFAULT NULL COMMENT '消息正文模板，支持 {占位符}',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_event_key` (`event_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通知模板表';

-- 通知记录表
CREATE TABLE IF NOT EXISTS `notify_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `event_key` varchar(50) DEFAULT NULL COMMENT '事件标识',
  `biz_type` varchar(30) DEFAULT NULL COMMENT '业务类型',
  `biz_id` int(11) DEFAULT NULL COMMENT '业务单据ID',
  `title` varchar(200) DEFAULT NULL COMMENT '推送标题',
  `content` varchar(1000) DEFAULT NULL COMMENT '推送内容',
  `robot_id` int(11) DEFAULT NULL COMMENT '机器人ID',
  `robot_name` varchar(100) DEFAULT NULL COMMENT '机器人名称',
  `status` varchar(10) DEFAULT NULL COMMENT '成功/失败',
  `response` varchar(500) DEFAULT NULL COMMENT '机器人接口返回内容',
  `create_time` varchar(20) DEFAULT NULL COMMENT '推送时间',
  PRIMARY KEY (`id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通知记录表';

-- ================= 通知模板初始数据 =================
-- 通过类默认启用
INSERT INTO `notify_template` (`event_key`,`biz_type`,`event_name`,`enabled`,`title`,`content`,`create_time`) VALUES
('SCRAP_PASS','报废','报废审批通过',1,'资产报废审批通过',
 '**资产报废审批通过**\n> 资产：{assetsName}（{assetsNo}）\n> 报废类型：{scrapType}\n> 报废原因：{reason}\n> 申请人：{applicant}\n> 审批人：{approver}\n> 时间：{time}',NOW()),
('TRANSFER_PASS','调拨','调拨审批通过',1,'资产调拨审批通过',
 '**资产调拨审批通过**\n> 资产：{assetsName}（{assetsNo}）\n> 调拨：{fromText} → {toText}\n> 调拨原因：{reason}\n> 申请人：{applicant}\n> 审批人：{approver}\n> 时间：{time}',NOW()),
('ASSETS_IN_PASS','入库','入库审核通过',1,'资产入库审核通过',
 '**资产入库审核通过**\n> 资产：{assetsName}\n> 资产分类：{category}\n> 采购单号：{purchaseNo}\n> 数量：{num}\n> 金额：{money}\n> 提交人：{applicant}\n> 审核人：{approver}\n> 时间：{time}',NOW()),
('RECEIVE_PASS','领用','领用审核通过',1,'资产领用审核通过',
 '**资产领用审核通过**\n> 资产：{assetsName}（{assetsNo}）\n> 领用人：{applicant}\n> 预计归还：{returnDate}\n> 审核人：{approver}\n> 时间：{time}',NOW()),
('REPAIR_PASS','维修','维修状态变更',1,'资产维修状态变更',
 '**资产维修状态变更**\n> 资产：{assetsName}（{assetsCode}）\n> 当前状态：{status}\n> 报修理由：{reason}\n> 故障描述：{faultDesc}\n> 报修人：{applicant}\n> 操作人：{approver}\n> 时间：{time}',NOW())
ON DUPLICATE KEY UPDATE `update_time` = NOW();

-- 拒绝类默认停用（需要时在「通知信息-模板」页打开开关即可）
INSERT INTO `notify_template` (`event_key`,`biz_type`,`event_name`,`enabled`,`title`,`content`,`create_time`) VALUES
('SCRAP_REJECT','报废','报废审批驳回',0,'资产报废申请被驳回',
 '**资产报废申请被驳回**\n> 资产：{assetsName}（{assetsNo}）\n> 申请人：{applicant}\n> 驳回原因：{approveComment}\n> 审批人：{approver}\n> 时间：{time}',NOW()),
('TRANSFER_REJECT','调拨','调拨审批驳回',0,'资产调拨申请被驳回',
 '**资产调拨申请被驳回**\n> 资产：{assetsName}（{assetsNo}）\n> 申请人：{applicant}\n> 驳回原因：{approveComment}\n> 审批人：{approver}\n> 时间：{time}',NOW()),
('ASSETS_IN_REJECT','入库','入库审核驳回',0,'资产入库单被驳回',
 '**资产入库单被驳回**\n> 资产：{assetsName}\n> 采购单号：{purchaseNo}\n> 提交人：{applicant}\n> 驳回原因：{approveComment}\n> 审核人：{approver}\n> 时间：{time}',NOW()),
('RECEIVE_REJECT','领用','领用审核驳回',0,'资产领用申请被驳回',
 '**资产领用申请被驳回**\n> 资产：{assetsName}（{assetsNo}）\n> 领用人：{applicant}\n> 审核人：{approver}\n> 时间：{time}',NOW()),
('REPAIR_REJECT','维修','维修申请驳回',0,'资产维修申请被驳回',
 '**资产维修申请被驳回**\n> 资产：{assetsName}（{assetsCode}）\n> 报修人：{applicant}\n> 操作人：{approver}\n> 时间：{time}',NOW())
ON DUPLICATE KEY UPDATE `update_time` = NOW();

-- ================= 菜单与授权 =================
-- 注意：sys_menu.id 是「固定编号」且非自增，必须显式指定，这里占用 53/54
INSERT INTO `sys_menu` (`id`,`parent_id`,`name`,`path`,`api`,`icon`,`type`,`sort`)
SELECT 53,30,'机器人配置','/robotConfig','/robotConfig',NULL,2,2 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT * FROM `sys_menu`) m WHERE m.`path` = '/robotConfig');

INSERT INTO `sys_menu` (`id`,`parent_id`,`name`,`path`,`api`,`icon`,`type`,`sort`)
SELECT 54,30,'通知信息','/notifyConfig','/notify',NULL,2,3 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT * FROM `sys_menu`) m WHERE m.`path` = '/notifyConfig');

-- 只授予「已拥有系统集成菜单(id=31)」的角色，避免给只读角色越权
INSERT IGNORE INTO `sys_role_menu` (`role_id`,`menu_id`)
SELECT rm.`role_id`, m.`id`
FROM `sys_role_menu` rm JOIN `sys_menu` m ON m.`id` IN (53,54)
WHERE rm.`menu_id` = 31;
