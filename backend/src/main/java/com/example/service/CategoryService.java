package com.example.service;

import cn.hutool.core.util.StrUtil;
import com.example.entity.Category;
import com.example.exception.CustomException;
import com.example.mapper.CategoryMapper;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

/**
 * 资产分类业务处理
 **/
@Service
public class CategoryService {

    @Resource
    private CategoryMapper categoryMapper;

    /**
     * 新增
     */
    public void add(Category category) {
        category.setPid(category.getPid() == null ? 0 : category.getPid());
        validate(category, null);
        categoryMapper.insert(category);
    }

    /**
     * 删除（有二级分类或已被资产使用时不允许删除）
     */
    @Transactional(rollbackFor = Exception.class)
    public void deleteById(Integer id) {
        Category category = categoryMapper.selectById(id);
        if (category == null) {
            return;
        }
        if (categoryMapper.countChildren(id) > 0) {
            throw new CustomException("500", "该分类下还有二级分类，请先删除二级分类");
        }
        if (categoryMapper.countAssetsByName(category.getName()) > 0) {
            throw new CustomException("500", "该分类下还有资产，不能删除");
        }
        categoryMapper.deleteById(id);
    }

    /**
     * 批量删除
     */
    @Transactional(rollbackFor = Exception.class)
    public void deleteBatch(List<Integer> ids) {
        for (Integer id : ids) {
            deleteById(id);
        }
    }

    /**
     * 修改（最多支持二级分类）
     */
    public void updateById(Category category) {
        Category old = categoryMapper.selectById(category.getId());
        if (old == null) {
            throw new CustomException("500", "分类不存在");
        }
        if (category.getPid() == null) {
            category.setPid(old.getPid() == null ? 0 : old.getPid());
        }
        validate(category, category.getId());
        categoryMapper.updateById(category);
    }

    /**
     * 分类校验：名称唯一、编码唯一、最多两级
     */
    private void validate(Category category, Integer excludeId) {
        if (StrUtil.isBlank(category.getName())) {
            throw new CustomException("500", "分类名称不能为空");
        }
        category.setName(category.getName().trim());
        if (categoryMapper.countByName(category.getName(), excludeId) > 0) {
            throw new CustomException("500", "分类名称「" + category.getName() + "」已存在");
        }
        if (StrUtil.isNotBlank(category.getCode())) {
            category.setCode(category.getCode().trim());
            if (categoryMapper.countByCode(category.getCode(), excludeId) > 0) {
                throw new CustomException("500", "分类编码「" + category.getCode() + "」已存在");
            }
        }
        Integer pid = category.getPid() == null ? 0 : category.getPid();
        if (pid > 0) {
            Category parent = categoryMapper.selectById(pid);
            if (parent == null) {
                throw new CustomException("500", "上级分类不存在");
            }
            if (parent.getPid() != null && parent.getPid() > 0) {
                throw new CustomException("500", "最多支持二级分类");
            }
            if (excludeId != null && categoryMapper.countChildren(excludeId) > 0) {
                throw new CustomException("500", "该分类下已有二级分类，不能再设为二级分类");
            }
        }
    }

    /**
     * 根据ID查询
     */
    public Category selectById(Integer id) {
        return categoryMapper.selectById(id);
    }

    /**
     * 查询所有
     */
    public List<Category> selectAll(Category category) {
        return categoryMapper.selectAll(category);
    }

    /**
     * 分页查询
     */
    public PageInfo<Category> selectPage(Category category, Integer pageNum, Integer pageSize) {
        PageHelper.startPage(pageNum, pageSize);
        List<Category> list = categoryMapper.selectAll(category);
        return PageInfo.of(list);
    }

}