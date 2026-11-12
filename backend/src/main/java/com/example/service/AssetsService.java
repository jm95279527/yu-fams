package com.example.service;

import com.example.entity.Assets;
import com.example.entity.Category;
import com.example.entity.NumberRule;
import com.example.mapper.AssetsMapper;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import java.util.List;

/**
 * 资产信息业务处理
 **/
@Service
public class AssetsService {

    @Resource
    private AssetsMapper assetsMapper;

    @Resource
    private NumberRuleService numberRuleService;

    /**
     * 新增（编号留空且规则启用时自动生成，Excel 批量导入同样生效）
     */
    public void add(Assets assets) {
        if (assets.getNo() == null || assets.getNo().trim().isEmpty()) {
            NumberRule rule = numberRuleService.findConfig();
            if (Boolean.TRUE.equals(rule.getEnabled())) {
                try {
                    assets.setNo(numberRuleService.generate(assets.getCategory()));
                } catch (Exception ignored) {
                    // 生成失败时保留为空，由数据库/用户后续补录
                }
            }
        }
        assetsMapper.insert(assets);
    }

    /**
     * 删除
     */
    public void deleteById(Integer id) {
        assetsMapper.deleteById(id);
    }

    /**
     * 批量删除
     */
    public void deleteBatch(List<Integer> ids) {
        for (Integer id : ids) {
            assetsMapper.deleteById(id);
        }
    }

    /**
     * 修改
     */
    public void updateById(Assets assets) {
        assetsMapper.updateById(assets);
    }

    /**
     * 根据ID查询
     */
    public Assets selectById(Integer id) {
        return assetsMapper.selectById(id);
    }

    /**
     * 根据ID查询（带部门/责任人名称，部门名含公司前缀，责任人离职会带「（离职）」）
     */
    public Assets selectJoinedById(Integer id) {
        return assetsMapper.selectJoinedById(id);
    }

    /**
     * 根据资产编号查询（带部门/责任人名称）
     */
    public Assets selectJoinedByNo(String no) {
        return assetsMapper.selectJoinedByNo(no);
    }

    /**
     * 查询所有
     */
    public List<Assets> selectAll(Assets assets) {
        return assetsMapper.selectAll(assets);
    }

    /**
     * 分页查询
     */
    public PageInfo<Assets> selectPage(Assets assets, Integer pageNum, Integer pageSize) {
        PageHelper.startPage(pageNum, pageSize);
        List<Assets> list = assetsMapper.selectAll(assets);
        return PageInfo.of(list);
    }


    public int selectCountByCategory(String category) {
        return assetsMapper.selectCountByCategory(category);
    }
}