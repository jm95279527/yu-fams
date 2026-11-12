package com.example.mapper;

import com.example.entity.NotifyLog;

import java.util.List;

/**
 * 操作notify_log相关数据接口
 */
public interface NotifyLogMapper {

    /**
     * 新增
     */
    int insert(NotifyLog notifyLog);

    /**
     * 删除
     */
    int deleteById(Integer id);

    /**
     * 批量删除
     */
    int deleteBatch(List<Integer> ids);

    /**
     * 按条件清理（保留最近 days 天）
     */
    int cleanBefore(String beforeTime);

    /**
     * 根据ID查询
     */
    NotifyLog selectById(Integer id);

    /**
     * 查询所有（条件：业务类型、结果、日期）
     */
    List<NotifyLog> selectAll(NotifyLog notifyLog);
}
