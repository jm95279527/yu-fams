package com.example.controller;

import com.example.common.Result;
import com.example.entity.NotifyLog;
import com.example.entity.NotifyTemplate;
import com.example.service.NotifyService;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;

/**
 * 通知信息接口：通知模板 + 通知记录
 */
@RestController
@RequestMapping("/notify")
public class NotifyController {

    @Resource
    private NotifyService notifyService;

    /* ==================== 通知模板 ==================== */

    /**
     * 模板列表
     */
    @GetMapping("/templates")
    public Result templates() {
        return Result.success(notifyService.listTemplates());
    }

    /**
     * 保存模板（启用开关/标题/正文）
     */
    @PutMapping("/template")
    public Result saveTemplate(@RequestBody NotifyTemplate template) {
        notifyService.saveTemplate(template);
        return Result.success();
    }

    /* ==================== 通知记录 ==================== */

    /**
     * 分页查询
     */
    @GetMapping("/selectPage")
    public Result selectPage(NotifyLog notifyLog,
                             @RequestParam(defaultValue = "1") Integer pageNum,
                             @RequestParam(defaultValue = "10") Integer pageSize) {
        PageHelper.startPage(pageNum, pageSize);
        List<NotifyLog> list = notifyService.listLogs(notifyLog);
        return Result.success(PageInfo.of(list));
    }

    /**
     * 删除
     */
    @DeleteMapping("/delete/{id}")
    public Result delete(@PathVariable Integer id) {
        notifyService.deleteLog(id);
        return Result.success();
    }

    /**
     * 批量删除
     */
    @DeleteMapping("/delete/batch")
    public Result deleteBatch(@RequestBody List<Integer> ids) {
        notifyService.deleteLogBatch(ids);
        return Result.success();
    }

    /**
     * 清理历史记录（保留最近 days 天）
     */
    @DeleteMapping("/clean/{days}")
    public Result clean(@PathVariable Integer days) {
        notifyService.cleanLogs(days);
        return Result.success();
    }

    /**
     * 重发
     */
    @PostMapping("/resend/{id}")
    public Result resend(@PathVariable Integer id) {
        return Result.success(notifyService.resend(id));
    }
}
