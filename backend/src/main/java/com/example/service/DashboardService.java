package com.example.service;

import com.example.dto.DashboardStats;
import com.example.dto.StatusDistribution;
import com.example.dto.RepairStats;
import com.example.dto.InventoryTrend;

import java.util.List;
import java.util.Map;

public interface DashboardService {
    DashboardStats getDashboardStats();
    List<StatusDistribution> getStatusDistribution();
    RepairStats getRepairStats();
    InventoryTrend getInventoryTrend();
    /** 资产驾驶舱：一次性返回 KPI、分布、趋势、待办、盘点进度与最近资产 */
    Map<String, Object> getOverview();
}