package com.example.mapper;

import com.example.entity.AssetsScrap;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 资产报废数据访问层
 */
@Mapper
public interface AssetsScrapMapper {

    /**
     * 新增
     */
    void insert(AssetsScrap assetsScrap);

    /**
     * 删除
     */
    void deleteById(Integer id);

    /**
     * 批量删除
     */
    void deleteBatch(List<Integer> ids);

    /**
     * 修改
     */
    void updateById(AssetsScrap assetsScrap);

    /**
     * 驳回单据重新提交：清空审核信息并回到待审批
     */
    void resetAudit(Integer id);

    /**
     * 根据ID查询
     */
    AssetsScrap selectById(Integer id);

    /**
     * 查询所有
     */
    List<AssetsScrap> selectAll(AssetsScrap assetsScrap);

    /**
     * 分页查询
     */
    List<AssetsScrap> selectPage(AssetsScrap assetsScrap);

    /**
     * 根据资产ID查询报废记录
     */
    List<AssetsScrap> selectByAssetsId(Integer assetsId);
}
