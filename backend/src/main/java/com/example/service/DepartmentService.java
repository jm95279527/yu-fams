package com.example.service;

import cn.hutool.core.util.StrUtil;
import com.example.entity.Department;
import com.example.exception.CustomException;
import com.example.mapper.DepartmentMapper;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 部门信息业务处理
 **/
@Service
public class DepartmentService {

    @Resource
    private DepartmentMapper departmentMapper;

    @Resource
    private CompanyService companyService;

    /**
     * 新增
     */
    public void add(Department department) {
        departmentMapper.insert(department);
    }

    /**
     * 删除
     */
    public void deleteById(Integer id) {
        departmentMapper.deleteById(id);
    }

    /**
     * 批量删除
     */
    public void deleteBatch(List<Integer> ids) {
        for (Integer id : ids) {
            departmentMapper.deleteById(id);
        }
    }

    /**
     * 修改
     */
    public void updateById(Department department) {
        departmentMapper.updateById(department);
    }

    /**
     * 根据ID查询
     */
    public Department selectById(Integer id) {
        return departmentMapper.selectById(id);
    }

    /**
     * 查询所有
     */
    public List<Department> selectAll(Department department) {
        return departmentMapper.selectAll(department);
    }

    /**
     * 分页查询
     */
    public PageInfo<Department> selectPage(Department department, Integer pageNum, Integer pageSize) {
        PageHelper.startPage(pageNum, pageSize);
        List<Department> list = departmentMapper.selectAll(department);
        return PageInfo.of(list);
    }
    public List<Department> selectTree() {
        // 效率比较低  我们应该怎么办？  lambda表达式做筛选
        List<Department> list = departmentMapper.selectAll(null);
        List<Department> rootList = list.stream().filter(department -> department.getPid() == null).collect(Collectors.toList());
        for (Department root : rootList) {
            List<Department> level2List = list.stream().filter(department -> Objects.equals(department.getPid(), root.getId())).collect(Collectors.toList());
            root.setChildren(level2List);
            for (Department level2 : level2List) {
                //  IO
                List<Department> level3List = list.stream().filter(department -> Objects.equals(department.getPid(), level2.getId())).collect(Collectors.toList());
                level2.setChildren(level3List);
            }
        }
        return rootList;
    }

    public List<Department> selectParent() {
        List<Department> list = departmentMapper.selectAll(null);
        return list.stream().filter(department -> department.getLevel() == 2 || department.getLevel() == 1).collect(Collectors.toList());
    }

    /**
     * Excel 批量导入部门。
     * 列：公司名称、部门名称、上级部门、地址
     * 规则：
     * 1) 公司名称在 company 表中不存在时自动创建
     * 2) 上级部门按「同一公司下的部门名称」匹配，支持多级；父级行排在后面也能识别
     * 3) 同一公司下已存在同名部门则跳过（可重复导入）
     */
    @Transactional(rollbackFor = Exception.class)
    public String importDepartments(List<Map<String, Object>> rows) {
        if (rows == null || rows.isEmpty()) {
            throw new CustomException("500", "文件中没有数据");
        }
        List<Department> all = departmentMapper.selectAll(null);
        List<Map<String, Object>> pending = new ArrayList<>(rows);
        int success = 0;
        int skip = 0;
        int companyCreated = 0;
        int round = 0;
        while (!pending.isEmpty() && round < 10) {
            round++;
            boolean progress = false;
            Iterator<Map<String, Object>> it = pending.iterator();
            while (it.hasNext()) {
                Map<String, Object> row = it.next();
                String companyName = cell(row, "公司名称");
                String deptName = cell(row, "部门名称");
                String parentName = cell(row, "上级部门");
                String address = cell(row, "地址");
                if (StrUtil.isBlank(deptName)) {
                    throw new CustomException("500", "存在没有填写「部门名称」的行，请检查文件");
                }
                if (StrUtil.isBlank(companyName)) {
                    throw new CustomException("500", "部门「" + deptName + "」没有填写「公司名称」");
                }
                if (companyService.findByName(companyName) == null) {
                    companyCreated++;
                }
                Integer companyId = companyService.idOfNameOrCreate(companyName);
                Department parent = null;
                if (StrUtil.isNotBlank(parentName)) {
                    parent = find(all, companyId, parentName);
                    if (parent == null) {
                        continue; // 父级可能排在本行之后，留到下一轮
                    }
                }
                if (find(all, companyId, deptName) != null) {
                    it.remove();
                    skip++;
                    progress = true;
                    continue;
                }
                Department dept = new Department();
                dept.setName(deptName);
                dept.setCompanyId(companyId);
                if (StrUtil.isNotBlank(address)) {
                    dept.setAddress(address);
                }
                if (parent == null) {
                    dept.setLevel(1);
                } else {
                    dept.setPid(parent.getId());
                    dept.setLevel((parent.getLevel() == null ? 1 : parent.getLevel()) + 1);
                }
                departmentMapper.insert(dept);
                all.add(dept);
                it.remove();
                success++;
                progress = true;
            }
            if (!progress) {
                break; // 剩余行的上级部门找不到，无法继续
            }
        }
        if (!pending.isEmpty()) {
            StringBuilder sb = new StringBuilder();
            for (Map<String, Object> row : pending) {
                if (sb.length() > 0) {
                    sb.append("、");
                }
                sb.append(cell(row, "部门名称"));
            }
            throw new CustomException("500", "以下部门的「上级部门」在当前公司中不存在：" + sb);
        }
        StringBuilder msg = new StringBuilder("成功导入 " + success + " 个部门");
        if (companyCreated > 0) {
            msg.append("，自动新建公司 ").append(companyCreated).append(" 个");
        }
        if (skip > 0) {
            msg.append("，跳过已存在 ").append(skip).append(" 个");
        }
        return msg.toString();
    }

    private Department find(List<Department> all, Integer companyId, String name) {
        for (Department d : all) {
            if (Objects.equals(d.getCompanyId(), companyId) && name.equals(d.getName())) {
                return d;
            }
        }
        return null;
    }

    private String cell(Map<String, Object> row, String key) {
        Object value = row.get(key);
        return value == null ? null : String.valueOf(value).trim();
    }
}