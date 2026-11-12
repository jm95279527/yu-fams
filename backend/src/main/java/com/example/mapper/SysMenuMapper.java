package com.example.mapper;

import com.example.entity.SysMenu;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 系统菜单数据访问层
 */
@Mapper
public interface SysMenuMapper {

    /**
     * 查询全部菜单（按sort排序）
     */
    List<SysMenu> selectAll();

    /**
     * 根据ID集合查询菜单
     */
    List<SysMenu> selectByIds(List<Integer> ids);

    /**
     * 新增菜单
     */
    void insert(SysMenu menu);

    /**
     * 修改菜单
     */
    void updateById(SysMenu menu);

    /**
     * 删除菜单
     */
    void deleteById(Integer id);
}
