-- ============================================================
-- 借用归还到期提醒模板（由定时任务 BorrowRemindTask 推送）
-- 触发时机：提前 1 天 / 到期当天 / 逾期（每天固定时间汇总一条）
-- ============================================================
INSERT INTO `notify_template` (`event_key`,`biz_type`,`event_name`,`enabled`,`title`,`content`,`create_time`) VALUES
('RECEIVE_DUE','借用','借用到期提醒',1,'借用归还到期提醒',
 '**借用归还到期提醒**\n> 待归还 {total} 笔（逾期 {overdueCount} / 今日到期 {todayCount} / 明日到期 {tomorrowCount}）\n{detail}> 请及时联系借用人催还',NOW())
ON DUPLICATE KEY UPDATE `update_time` = NOW();
