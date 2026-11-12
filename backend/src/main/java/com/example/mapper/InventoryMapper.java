package com.example.mapper;

import com.example.entity.Inventory;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface InventoryMapper {

    /**
     * 新增
     */
    int insert(Inventory inventory);

    /**
     * 删除
     */
    int deleteById(Integer id);

    /**
     * 批量删除
     */
    int deleteBatch(List<Integer> ids);

    /**
     * 修改
     */
    int updateById(Inventory inventory);

    /**
     * 根据ID查询
     */
    Inventory selectById(Integer id);

    /**
     * 查询所有
     */
    List<Inventory> selectAll(Inventory inventory);

    /**
     * 分页查询
     */
    List<Inventory> selectPage(Inventory inventory, Integer pageNum, Integer pageSize);

    /**
     * 查询最近的盘点记录
     */
    List<Inventory> selectRecent(Integer limit);
}