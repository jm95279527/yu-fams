package com.example.mapper;

import com.example.entity.SysRole;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 系统角色数据访问层
 */
@Mapper
public interface SysRoleMapper {

    /**
     * 查询角色列表（支持按名称模糊）
     */
    List<SysRole> selectAll(SysRole role);

    /**
     * 根据ID查询
     */
    SysRole selectById(Integer id);

    /**
     * 根据标识查询
     */
    SysRole selectByCode(String code);

    /**
     * 新增角色
     */
    void insert(SysRole role);

    /**
     * 修改角色
     */
    void updateById(SysRole role);

    /**
     * 删除角色
     */
    void deleteById(Integer id);

    /**
     * 查询角色拥有的菜单ID
     */
    List<Integer> selectMenuIdsByRoleId(Integer roleId);

    /**
     * 删除角色的全部菜单关联
     */
    void deleteRoleMenus(Integer roleId);

    /**
     * 批量插入角色菜单关联
     */
    void batchInsertRoleMenus(@Param("roleId") Integer roleId, @Param("menuIds") List<Integer> menuIds);

    /**
     * 统计该角色下管理员数量
     */
    int countAdminsByRoleId(Integer roleId);
}
