package com.example.service;

import com.example.entity.AuditLog;
import com.example.mapper.AuditLogMapper;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * 操作审计日志业务处理
 */
@Service
public class AuditLogService {

    @Resource
    private AuditLogMapper auditLogMapper;

    /**
     * 写入一条审计日志（失败不影响业务）
     */
    public void add(AuditLog auditLog) {
        auditLogMapper.insert(auditLog);
    }

    /**
     * 分页查询
     */
    public PageInfo<AuditLog> selectPage(AuditLog query, Integer pageNum, Integer pageSize) {
        PageHelper.startPage(pageNum, pageSize);
        List<AuditLog> list = auditLogMapper.selectAll(query);
        return PageInfo.of(list);
    }

    /**
     * 批量删除
     */
    public void deleteBatch(List<Integer> ids) {
        auditLogMapper.deleteBatch(ids);
    }

    /**
     * 清理 N 天前的日志
     */
    public void cleanBefore(Integer days) {
        if (days == null || days < 1) {
            days = 30;
        }
        auditLogMapper.cleanBefore(days);
    }
}
