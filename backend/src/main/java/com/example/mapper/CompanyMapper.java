package com.example.mapper;

import com.example.entity.Company;

import java.util.List;

/**
 * 操作company相关数据接口
 */
public interface CompanyMapper {

    /**
     * 新增
     */
    int insert(Company company);

    /**
     * 删除
     */
    int deleteById(Integer id);

    /**
     * 修改
     */
    int updateById(Company company);

    /**
     * 根据ID查询
     */
    Company selectById(Integer id);

    /**
     * 按名称查询
     */
    Company selectByName(String name);

    /**
     * 查询所有
     */
    List<Company> selectAll(Company company);
}
