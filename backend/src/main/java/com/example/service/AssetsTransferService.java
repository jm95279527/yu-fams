package com.example.service;

import com.example.entity.AssetsTransfer;
import com.github.pagehelper.PageInfo;

import java.util.List;
import java.util.Map;

public interface AssetsTransferService {

    /**
     * 新增调拨申请（自动快照资产当前部门/责任人/地点）
     */
    void add(AssetsTransfer assetsTransfer);

    /**
     * 删除（仅待审批/已拒绝可删，由前端控制入口）
     */
    void deleteById(Integer id);

    /**
     * 批量删除
     */
    void deleteBatch(List<Integer> ids);

    /**
     * 修改（申请人编辑待审批单据）
     */
    void updateById(AssetsTransfer assetsTransfer);

    /**
     * 根据ID查询
     */
    AssetsTransfer selectById(Integer id);

    /**
     * 查询所有
     */
    List<AssetsTransfer> selectAll(AssetsTransfer assetsTransfer);

    /**
     * 分页查询（员工仅可见自己提交的）
     */
    PageInfo<AssetsTransfer> selectPage(AssetsTransfer assetsTransfer, Integer pageNum, Integer pageSize);

    /**
     * 根据资产ID查询调拨历史
     */
    List<AssetsTransfer> selectByAssetsId(Integer assetsId);

    /**
     * 管理员审核：通过即生效（更新资产部门/责任人/地点并写明细），拒绝记录原因
     */
    void audit(Integer id, Boolean pass, String approveComment);

    /**
     * 批量导入调拨申请（逐行校验，返回成功/失败明细）
     * 每行键：资产编号、新所属公司、新使用部门、新使用人、新存放地点、调拨原因、备注、__row
     */
    Map<String, Object> importBatch(List<Map<String, String>> rows);
}
