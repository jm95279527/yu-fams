-- 系统级加固：操作审计日志表 + 日志审计菜单 api 修正
CREATE TABLE IF NOT EXISTS audit_log (
  id INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) COMMENT '操作人账号',
  role VARCHAR(20) COMMENT '角色 ADMIN/STAFF',
  ip VARCHAR(64) COMMENT '来源IP',
  method VARCHAR(10) COMMENT 'HTTP方法',
  uri VARCHAR(255) COMMENT '请求接口',
  params VARCHAR(2000) COMMENT '请求参数(已脱敏)',
  result_code VARCHAR(10) COMMENT '业务码',
  status INT COMMENT 'HTTP状态码',
  cost_ms INT COMMENT '耗时毫秒',
  create_time DATETIME COMMENT '操作时间',
  KEY idx_al_user (username),
  KEY idx_al_ctime (create_time)
) COMMENT '操作审计日志';

UPDATE sys_menu SET api = '/auditLog' WHERE id = 52 AND path = '/auditLog';
