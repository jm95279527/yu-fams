package com.example.mapper;

import com.example.entity.InventoryTask;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 盘点任务数据访问层
 */
@Mapper
public interface InventoryTaskMapper {

    void insert(InventoryTask task);

    void updateById(InventoryTask task);

    void deleteById(Integer id);

    InventoryTask selectById(Integer id);

    InventoryTask selectByAccessCode(String accessCode);

    List<InventoryTask> selectAll(InventoryTask query);
}
