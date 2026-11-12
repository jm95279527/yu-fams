package com.example.service.impl;

import cn.hutool.core.date.DateUtil;
import com.example.entity.Account;
import com.example.entity.Assets;
import com.example.entity.Category;
import com.example.entity.Company;
import com.example.entity.Department;
import com.example.entity.InventoryItem;
import com.example.entity.InventoryTask;
import com.example.exception.CustomException;
import com.example.mapper.AssetsMapper;
import com.example.mapper.CategoryMapper;
import com.example.mapper.CompanyMapper;
import com.example.mapper.DepartmentMapper;
import com.example.mapper.InventoryItemMapper;
import com.example.mapper.InventoryTaskMapper;
import com.example.service.AssetsInventoryService;
import com.example.utils.TokenUtils;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * 资产盘点业务实现
 */
@Service
public class AssetsInventoryServiceImpl implements AssetsInventoryService {

    /** 各差异类型允许的处理方式 */
    private static final Map<String, Set<String>> DEAL_TYPES = new HashMap<>();
    static {
        DEAL_TYPES.put("盘亏", new HashSet<>(Arrays.asList("报损", "赔偿", "挂账待查", "误盘")));
        DEAL_TYPES.put("盘盈", new HashSet<>(Arrays.asList("补录入账", "寄存待查", "误盘")));
        DEAL_TYPES.put("异常", new HashSet<>(Arrays.asList("调拨修正", "信息更正", "误盘")));
    }

    @Resource
    private InventoryTaskMapper taskMapper;
    @Resource
    private InventoryItemMapper itemMapper;
    @Resource
    private AssetsMapper assetsMapper;
    @Resource
    private DepartmentMapper departmentMapper;
    @Resource
    private CompanyMapper companyMapper;
    @Resource
    private CategoryMapper categoryMapper;

    @Override
    @Transactional
    public InventoryTask create(InventoryTask form) {
        Account user = TokenUtils.getCurrentUser();
        if (user == null) {
            throw new CustomException("4001", "未登录");
        }
        if (form.getName() == null || form.getName().trim().isEmpty()) {
            throw new CustomException("500", "请填写盘点任务名称");
        }
        String scopeType = form.getScopeType() == null ? "ALL" : form.getScopeType();
        form.setScopeType(scopeType);

        // 解析范围并快照资产
        Assets query = new Assets();
        String scopeName = "全部资产";
        String categoryName = null;
        if ("DEPT".equals(scopeType)) {
            if (form.getScopeId() == null) {
                throw new CustomException("500", "请选择盘点部门");
            }
            Department dept = departmentMapper.selectById(form.getScopeId());
            if (dept == null) {
                throw new CustomException("500", "所选部门不存在");
            }
            scopeName = "部门：" + dept.getName();
            query.setDepartmentId(form.getScopeId());
        } else if ("COMPANY".equals(scopeType)) {
            if (form.getScopeId() == null) {
                throw new CustomException("500", "请选择盘点公司");
            }
            Company company = companyMapper.selectById(form.getScopeId());
            if (company == null) {
                throw new CustomException("500", "所选公司不存在");
            }
            scopeName = "公司：" + company.getName();
            query.setCompanyId(form.getScopeId());
        } else if ("CATEGORY".equals(scopeType)) {
            if (form.getScopeId() == null) {
                throw new CustomException("500", "请选择盘点分类");
            }
            Category category = categoryMapper.selectById(form.getScopeId());
            if (category == null) {
                throw new CustomException("500", "所选分类不存在");
            }
            categoryName = category.getName();
            scopeName = "分类：" + categoryName;
            query.setCategory(categoryName);
        }
        form.setScopeName(scopeName);

        List<Assets> assetsList = assetsMapper.selectAll(query);
        List<InventoryItem> items = new ArrayList<>();
        for (Assets a : assetsList) {
            // 分类为精确匹配（selectAll 使用 LIKE）；报废资产不纳入盘点
            if (categoryName != null && !categoryName.equals(a.getCategory())) {
                continue;
            }
            if ("报废".equals(a.getStatus())) {
                continue;
            }
            InventoryItem item = new InventoryItem();
            item.setAssetsId(a.getId());
            item.setAssetsNo(a.getNo());
            item.setAssetsName(a.getName());
            item.setModel(a.getModel());
            item.setCategory(a.getCategory());
            item.setDepartmentId(a.getDepartmentId());
            item.setDepartmentName(a.getDepartmentName());
            item.setStaffId(a.getStaffId());
            item.setStaffName(a.getStaffName());
            item.setLocation(a.getLocation());
            item.setItemStatus("未盘");
            item.setIsExtra(0);
            items.add(item);
        }
        if (items.isEmpty()) {
            throw new CustomException("500", "所选盘点范围内没有可盘点的资产");
        }

        form.setStatus("盘点中");
        form.setAccessCode(UUID.randomUUID().toString().replace("-", ""));
        form.setCreatorId(user.getId());
        form.setCreatorName(displayName(user));
        form.setTotalCount(items.size());
        form.setNormalCount(0);
        form.setProfitCount(0);
        form.setLossCount(0);
        form.setAbnormalCount(0);
        form.setPendingDiffCount(0);
        taskMapper.insert(form);

        for (InventoryItem item : items) {
            item.setTaskId(form.getId());
        }
        itemMapper.batchInsert(items);
        return form;
    }

    @Override
    public PageInfo<InventoryTask> selectPage(InventoryTask query, Integer pageNum, Integer pageSize) {
        PageHelper.startPage(pageNum, pageSize);
        List<InventoryTask> list = taskMapper.selectAll(query);
        return PageInfo.of(list);
    }

    @Override
    public InventoryTask selectById(Integer id) {
        InventoryTask task = taskMapper.selectById(id);
        if (task == null) {
            throw new CustomException("500", "盘点任务不存在");
        }
        return task;
    }

    @Override
    public List<InventoryItem> items(Integer taskId, String itemStatus, String keyword) {
        return itemMapper.selectByTask(taskId, itemStatus, keyword);
    }

    @Override
    @Transactional
    public InventoryItem scan(Integer taskId, String rawCode, String actualLocation, Boolean abnormal, String comment) {
        Account user = TokenUtils.getCurrentUser();
        if (user == null) {
            throw new CustomException("4001", "未登录");
        }
        InventoryTask task = taskMapper.selectById(taskId);
        if (task == null) {
            throw new CustomException("500", "盘点任务不存在");
        }
        if ("已完成".equals(task.getStatus())) {
            throw new CustomException("500", "盘点任务已完成，不能继续扫码");
        }
        if (rawCode == null || rawCode.trim().isEmpty()) {
            throw new CustomException("500", "扫码内容为空");
        }
        Assets asset = resolveAsset(rawCode.trim());
        if (asset == null) {
            throw new CustomException("500", "未找到该资产：" + rawCode);
        }
        return scanAsset(task, asset, actualLocation, abnormal, comment, user.getId(), displayName(user));
    }

    /**
     * 扫码盘点核心逻辑（后台/手机端共用）
     */
    private InventoryItem scanAsset(InventoryTask task, Assets asset, String actualLocation,
                                    Boolean abnormal, String comment, Integer scannerId, String operator) {
        Integer taskId = task.getId();
        String now = DateUtil.now();
        InventoryItem item = itemMapper.selectByTaskAndAssets(taskId, asset.getId());
        if (item != null) {
            if (!"未盘".equals(item.getItemStatus())) {
                String who = (item.getScannerName() == null || item.getScannerName().trim().isEmpty())
                        ? "" : "，盘点人：" + item.getScannerName();
                String when = (item.getScanTime() == null || item.getScanTime().trim().isEmpty())
                        ? "" : "，时间：" + item.getScanTime();
                throw new CustomException("500",
                        "该资产已盘点（" + item.getItemStatus() + who + when + "），请勿重复扫码");
            }
            // 判定正常/异常：显式异常优先；其次比对实盘地点与台账地点
            String result = "正常";
            if (Boolean.TRUE.equals(abnormal)) {
                result = "异常";
            } else if (actualLocation != null && !actualLocation.trim().isEmpty()
                    && !actualLocation.trim().equals(item.getLocation() == null ? "" : item.getLocation().trim())) {
                result = "异常";
            }
            item.setItemStatus(result);
            if ("异常".equals(result)) {
                item.setDealStatus("待处理");
            }
            item.setActualLocation(actualLocation == null || actualLocation.trim().isEmpty()
                    ? item.getLocation() : actualLocation.trim());
            item.setScannerId(scannerId);
            item.setScannerName(operator);
            item.setScanTime(now);
            if (comment != null && !comment.trim().isEmpty()) {
                item.setComment(comment.trim());
            }
            itemMapper.updateById(item);
        } else {
            // 范围外扫到的资产 → 盘盈登记
            item = new InventoryItem();
            item.setTaskId(taskId);
            item.setAssetsId(asset.getId());
            item.setAssetsNo(asset.getNo());
            item.setAssetsName(asset.getName());
            item.setModel(asset.getModel());
            item.setCategory(asset.getCategory());
            item.setDepartmentId(asset.getDepartmentId());
            item.setDepartmentName(asset.getDepartmentName());
            item.setStaffId(asset.getStaffId());
            item.setStaffName(asset.getStaffName());
            item.setLocation(asset.getLocation());
            item.setActualLocation(actualLocation);
            item.setItemStatus("盘盈");
            item.setDealStatus("待处理");
            item.setIsExtra(1);
            item.setScannerId(scannerId);
            item.setScannerName(operator);
            item.setScanTime(now);
            item.setComment((comment == null || comment.trim().isEmpty()) ? "范围外扫入，盘盈登记" : comment.trim());
            itemMapper.insert(item);
        }

        recalcStats(taskId);
        return itemMapper.selectById(item.getId());
    }

    // ==================== 手机扫码盘点（公开） ====================

    @Override
    public Map<String, Object> publicTask(String accessCode) {
        InventoryTask task = requireTaskByCode(accessCode);
        int normal = 0, profit = 0, loss = 0, abnormal = 0, unscanned = 0;
        for (Map<String, Object> row : itemMapper.countByTask(task.getId())) {
            String st = String.valueOf(row.get("itemStatus"));
            int cnt = ((Number) row.get("cnt")).intValue();
            switch (st) {
                case "正常": normal = cnt; break;
                case "盘盈": profit = cnt; break;
                case "盘亏": loss = cnt; break;
                case "异常": abnormal = cnt; break;
                case "未盘": unscanned = cnt; break;
                default: break;
            }
        }
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("name", task.getName());
        data.put("scopeName", task.getScopeName());
        data.put("status", task.getStatus());
        data.put("remark", task.getRemark());
        data.put("createTime", task.getCreateTime());
        data.put("finishTime", task.getFinishTime());
        data.put("normalCount", normal);
        data.put("abnormalCount", abnormal);
        data.put("profitCount", profit);
        data.put("lossCount", loss);
        data.put("unscannedCount", unscanned);
        data.put("scannedCount", normal + abnormal + profit + loss);
        // 应盘 = 台账快照数量（不含范围外盘盈）
        data.put("totalCount", normal + abnormal + loss + unscanned);
        return data;
    }

    @Override
    public List<Map<String, Object>> publicItems(String accessCode, String tab, String keyword) {
        InventoryTask task = requireTaskByCode(accessCode);
        Integer scanned = null;
        if ("已盘".equals(tab)) {
            scanned = 1;
        } else if ("未盘".equals(tab)) {
            scanned = 0;
        }
        List<InventoryItem> list = itemMapper.selectByTaskScope(task.getId(), scanned, keyword);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (InventoryItem it : list) {
            rows.add(publicItem(it));
        }
        return rows;
    }

    @Override
    public Map<String, Object> lookup(String accessCode, String code) {
        InventoryTask task = requireTaskByCode(accessCode);
        if ("已完成".equals(task.getStatus())) {
            throw new CustomException("500", "盘点任务已完成，不能再扫码盘点");
        }
        if (code == null || code.trim().isEmpty()) {
            throw new CustomException("500", "扫码内容为空");
        }
        Assets asset = resolveAsset(code.trim());
        if (asset == null) {
            throw new CustomException("500", "未找到该资产，请确认是本系统打印的资产二维码");
        }
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("no", asset.getNo());
        data.put("name", asset.getName());
        data.put("category", asset.getCategory());
        data.put("model", asset.getModel());
        data.put("img", asset.getImg());
        data.put("status", asset.getStatus());
        data.put("companyName", asset.getCompanyName());
        data.put("departmentName", asset.getDepartmentName());
        data.put("staffName", asset.getStaffName());
        data.put("location", asset.getLocation());

        InventoryItem item = itemMapper.selectByTaskAndAssets(task.getId(), asset.getId());
        boolean scanned = item != null && !"未盘".equals(item.getItemStatus());
        data.put("scanned", scanned);
        data.put("outOfScope", item == null);
        if (scanned) {
            data.put("itemStatus", item.getItemStatus());
            data.put("scannerName", item.getScannerName());
            data.put("scanTime", item.getScanTime());
            data.put("comment", item.getComment());
        }
        return data;
    }

    @Override
    @Transactional
    public InventoryItem publicScan(String accessCode, String code, String comment) {
        InventoryTask task = requireTaskByCode(accessCode);
        if ("已完成".equals(task.getStatus())) {
            throw new CustomException("500", "盘点任务已完成，不能再扫码盘点");
        }
        if (code == null || code.trim().isEmpty()) {
            throw new CustomException("500", "扫码内容为空");
        }
        Assets asset = resolveAsset(code.trim());
        if (asset == null) {
            throw new CustomException("500", "未找到该资产，请确认是本系统打印的资产二维码");
        }
        return scanAsset(task, asset, null, null, comment, null, "手机扫码");
    }

    private InventoryTask requireTaskByCode(String accessCode) {
        if (accessCode == null || accessCode.trim().isEmpty()) {
            throw new CustomException("500", "盘点单二维码无效");
        }
        InventoryTask task = taskMapper.selectByAccessCode(accessCode.trim());
        if (task == null) {
            throw new CustomException("500", "盘点单不存在或已删除，请联系资产管理员");
        }
        return task;
    }

    private Map<String, Object> publicItem(InventoryItem it) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", it.getId());
        row.put("assetsNo", it.getAssetsNo());
        row.put("assetsName", it.getAssetsName());
        row.put("category", it.getCategory());
        row.put("departmentName", it.getDepartmentName());
        row.put("staffName", it.getStaffName());
        row.put("location", it.getLocation());
        row.put("actualLocation", it.getActualLocation());
        row.put("itemStatus", it.getItemStatus());
        row.put("isExtra", it.getIsExtra());
        row.put("scannerName", it.getScannerName());
        row.put("scanTime", it.getScanTime());
        row.put("comment", it.getComment());
        return row;
    }

    @Override
    @Transactional
    public void markItem(Integer itemId, String itemStatus, String comment) {
        InventoryItem item = itemMapper.selectById(itemId);
        if (item == null) {
            throw new CustomException("500", "盘点明细不存在");
        }
        InventoryTask task = taskMapper.selectById(item.getTaskId());
        if ("已完成".equals(task.getStatus())) {
            throw new CustomException("500", "盘点任务已完成，明细不能修改");
        }
        if ("未盘".equals(item.getItemStatus())) {
            throw new CustomException("500", "该资产尚未盘点，请先扫码");
        }
        if ("盘盈".equals(item.getItemStatus())) {
            throw new CustomException("500", "盘盈明细不能改为正常/异常");
        }
        if (!"正常".equals(itemStatus) && !"异常".equals(itemStatus)) {
            throw new CustomException("500", "仅支持标记为正常或异常");
        }
        if ("正常".equals(itemStatus)) {
            // 改回正常：清空可能存在的差异处理信息
            itemMapper.clearDeal(itemId);
        } else if ("异常".equals(itemStatus) && !"已处理".equals(item.getDealStatus())) {
            InventoryItem dealPatch = new InventoryItem();
            dealPatch.setId(itemId);
            dealPatch.setDealStatus("待处理");
            itemMapper.updateById(dealPatch);
        }
        InventoryItem patch = new InventoryItem();
        patch.setId(itemId);
        patch.setItemStatus(itemStatus);
        if (comment != null) {
            patch.setComment(comment);
        }
        itemMapper.updateById(patch);
        recalcStats(item.getTaskId());
    }

    @Override
    @Transactional
    public InventoryItem dealItem(Integer itemId, String dealType, String dealRemark) {
        Account user = TokenUtils.getCurrentUser();
        if (user == null) {
            throw new CustomException("4001", "未登录");
        }
        InventoryItem item = itemMapper.selectById(itemId);
        if (item == null) {
            throw new CustomException("500", "盘点明细不存在");
        }
        InventoryTask task = taskMapper.selectById(item.getTaskId());
        if (task == null) {
            throw new CustomException("500", "盘点任务不存在");
        }
        String status = item.getItemStatus();
        Set<String> allowed = DEAL_TYPES.get(status);
        if (allowed == null) {
            throw new CustomException("500", "只有盘盈、盘亏、异常明细需要处理");
        }
        if ("已处理".equals(item.getDealStatus())) {
            throw new CustomException("500", "该差异已处理，请勿重复提交");
        }
        if (dealType == null || dealType.trim().isEmpty()) {
            throw new CustomException("500", "请选择处理方式");
        }
        dealType = dealType.trim();
        if (!allowed.contains(dealType)) {
            throw new CustomException("500", "处理方式不合法：" + dealType);
        }
        InventoryItem patch = new InventoryItem();
        patch.setId(itemId);
        patch.setDealStatus("已处理");
        patch.setDealType(dealType);
        patch.setDealRemark(dealRemark == null ? "" : dealRemark.trim());
        patch.setDealUserId(user.getId());
        patch.setDealUser(displayName(user));
        patch.setDealTime(DateUtil.now());
        itemMapper.updateById(patch);
        recalcStats(item.getTaskId());
        return itemMapper.selectById(itemId);
    }

    @Override
    public List<Map<String, Object>> workload(Integer taskId) {
        InventoryTask task = taskMapper.selectById(taskId);
        if (task == null) {
            throw new CustomException("500", "盘点任务不存在");
        }
        return itemMapper.workload(taskId);
    }

    @Override
    @Transactional
    public InventoryTask finish(Integer taskId) {
        InventoryTask task = taskMapper.selectById(taskId);
        if (task == null) {
            throw new CustomException("500", "盘点任务不存在");
        }
        if ("已完成".equals(task.getStatus())) {
            throw new CustomException("500", "盘点任务已完成，请勿重复操作");
        }
        // 未盘 → 盘亏
        itemMapper.markUncheckedAsLoss(taskId);
        recalcStats(taskId);

        InventoryTask patch = new InventoryTask();
        patch.setId(taskId);
        patch.setStatus("已完成");
        patch.setFinishTime(DateUtil.now());
        taskMapper.updateById(patch);
        return taskMapper.selectById(taskId);
    }

    @Override
    @Transactional
    public void delete(Integer taskId) {
        InventoryTask task = taskMapper.selectById(taskId);
        if (task == null) {
            throw new CustomException("500", "盘点任务不存在");
        }
        if ("已完成".equals(task.getStatus())) {
            throw new CustomException("500", "已完成的盘点任务不能删除（需保留盘点报告）");
        }
        itemMapper.deleteByTask(taskId);
        taskMapper.deleteById(taskId);
    }

    /**
     * 根据各状态明细数量重新汇总任务统计
     */
    private void recalcStats(Integer taskId) {
        List<Map<String, Object>> rows = itemMapper.countByTask(taskId);
        int total = 0, normal = 0, profit = 0, loss = 0, abnormal = 0;
        for (Map<String, Object> row : rows) {
            String st = String.valueOf(row.get("itemStatus"));
            int cnt = ((Number) row.get("cnt")).intValue();
            total += cnt;
            switch (st) {
                case "正常": normal += cnt; break;
                case "盘盈": profit += cnt; break;
                case "盘亏": loss += cnt; break;
                case "异常": abnormal += cnt; break;
                default: break;
            }
        }
        InventoryTask patch = new InventoryTask();
        patch.setId(taskId);
        patch.setTotalCount(total);
        patch.setNormalCount(normal);
        patch.setProfitCount(profit);
        patch.setLossCount(loss);
        patch.setAbnormalCount(abnormal);
        patch.setPendingDiffCount(itemMapper.countPending(taskId));
        taskMapper.updateById(patch);
    }

    /**
     * 扫码内容解析为资产：支持资产编号、ID、二维码链接 http(s)://.../scan/{资产编号或ID}
     */
    private Assets resolveAsset(String code) {
        String c = code.trim();
        int idx = c.lastIndexOf("/scan/");
        if (idx >= 0) {
            String tail = c.substring(idx + 6);
            int stop = tail.indexOf('?');
            if (stop >= 0) {
                tail = tail.substring(0, stop);
            }
            stop = tail.indexOf('#');
            if (stop >= 0) {
                tail = tail.substring(0, stop);
            }
            if (tail.endsWith("/")) {
                tail = tail.substring(0, tail.length() - 1);
            }
            try {
                tail = java.net.URLDecoder.decode(tail, "UTF-8");
            } catch (Exception ignored) {
                // 保持原值
            }
            if (!tail.isEmpty()) {
                // 历史二维码为数字 ID，优先按 ID 兼容
                if (tail.matches("\\d+")) {
                    Assets byId = assetsMapper.selectJoinedById(Integer.valueOf(tail));
                    if (byId != null) {
                        return byId;
                    }
                }
                Assets byNo = assetsMapper.selectJoinedByNo(tail);
                if (byNo != null) {
                    return byNo;
                }
            }
        }
        if (c.matches("\\d+")) {
            Assets byId = assetsMapper.selectJoinedById(Integer.valueOf(c));
            if (byId != null) {
                return byId;
            }
        }
        return assetsMapper.selectJoinedByNo(c);
    }

    private String displayName(Account user) {
        String name = user.getName();
        return (name == null || name.trim().isEmpty()) ? user.getUsername() : name;
    }
}
