package com.example.service;

import cn.hutool.core.date.DateUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.http.HttpUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.example.entity.NotifyLog;
import com.example.entity.NotifyTemplate;
import com.example.entity.RobotConfig;
import com.example.exception.CustomException;
import com.example.mapper.NotifyLogMapper;
import com.example.mapper.NotifyTemplateMapper;
import com.example.mapper.RobotConfigMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Date;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 群机器人通知服务：审批事件推送到企业微信群机器人
 */
@Service
public class NotifyService {

    private static final Logger log = LoggerFactory.getLogger(NotifyService.class);

    @Resource
    private RobotConfigMapper robotConfigMapper;
    @Resource
    private NotifyTemplateMapper notifyTemplateMapper;
    @Resource
    private NotifyLogMapper notifyLogMapper;

    /* ==================== 机器人配置 ==================== */

    public List<RobotConfig> listRobots(RobotConfig query) {
        if (query == null) {
            query = new RobotConfig();
        }
        return robotConfigMapper.selectAll(query);
    }

    public RobotConfig getRobot(Integer id) {
        return robotConfigMapper.selectById(id);
    }

    public void saveRobot(RobotConfig config) {
        if (StrUtil.isBlank(config.getWebhookUrl())) {
            throw new CustomException("500", "Webhook 地址不能为空");
        }
        if (StrUtil.isBlank(config.getType())) {
            config.setType("wechat");
        }
        if (config.getEnabled() == null) {
            config.setEnabled(true);
        }
        String now = DateUtil.now();
        config.setUpdateTime(now);
        if (config.getId() == null) {
            config.setCreateTime(now);
            robotConfigMapper.insert(config);
        } else {
            robotConfigMapper.updateById(config);
        }
    }

    public void deleteRobot(Integer id) {
        robotConfigMapper.deleteById(id);
    }

    /**
     * 测试发送（机器人配置页「测试」按钮）
     */
    public Map<String, Object> testSend(Integer robotId, String message) {
        RobotConfig robot = robotConfigMapper.selectById(robotId);
        if (robot == null) {
            throw new CustomException("500", "机器人不存在");
        }
        String content = StrUtil.isBlank(message)
                ? "**群机器人连通性测试**\n> 发送时间：" + DateUtil.now()
                : message;
        String[] r = sendToRobot(robot, "测试消息", content, "TEST", "测试", null);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("status", r[0]);
        data.put("response", r[1]);
        return data;
    }

    /* ==================== 通知模板 ==================== */

    public List<NotifyTemplate> listTemplates() {
        return notifyTemplateMapper.selectAll();
    }

    public void saveTemplate(NotifyTemplate template) {
        template.setUpdateTime(DateUtil.now());
        notifyTemplateMapper.updateById(template);
    }

    /* ==================== 通知记录 ==================== */

    public List<NotifyLog> listLogs(NotifyLog query) {
        if (query == null) {
            query = new NotifyLog();
        }
        return notifyLogMapper.selectAll(query);
    }

    public void deleteLog(Integer id) {
        notifyLogMapper.deleteById(id);
    }

    public void deleteLogBatch(List<Integer> ids) {
        if (ids != null && !ids.isEmpty()) {
            notifyLogMapper.deleteBatch(ids);
        }
    }

    /**
     * 清理历史通知记录（保留最近 days 天）
     */
    public void cleanLogs(Integer days) {
        int d = (days == null || days <= 0) ? 30 : days;
        String before = DateUtil.formatDateTime(DateUtil.offsetDay(new Date(), -d));
        notifyLogMapper.cleanBefore(before);
    }

    /**
     * 重发某条通知记录
     */
    public Map<String, Object> resend(Integer id) {
        NotifyLog record = notifyLogMapper.selectById(id);
        if (record == null) {
            throw new CustomException("500", "通知记录不存在");
        }
        if (record.getRobotId() == null) {
            throw new CustomException("500", "该记录未关联机器人，无法重发");
        }
        RobotConfig robot = robotConfigMapper.selectById(record.getRobotId());
        if (robot == null) {
            throw new CustomException("500", "原机器人已删除，无法重发");
        }
        String[] r = sendToRobot(robot, record.getTitle(), record.getContent(),
                record.getEventKey(), record.getBizType(), record.getBizId());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("status", r[0]);
        data.put("response", r[1]);
        return data;
    }

    /* ==================== 对外推送入口 ==================== */

    /**
     * 审批事件推送到群：模板不存在或未启用则静默跳过；推送异常不影响主业务
     *
     * @param eventKey 事件标识，如 SCRAP_PASS
     * @param bizType  业务类型，如 报废
     * @param bizId    业务单据ID
     * @param vars     模板变量
     */
    public void push(String eventKey, String bizType, Integer bizId, Map<String, Object> vars) {
        try {
            NotifyTemplate tpl = notifyTemplateMapper.selectByEventKey(eventKey);
            if (tpl == null || !Boolean.TRUE.equals(tpl.getEnabled())) {
                return;
            }
            Map<String, Object> model = new HashMap<>();
            if (vars != null) {
                model.putAll(vars);
            }
            model.putIfAbsent("time", DateUtil.now());
            String title = render(tpl.getTitle(), model);
            String content = render(tpl.getContent(), model);

            List<RobotConfig> robots = robotConfigMapper.selectEnabled();
            if (robots == null || robots.isEmpty()) {
                saveLog(eventKey, bizType, bizId, title, content, null, null, "失败", "未配置已启用的群机器人");
                return;
            }
            for (RobotConfig robot : robots) {
                sendToRobot(robot, title, content, eventKey, bizType, bizId);
            }
        } catch (Exception e) {
            // 通知属于旁路能力，失败不能影响审批主流程
            log.error("推送群通知失败, eventKey={}", eventKey, e);
        }
    }

    /**
     * 发送到单个机器人，并落通知记录
     *
     * @return [status, response]
     */
    private String[] sendToRobot(RobotConfig robot, String title, String content,
                                 String eventKey, String bizType, Integer bizId) {
        String status;
        String response;
        try {
            String url = robot.getWebhookUrl();
            if (StrUtil.isNotBlank(robot.getSecret())) {
                long timestamp = System.currentTimeMillis() / 1000;
                String sign = sign(timestamp, robot.getSecret());
                url = url + (url.contains("?") ? "&" : "?")
                        + "timestamp=" + timestamp + "&sign=" + URLEncoder.encode(sign, "UTF-8");
            }
            JSONObject body = new JSONObject();
            body.set("msgtype", "markdown");
            JSONObject markdown = new JSONObject();
            markdown.set("content", content);
            body.set("markdown", markdown);

            response = HttpUtil.post(url, body.toString(), 10000);
            boolean ok = false;
            try {
                ok = JSONUtil.parseObj(response).getInt("errcode", -1) == 0;
            } catch (Exception ignore) {
                // 返回内容非预期 JSON，按失败处理
            }
            status = ok ? "成功" : "失败";
        } catch (Exception e) {
            status = "失败";
            response = "调用异常：" + e.getMessage();
        }
        saveLog(eventKey, bizType, bizId, title, content, robot.getId(), robot.getName(), status, response);
        return new String[]{status, response};
    }

    private void saveLog(String eventKey, String bizType, Integer bizId, String title, String content,
                         Integer robotId, String robotName, String status, String response) {
        NotifyLog entity = new NotifyLog();
        entity.setEventKey(eventKey);
        entity.setBizType(bizType);
        entity.setBizId(bizId);
        entity.setTitle(cut(title, 200));
        entity.setContent(cut(content, 1000));
        entity.setRobotId(robotId);
        entity.setRobotName(robotName);
        entity.setStatus(status);
        entity.setResponse(cut(response, 500));
        entity.setCreateTime(DateUtil.now());
        notifyLogMapper.insert(entity);
    }

    /**
     * 企业微信群机器人加签
     */
    private String sign(long timestamp, String secret) throws Exception {
        String stringToSign = timestamp + "\n" + secret;
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] raw = mac.doFinal(stringToSign.getBytes(StandardCharsets.UTF_8));
        return Base64.getEncoder().encodeToString(raw);
    }

    /**
     * 模板渲染：{key} 替换为变量值，未提供的占位符清空
     */
    private String render(String template, Map<String, Object> vars) {
        if (StrUtil.isBlank(template)) {
            return "";
        }
        String out = template;
        for (Map.Entry<String, Object> entry : vars.entrySet()) {
            String value = entry.getValue() == null ? "" : String.valueOf(entry.getValue());
            out = out.replace("{" + entry.getKey() + "}", value);
        }
        return out.replaceAll("\\{[A-Za-z0-9_]+\\}", "");
    }

    private String cut(String s, int max) {
        if (s == null) {
            return null;
        }
        return s.length() <= max ? s : s.substring(0, max);
    }
}
