package com.example.mapper;

import com.example.entity.NotifyTemplate;

import java.util.List;

/**
 * 操作notify_template相关数据接口
 */
public interface NotifyTemplateMapper {

    /**
     * 查询所有（按业务类型、事件排序）
     */
    List<NotifyTemplate> selectAll();

    /**
     * 按事件标识查询（推送时取模板）
     */
    NotifyTemplate selectByEventKey(String eventKey);

    /**
     * 修改（启用开关、标题、正文）
     */
    int updateById(NotifyTemplate notifyTemplate);
}
