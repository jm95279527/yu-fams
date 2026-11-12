package com.example.mapper;

import com.example.entity.RobotConfig;

import java.util.List;

/**
 * 操作robot_config相关数据接口
 */
public interface RobotConfigMapper {

    /**
     * 新增
     */
    int insert(RobotConfig robotConfig);

    /**
     * 删除
     */
    int deleteById(Integer id);

    /**
     * 修改
     */
    int updateById(RobotConfig robotConfig);

    /**
     * 根据ID查询
     */
    RobotConfig selectById(Integer id);

    /**
     * 查询所有
     */
    List<RobotConfig> selectAll(RobotConfig robotConfig);

    /**
     * 查询已启用的机器人（推送用）
     */
    List<RobotConfig> selectEnabled();
}
