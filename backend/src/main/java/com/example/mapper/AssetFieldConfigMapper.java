package com.example.mapper;

import com.example.entity.AssetFieldConfig;

import java.util.List;

/**
 * 资产字段配置数据接口
 */
public interface AssetFieldConfigMapper {

    /**
     * 查询全部字段配置（按排序号）
     */
    List<AssetFieldConfig> selectAll();

    /**
     * 按字段标识查询
     */
    AssetFieldConfig selectByKey(String fieldKey);

    /**
     * 修改
     */
    int updateById(AssetFieldConfig config);
}
