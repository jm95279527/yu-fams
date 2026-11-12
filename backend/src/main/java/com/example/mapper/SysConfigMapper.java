package com.example.mapper;

import com.example.entity.SysConfig;

import java.util.List;

/**
 * 操作 sys_config 相关数据接口
 */
public interface SysConfigMapper {

    /**
     * 查询所有配置
     */
    List<SysConfig> selectAll();

    /**
     * 新增或更新（按 config_key 唯一）
     */
    int save(SysConfig sysConfig);
}
