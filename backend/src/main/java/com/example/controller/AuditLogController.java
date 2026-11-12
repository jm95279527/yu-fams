package com.example.controller;

import com.example.common.Result;
import com.example.entity.AuditLog;
import com.example.service.AuditLogService;
import com.github.pagehelper.PageInfo;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;

/**
 * 日志审计前端接口
 */
@RestController
@RequestMapping("/auditLog")
public class AuditLogController {

    @Resource
    private AuditLogService auditLogService;

    /**
     * 分页查询
     */
    @GetMapping("/selectPage")
    public Result selectPage(AuditLog query,
                             @RequestParam(defaultValue = "1") Integer pageNum,
                             @RequestParam(defaultValue = "10") Integer pageSize) {
        PageInfo<AuditLog> page = auditLogService.selectPage(query, pageNum, pageSize);
        return Result.success(page);
    }

    /**
     * 批量删除
     */
    @DeleteMapping("/delete/batch")
    public Result deleteBatch(@RequestBody List<Integer> ids) {
        auditLogService.deleteBatch(ids);
        return Result.success();
    }

    /**
     * 清理 N 天前的日志
     */
    @DeleteMapping("/clean/{days}")
    public Result clean(@PathVariable Integer days) {
        auditLogService.cleanBefore(days);
        return Result.success();
    }

}
