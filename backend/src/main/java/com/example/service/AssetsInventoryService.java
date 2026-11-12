package com.example.service;

import com.example.entity.InventoryItem;
import com.example.entity.InventoryTask;
import com.github.pagehelper.PageInfo;

import java.util.List;
import java.util.Map;

/**
 * 资产盘点业务接口
 */
public interface AssetsInventoryService {

    /**
     * 创建盘点任务（按范围快照资产明细）
     */
    InventoryTask create(InventoryTask form);

    /**
     * 分页查询盘点任务
     */
    PageInfo<InventoryTask> selectPage(InventoryTask query, Integer pageNum, Integer pageSize);

    /**
     * 任务详情
     */
    InventoryTask selectById(Integer id);

    /**
     * 任务明细（可按状态/关键字筛选）
     */
    List<InventoryItem> items(Integer taskId, String itemStatus, String keyword);

    /**
     * 扫码盘点：code 支持资产ID、资产编号或二维码链接 .../scan/{id}
     * 范围外资产自动登记为盘盈；实盘地点与台账不符可标记异常
     */
    InventoryItem scan(Integer taskId, String code, String actualLocation, Boolean abnormal, String comment);

    /**
     * 手工调整明细结果（正常/异常）与备注
     */
    void markItem(Integer itemId, String itemStatus, String comment);

    /**
     * 处理一条盘点差异（盘盈/盘亏/异常），登记处理方式与说明；任务完成后仍可处理
     */
    InventoryItem dealItem(Integer itemId, String dealType, String dealRemark);

    /**
     * 盘点人工作量统计
     */
    List<java.util.Map<String, Object>> workload(Integer taskId);

    /**
     * 完成盘点：未盘明细记为盘亏，汇总统计
     */
    InventoryTask finish(Integer taskId);

    /**
     * 删除任务（仅盘点中可删，连带删除明细）
     */
    void delete(Integer taskId);

    // ==================== 手机扫码盘点（公开，凭 accessCode 访问） ====================

    /**
     * 手机盘点任务概览（脱敏）
     */
    Map<String, Object> publicTask(String accessCode);

    /**
     * 手机盘点明细列表：tab=已盘 / 未盘
     */
    List<Map<String, Object>> publicItems(String accessCode, String tab, String keyword);

    /**
     * 扫码后查询资产信息与盘点状态（已盘 / 范围外 / 可盘点）
     */
    Map<String, Object> lookup(String accessCode, String code);

    /**
     * 手机扫码确认盘点
     */
    InventoryItem publicScan(String accessCode, String code, String comment);
}
