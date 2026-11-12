package com.example.mapper;

import com.example.entity.Assets;
import com.example.entity.Category;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 操作assets相关数据接口
 */
public interface AssetsMapper {

    /**
     * 新增
     */
    int insert(Assets assets);

    /**
     * 删除
     */
    int deleteById(Integer id);

    /**
     * 修改
     */
    int updateById(Assets assets);

    /**
     * 根据ID查询
     */
    Assets selectById(Integer id);

    /**
     * 根据ID查询（带部门/责任人名称）
     */
    Assets selectJoinedById(Integer id);

    /**
     * 根据资产编号查询（带部门/责任人名称）
     */
    Assets selectJoinedByNo(String no);

    /**
     * 查询所有
     */
    List<Assets> selectAll(Assets assets);

    @Select("select count(*) from assets where category = #{category}")
    int selectCountByCategory(String category);

    @Select("select no from assets where no like concat(#{prefix}, '%')")
    List<String> selectNoByPrefix(String prefix);

    @Select("select count(*) from assets where no = #{no}")
    int countByNo(String no);
}