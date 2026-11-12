package com.example.task;

import cn.hutool.core.date.DateUtil;
import com.example.entity.AssetsReceive;
import com.example.mapper.AssetsReceiveMapper;
import com.example.service.NotifyService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 借用归还到期提醒定时任务
 * 提前 1 天 + 到期当天 + 逾期，每天固定时间汇总推送一条到群
 * 执行时间由配置项 borrow-remind-cron 控制（默认每天 9:00）
 */
@Component
public class BorrowRemindTask {

    private static final Logger log = LoggerFactory.getLogger(BorrowRemindTask.class);

    @Resource
    private AssetsReceiveMapper assetsReceiveMapper;

    @Resource
    private NotifyService notifyService;

    @Scheduled(cron = "${borrow-remind-cron}")
    public void remind() {
        try {
            List<AssetsReceive> list = assetsReceiveMapper.selectDueForRemind();
            if (list == null || list.isEmpty()) {
                log.info("借用到期提醒：无待提醒记录");
                return;
            }
            String today = DateUtil.today();
            List<String> overdue = new ArrayList<>();
            List<String> dueToday = new ArrayList<>();
            List<String> dueTomorrow = new ArrayList<>();
            for (AssetsReceive r : list) {
                String line = nz(r.getBorrowerName(), nz(r.getStaffName(), "（未填写借用人）"))
                        + " / " + nz(r.getAssetsName(), "-") + "（" + nz(r.getAssetsNo(), "-") + "）"
                        + " / 应归还 " + nz(r.getReturnDate(), "-")
                        + (r.getBorrowerPhone() == null || r.getBorrowerPhone().isEmpty() ? "" : " / " + r.getBorrowerPhone());
                String d = r.getReturnDate();
                if (d == null || d.isEmpty()) {
                    continue;
                }
                if (d.compareTo(today) < 0) {
                    overdue.add(line);
                } else if (d.equals(today)) {
                    dueToday.add(line);
                } else {
                    dueTomorrow.add(line);
                }
            }

            StringBuilder detail = new StringBuilder();
            appendSection(detail, "已逾期", overdue);
            appendSection(detail, "今日到期", dueToday);
            appendSection(detail, "明日到期", dueTomorrow);
            if (detail.length() == 0) {
                return;
            }

            Map<String, Object> vars = new HashMap<>();
            vars.put("total", list.size());
            vars.put("overdueCount", overdue.size());
            vars.put("todayCount", dueToday.size());
            vars.put("tomorrowCount", dueTomorrow.size());
            vars.put("detail", detail.toString());
            notifyService.push("RECEIVE_DUE", "借用", null, vars);
            log.info("借用到期提醒已推送，共 {} 笔", list.size());
        } catch (Exception e) {
            // 定时任务异常不影响其它功能
            log.error("借用到期提醒执行失败", e);
        }
    }

    private void appendSection(StringBuilder sb, String title, List<String> lines) {
        if (lines == null || lines.isEmpty()) {
            return;
        }
        sb.append("【").append(title).append("】\n");
        for (String line : lines) {
            sb.append("- ").append(line).append("\n");
        }
    }

    private String nz(String value, String fallback) {
        return (value == null || value.trim().isEmpty()) ? fallback : value;
    }
}
