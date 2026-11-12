-- ============================================================
-- 清理已废弃的「企业微信/钉钉集成」入口（菜单 31 + 角色授权）
-- 背景：该功能已被「群机器人 webhook 推送」替代，前端页面与后端接口
--       （IntegrationController / WechatWorkService / WechatWorkSyncService /
--         WechatWorkConfig / DingTalkConfig / WechatWorkConfigMapper）已一并删除。
-- 说明：wechat_work_config / dingtalk_config / third_party_user 三张表**保留不动**
--       （其中 wechat_work_config 存有真实企微凭据，删除会丢数据）；
--       department.wx_dept_id / staff.wx_userid 两列同样保留（均为空值）。
-- ============================================================

DELETE FROM `sys_role_menu` WHERE `menu_id` = 31;
DELETE FROM `sys_menu` WHERE `id` = 31;
