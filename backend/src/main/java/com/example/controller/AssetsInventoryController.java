package com.example.controller;

import cn.hutool.poi.excel.ExcelUtil;
import cn.hutool.poi.excel.ExcelWriter;
import com.example.common.Result;
import com.example.entity.Company;
import com.example.entity.InventoryItem;
import com.example.entity.InventoryTask;
import com.example.service.AssetFieldConfigService;
import com.example.service.AssetsInventoryService;
import com.example.service.CompanyService;
import com.github.pagehelper.PageInfo;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.util.List;
import java.util.Map;

/**
 * 资产盘点前端操作接口
 */
@RestController
@RequestMapping("/assetsInventory")
public class AssetsInventoryController {

    @Resource
    private AssetsInventoryService inventoryService;

    @Resource
    private AssetFieldConfigService assetFieldConfigService;

    @Resource
    private CompanyService companyService;

    /**
     * 盘点范围可选公司（挂在盘点接口下，具备盘点菜单权限即可读取）
     */
    @GetMapping("/companies")
    public Result companies() {
        return Result.success(companyService.selectAll(new Company()));
    }

    /**
     * 创建盘点任务（按范围快照资产）
     */
    @PostMapping("/add")
    public Result add(@RequestBody InventoryTask form) {
        return Result.success(inventoryService.create(form));
    }

    /**
     * 分页查询盘点任务
     */
    @GetMapping("/selectPage")
    public Result selectPage(InventoryTask query,
                             @RequestParam(defaultValue = "1") Integer pageNum,
                             @RequestParam(defaultValue = "10") Integer pageSize) {
        PageInfo<InventoryTask> page = inventoryService.selectPage(query, pageNum, pageSize);
        return Result.success(page);
    }

    /**
     * 任务详情
     */
    @GetMapping("/selectById/{id}")
    public Result selectById(@PathVariable Integer id) {
        return Result.success(inventoryService.selectById(id));
    }

    /**
     * 任务明细：?itemStatus=未盘&keyword=编号/名称
     */
    @GetMapping("/items/{taskId}")
    public Result items(@PathVariable Integer taskId,
                        @RequestParam(required = false) String itemStatus,
                        @RequestParam(required = false) String keyword) {
        return Result.success(inventoryService.items(taskId, itemStatus, keyword));
    }

    /**
     * 扫码盘点
     * body: {"code":"资产ID/编号/二维码链接", "actualLocation":"实盘地点", "abnormal":false, "comment":"备注"}
     */
    @PostMapping("/scan/{taskId}")
    public Result scan(@PathVariable Integer taskId, @RequestBody Map<String, Object> body) {
        String code = body.get("code") == null ? null : body.get("code").toString();
        String actualLocation = body.get("actualLocation") == null ? null : body.get("actualLocation").toString();
        String comment = body.get("comment") == null ? null : body.get("comment").toString();
        Boolean abnormal = null;
        Object ab = body.get("abnormal");
        if (ab != null) {
            abnormal = Boolean.parseBoolean(ab.toString());
        }
        return Result.success(inventoryService.scan(taskId, code, actualLocation, abnormal, comment));
    }

    /**
     * 调整明细结果（正常/异常）
     * body: {"itemStatus":"异常", "comment":"备注"}
     */
    @PostMapping("/markItem/{itemId}")
    public Result markItem(@PathVariable Integer itemId, @RequestBody Map<String, Object> body) {
        String itemStatus = body.get("itemStatus") == null ? null : body.get("itemStatus").toString();
        String comment = body.get("comment") == null ? null : body.get("comment").toString();
        inventoryService.markItem(itemId, itemStatus, comment);
        return Result.success();
    }

    /**
     * 完成盘点（未盘资产记为盘亏）
     */
    @PostMapping("/finish/{id}")
    public Result finish(@PathVariable Integer id) {
        return Result.success(inventoryService.finish(id));
    }

    /**
     * 处理盘点差异（盘盈/盘亏/异常）
     * body: {"dealType":"报损", "dealRemark":"说明"}
     */
    @PostMapping("/dealItem/{itemId}")
    public Result dealItem(@PathVariable Integer itemId, @RequestBody Map<String, Object> body) {
        String dealType = body.get("dealType") == null ? null : body.get("dealType").toString();
        String dealRemark = body.get("dealRemark") == null ? null : body.get("dealRemark").toString();
        return Result.success(inventoryService.dealItem(itemId, dealType, dealRemark));
    }

    /**
     * 盘点人工作量统计
     */
    @GetMapping("/workload/{taskId}")
    public Result workload(@PathVariable Integer taskId) {
        return Result.success(inventoryService.workload(taskId));
    }

    /**
     * 删除盘点任务（仅盘点中）
     */
    @DeleteMapping("/delete/{id}")
    public Result delete(@PathVariable Integer id) {
        inventoryService.delete(id);
        return Result.success();
    }

    /**
     * 导出盘点报告（任务全部明细）
     * 注意：hutool 5.8.22 的 beanToMap 会把实体上的 @Alias 值直接作为 map key，
     * 因此这里不依赖 bean 导出，改用显式中文 key 的 Map 行，彻底杜绝内部字段泄漏。
     */
    @GetMapping("/export/{taskId}")
    public void export(@PathVariable Integer taskId, HttpServletResponse response) throws IOException {
        InventoryTask task = inventoryService.selectById(taskId);
        List<InventoryItem> list = inventoryService.items(taskId, null, null);
        Map<String, String> labels = assetFieldConfigService.labelMap();
        List<Map<String, Object>> rows = new java.util.ArrayList<>();
        for (InventoryItem it : list) {
            Map<String, Object> row = new java.util.LinkedHashMap<>();
            row.put("资产ID", it.getAssetsId());
            row.put(labels.getOrDefault("no", "资产编号"), it.getAssetsNo());
            row.put(labels.getOrDefault("name", "资产名称"), it.getAssetsName());
            row.put(labels.getOrDefault("model", "资产型号"), it.getModel());
            row.put("范围外盘盈", it.getIsExtra() != null && it.getIsExtra() == 1 ? "是" : "");
            row.put(labels.getOrDefault("category", "资产分类"), it.getCategory());
            row.put("台账" + labels.getOrDefault("departmentName", "使用部门"), it.getDepartmentName());
            row.put("台账" + labels.getOrDefault("staffName", "责任人"), it.getStaffName());
            row.put("台账" + labels.getOrDefault("location", "存放地点"), it.getLocation());
            row.put("实盘地点", it.getActualLocation());
            row.put("盘点结果", it.getItemStatus());
            row.put("处理状态", it.getDealStatus());
            row.put("处理方式", it.getDealType());
            row.put("处理说明", it.getDealRemark());
            row.put("处理人", it.getDealUser());
            row.put("处理时间", it.getDealTime());
            row.put("盘点人", it.getScannerName());
            row.put("盘点时间", it.getScanTime());
            row.put("备注", it.getComment());
            rows.add(row);
        }
        ExcelWriter writer = ExcelUtil.getWriter(true);
        // 报告头信息
        writer.writeCellValue(0, 0, "盘点任务：" + task.getName());
        writer.writeCellValue(0, 1, "盘点范围：" + task.getScopeName());
        writer.writeCellValue(0, 2, "盘点结果：应盘 " + nz(task.getTotalCount())
                + "，正常 " + nz(task.getNormalCount())
                + "，盘盈 " + nz(task.getProfitCount())
                + "，盘亏 " + nz(task.getLossCount())
                + "，异常 " + nz(task.getAbnormalCount())
                + "，待处理差异 " + nz(task.getPendingDiffCount()));
        writer.setCurrentRow(4);
        writer.write(rows, true);

        String fileName = URLEncoder.encode("盘点报告-" + task.getName(), "UTF-8") + ".xlsx";
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8");
        response.setHeader("Content-Disposition", "attachment;filename=" + fileName);
        ServletOutputStream out = response.getOutputStream();
        writer.flush(out, true);
        out.flush();
        writer.close();
        out.close();
    }

    private int nz(Integer v) {
        return v == null ? 0 : v;
    }
}
