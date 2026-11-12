package com.example.mapper;

import com.example.dto.DashboardStats;
import com.example.dto.StatusDistribution;
import com.example.dto.RepairStats;
import com.example.dto.InventoryTrend;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Mapper
public interface DashboardMapper {

    @Select("SELECT " +
            "(SELECT COUNT(*) FROM assets) AS totalAssets, " +
            "(SELECT COUNT(*) FROM assets WHERE status = '维修中') AS underRepair, " +
            "(SELECT COALESCE(SUM(current_value), 0) FROM assets) AS totalValue, " +
            "(SELECT COUNT(*) FROM inventory WHERE inventory_time >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AS inventoryCount, " +
            "(SELECT COUNT(*) FROM inventory WHERE result = '正常') AS normalInventory, " +
            "(SELECT COUNT(*) FROM inventory WHERE result != '正常') AS abnormalInventory, " +
            "0 AS assetGrowthRate, " +
            "0 AS repairDecreaseRate, " +
            "0 AS valueGrowthRate, " +
            "0 AS inventoryGrowthRate")
    DashboardStats getDashboardStats();

    @Select("SELECT status AS name, COUNT(*) AS value FROM assets GROUP BY status")
    List<StatusDistribution> getStatusDistribution();

    @Select("SELECT " +
            "DATE_FORMAT(date, '%Y-%m-%d') AS date, " +
            "COUNT(*) AS repairCount, " +
            "SUM(CASE WHEN status = '已完成' THEN 1 ELSE 0 END) AS completedCount " +
            "FROM assets_repair " +
            "WHERE date >= DATE_SUB(NOW(), INTERVAL 30 DAY) " +
            "GROUP BY DATE_FORMAT(date, '%Y-%m-%d') " +
            "ORDER BY date")
    List<Map<String, Object>> getRepairStats();

    @Select("SELECT " +
            "DATE_FORMAT(inventory_time, '%Y-%m') AS month, " +
            "COUNT(*) AS count " +
            "FROM inventory " +
            "WHERE inventory_time >= DATE_SUB(NOW(), INTERVAL 6 MONTH) " +
            "GROUP BY DATE_FORMAT(inventory_time, '%Y-%m') " +
            "ORDER BY month")
    List<Map<String, Object>> getInventoryTrend();

    /* ===================== 驾驶舱概览 ===================== */

    @Select("SELECT " +
            "(SELECT COUNT(*) FROM assets) AS totalCount, " +
            "(SELECT COALESCE(SUM(money), 0) FROM assets) AS totalMoney, " +
            "(SELECT COUNT(DISTINCT department_id) FROM assets WHERE department_id IS NOT NULL) AS deptCount, " +
            "(SELECT COUNT(DISTINCT staff_id) FROM assets WHERE staff_id IS NOT NULL) AS staffCount, " +
            "(SELECT COUNT(*) FROM assets WHERE money IS NULL OR money = 0) AS missingMoneyCount, " +
            "(SELECT COUNT(*) FROM assets WHERE date IS NOT NULL AND LEFT(date, 7) = DATE_FORMAT(CURDATE(), '%Y-%m')) AS monthNewCount, " +
            "(SELECT COALESCE(SUM(money), 0) FROM assets WHERE date IS NOT NULL AND LEFT(date, 7) = DATE_FORMAT(CURDATE(), '%Y-%m')) AS monthNewValue")
    Map<String, Object> getOverviewKpi();

    @Select("SELECT COALESCE(NULLIF(status, ''), '未知') AS name, COUNT(*) AS value, " +
            "COALESCE(SUM(money), 0) AS amount FROM assets GROUP BY status ORDER BY value DESC")
    List<Map<String, Object>> getOverviewStatus();

    @Select("SELECT COALESCE(c.name, '未分配公司') AS name, COUNT(*) AS value, " +
            "COALESCE(SUM(a.money), 0) AS amount FROM assets a " +
            "LEFT JOIN department d ON a.department_id = d.id " +
            "LEFT JOIN company c ON d.company_id = c.id " +
            "GROUP BY c.name ORDER BY value DESC")
    List<Map<String, Object>> getOverviewCompany();

    @Select("SELECT COALESCE(d.name, '未分配部门') AS name, COUNT(*) AS value, " +
            "COALESCE(SUM(a.money), 0) AS amount FROM assets a " +
            "LEFT JOIN department d ON a.department_id = d.id " +
            "GROUP BY d.name ORDER BY value DESC LIMIT 8")
    List<Map<String, Object>> getOverviewDept();

    @Select("SELECT COALESCE(NULLIF(category, ''), '未分类') AS name, COUNT(*) AS value, " +
            "COALESCE(SUM(money), 0) AS amount FROM assets " +
            "GROUP BY COALESCE(NULLIF(category, ''), '未分类') ORDER BY value DESC LIMIT 8")
    List<Map<String, Object>> getOverviewCategory();

    @Select("SELECT LEFT(date, 7) AS month, COUNT(*) AS count, COALESCE(SUM(money), 0) AS amount " +
            "FROM assets WHERE date IS NOT NULL AND date <> '' " +
            "AND date >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 11 MONTH), '%Y-%m') " +
            "GROUP BY LEFT(date, 7) ORDER BY month")
    List<Map<String, Object>> getOverviewMonthly();

    @Select("SELECT id, name, status, total_count AS totalCount, normal_count AS normalCount, " +
            "loss_count AS lossCount, abnormal_count AS abnormalCount, profit_count AS profitCount " +
            "FROM inventory_task ORDER BY create_time DESC LIMIT 4")
    List<Map<String, Object>> getOverviewInventory();

    @Select("SELECT " +
            "(SELECT COUNT(*) FROM assets_transfer WHERE status = '待审批') AS pendingTransfer, " +
            "(SELECT COUNT(*) FROM assets_repair WHERE status IN ('处理中', '待处理')) AS pendingRepair, " +
            "(SELECT COUNT(*) FROM inventory_task WHERE status = '盘点中') AS activeInventory, " +
            "(SELECT COUNT(*) FROM assets_receive WHERE status = '借用中' " +
            "  AND return_date IS NOT NULL AND return_date < CURDATE()) AS overdueBorrow")
    Map<String, Object> getOverviewTodo();

    @Select("SELECT no, name, category, model, LEFT(date, 10) AS date, money, status, location " +
            "FROM assets ORDER BY id DESC LIMIT 8")
    List<Map<String, Object>> getRecentAssets();
}
