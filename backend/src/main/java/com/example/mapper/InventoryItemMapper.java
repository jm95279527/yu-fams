package com.example.mapper;

import com.example.entity.InventoryItem;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 盘点明细数据访问层
 */
@Mapper
public interface InventoryItemMapper {

    void insert(InventoryItem item);

    void batchInsert(@Param("list") List<InventoryItem> list);

    void updateById(InventoryItem item);

    InventoryItem selectById(Integer id);

    /** 查询某任务下指定资产的明细 */
    InventoryItem selectByTaskAndAssets(@Param("taskId") Integer taskId, @Param("assetsId") Integer assetsId);

    /** 任务明细列表（可按状态/关键字筛选） */
    List<InventoryItem> selectByTask(@Param("taskId") Integer taskId,
                                     @Param("itemStatus") String itemStatus,
                                     @Param("keyword") String keyword);

    /** 手机盘点明细：scanned=1 已盘（非未盘） / 0 未盘 / null 全部 */
    List<InventoryItem> selectByTaskScope(@Param("taskId") Integer taskId,
                                          @Param("scanned") Integer scanned,
                                          @Param("keyword") String keyword);

    /** 任务下各状态数量统计：返回 item_status, cnt */
    List<java.util.Map<String, Object>> countByTask(@Param("taskId") Integer taskId);

    /** 任务下待处理差异数（盘盈/盘亏/异常且未处理） */
    int countPending(@Param("taskId") Integer taskId);

    /** 盘点人工作量统计：scannerName/total/normalCnt/abnormalCnt/profitCnt/lossCnt */
    List<java.util.Map<String, Object>> workload(@Param("taskId") Integer taskId);

    /** 将任务下所有未盘明细置为盘亏 */
    int markUncheckedAsLoss(@Param("taskId") Integer taskId);

    /** 明细改回正常时清空差异处理信息 */
    void clearDeal(@Param("id") Integer id);

    void deleteByTask(@Param("taskId") Integer taskId);
}
