package com.example.service;

import com.example.entity.AssetsScrap;
import com.github.pagehelper.PageInfo;

import java.util.List;

/**
 * 资产报废业务接口
 */
public interface AssetsScrapService {

    /**
     * 提交报废申请（自动快照资产信息，状态=待审批）
     */
    void add(AssetsScrap assetsScrap);

    /**
     * 删除
     */
    void deleteById(Integer id);

    /**
     * 批量删除
     */
    void deleteBatch(List<Integer> ids);

    /**
     * 修改（申请人编辑待审批/已拒绝单据，已拒绝改后重新进入审批）
     */
    void updateById(AssetsScrap assetsScrap);

    /**
     * 根据ID查询
     */
    AssetsScrap selectById(Integer id);

    /**
     * 查询所有
     */
    List<AssetsScrap> selectAll(AssetsScrap assetsScrap);

    /**
     * 分页查询（员工仅看本人申请）
     */
    PageInfo<AssetsScrap> selectPage(AssetsScrap assetsScrap, Integer pageNum, Integer pageSize);

    /**
     * 根据资产ID查询报废记录
     */
    List<AssetsScrap> selectByAssetsId(Integer assetsId);

    /**
     * 管理员审核：pass=true 通过（资产置为已报废并写变更明细）；pass=false 驳回（需填原因）
     */
    void audit(Integer id, Boolean pass, String approveComment);
}
