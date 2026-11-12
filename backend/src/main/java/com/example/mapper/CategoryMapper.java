package com.example.mapper;

import com.example.entity.Category;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 操作category相关数据接口
 */
public interface CategoryMapper {

    /**
     * 新增
     */
    int insert(Category category);

    /**
     * 删除
     */
    int deleteById(Integer id);

    /**
     * 修改
     */
    int updateById(Category category);

    /**
     * 根据ID查询
     */
    Category selectById(Integer id);

    /**
     * 查询所有
     */
    List<Category> selectAll(Category category);

    /**
     * 按名称精确查询
     */
    Category selectByName(String name);

    /**
     * 统计子分类数量
     */
    int countChildren(Integer pid);

    /**
     * 统计同名分类数量（excludeId 用于编辑时排除自身）
     */
    int countByName(@Param("name") String name, @Param("excludeId") Integer excludeId);

    /**
     * 统计使用该分类名称的资产数量
     */
    int countAssetsByName(String name);

    /**
     * 统计相同编码的分类数量（excludeId 用于编辑时排除自身）
     */
    int countByCode(@Param("code") String code, @Param("excludeId") Integer excludeId);

}