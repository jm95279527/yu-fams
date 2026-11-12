package com.example.service;

import cn.hutool.core.date.DateUtil;
import cn.hutool.core.util.StrUtil;
import com.example.entity.Company;
import com.example.exception.CustomException;
import com.example.mapper.CompanyMapper;
import com.example.mapper.DepartmentMapper;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * 分子公司业务处理
 */
@Service
public class CompanyService {

    @Resource
    private CompanyMapper companyMapper;

    @Resource
    private DepartmentMapper departmentMapper;

    public List<Company> selectAll(Company company) {
        if (company == null) {
            company = new Company();
        }
        return companyMapper.selectAll(company);
    }

    public Company selectById(Integer id) {
        return companyMapper.selectById(id);
    }

    public void add(Company company) {
        if (StrUtil.isBlank(company.getName())) {
            throw new CustomException("500", "请填写公司名称");
        }
        company.setName(company.getName().trim());
        if (companyMapper.selectByName(company.getName()) != null) {
            throw new CustomException("500", "该公司名称已存在");
        }
        String now = DateUtil.now();
        company.setCreateTime(now);
        company.setUpdateTime(now);
        companyMapper.insert(company);
    }

    public void updateById(Company company) {
        if (StrUtil.isBlank(company.getName())) {
            throw new CustomException("500", "请填写公司名称");
        }
        company.setName(company.getName().trim());
        Company db = companyMapper.selectByName(company.getName());
        if (db != null && !db.getId().equals(company.getId())) {
            throw new CustomException("500", "该公司名称已存在");
        }
        company.setUpdateTime(DateUtil.now());
        companyMapper.updateById(company);
    }

    public void deleteById(Integer id) {
        if (departmentMapper.countByCompanyId(id) > 0) {
            throw new CustomException("500", "该公司下还有部门，请先把部门调整到其它公司");
        }
        companyMapper.deleteById(id);
    }

    /**
     * 按名称查询（不存在时返回 null），部门导入时用于自动建公司
     */
    public Company findByName(String name) {
        return companyMapper.selectByName(name);
    }

    /**
     * 导入时按名称取公司ID，不存在则新建
     */
    public Integer idOfNameOrCreate(String name) {
        if (StrUtil.isBlank(name)) {
            return null;
        }
        Company exist = companyMapper.selectByName(name.trim());
        if (exist != null) {
            return exist.getId();
        }
        Company company = new Company();
        company.setName(name.trim());
        company.setSort(0);
        add(company);
        return company.getId();
    }
}
