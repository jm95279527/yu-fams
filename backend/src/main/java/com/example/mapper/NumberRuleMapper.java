package com.example.mapper;

import com.example.entity.NumberRule;

/**
 * 操作number_rule相关数据接口（单行配置表）
 */
public interface NumberRuleMapper {

    /**
     * 查询规则（单行）
     */
    NumberRule selectOne();

    /**
     * 新增
     */
    int insert(NumberRule rule);

    /**
     * 修改
     */
    int updateById(NumberRule rule);

}
