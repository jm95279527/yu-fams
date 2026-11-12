package com.example.controller;

import cn.hutool.core.util.StrUtil;
import cn.hutool.poi.excel.ExcelUtil;
import cn.hutool.poi.excel.ExcelWriter;
import com.example.common.Result;
import com.example.entity.AssetFieldConfig;
import com.example.entity.AssetsIn;
import com.example.service.AssetFieldConfigService;
import com.example.service.AssetsInService;
import com.github.pagehelper.PageInfo;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 资产入库前端操作接口
 **/
@RestController
@RequestMapping("/assetsIn")
public class AssetsInController {

    @Resource
    private AssetsInService assetsInService;

    @Resource
    private AssetFieldConfigService assetFieldConfigService;

    /**
     * 新增
     */
    @PostMapping("/add")
    public Result add(@RequestBody AssetsIn assetsIn) {
        assetsInService.add(assetsIn);
        return Result.success();
    }

    /**
     * 删除
     */
    @DeleteMapping("/delete/{id}")
    public Result deleteById(@PathVariable Integer id) {
        assetsInService.deleteById(id);
        return Result.success();
    }

    /**
     * 批量删除
     */
    @DeleteMapping("/delete/batch")
    public Result deleteBatch(@RequestBody List<Integer> ids) {
        assetsInService.deleteBatch(ids);
        return Result.success();
    }

    /**
     * 修改
     */
    @PutMapping("/update")
    public Result updateById(@RequestBody AssetsIn assetsIn) {
        assetsInService.updateById(assetsIn);
        return Result.success();
    }

    /**
     * 管理员审核（pass=true 通过并生成资产；false 拒绝需填驳回原因）
     */
    @PostMapping("/audit/{id}")
    public Result audit(@PathVariable Integer id, @RequestBody Map<String, Object> body) {
        Boolean pass = body.get("pass") != null && Boolean.parseBoolean(body.get("pass").toString());
        String rejectReason = body.get("rejectReason") == null ? null : body.get("rejectReason").toString();
        try {
            assetsInService.audit(id, pass, rejectReason);
            return Result.success(pass ? "审核通过，已生成资产并自动编号" : "已驳回");
        } catch (Exception e) {
            return Result.error("500", e.getMessage());
        }
    }

    /**
     * 根据ID查询
     */
    @GetMapping("/selectById/{id}")
    public Result selectById(@PathVariable Integer id) {
        AssetsIn assetsIn = assetsInService.selectById(id);
        return Result.success(assetsIn);
    }

    /**
     * 查询所有
     */
    @GetMapping("/selectAll")
    public Result selectAll(AssetsIn assetsIn) {
        List<AssetsIn> list = assetsInService.selectAll(assetsIn);
        return Result.success(list);
    }

    /**
     * 分页查询
     */
    @GetMapping("/selectPage")
    public Result selectPage(AssetsIn assetsIn,
                             @RequestParam(defaultValue = "1") Integer pageNum,
                             @RequestParam(defaultValue = "10") Integer pageSize) {
        PageInfo<AssetsIn> page = assetsInService.selectPage(assetsIn, pageNum, pageSize);
        return Result.success(page);
    }

    /**
     * 下载导入模板
     */
    @GetMapping("/template")
    public void downloadTemplate(HttpServletResponse response) throws IOException {
        ExcelWriter writer = ExcelUtil.getWriter(true);
        // 列名取字段配置：系统字段改名后入库模板/导入同步生效
        Map<String, Object> row = new LinkedHashMap<>();
        for (Map.Entry<String, String> entry : inLabelMap().entrySet()) {
            row.put(entry.getKey(), sampleInValue(entry.getValue()));
        }
        writer.write(Arrays.asList(row), true);

        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8");
        response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode("资产入库导入模板", "UTF-8") + ".xlsx");
        ServletOutputStream out = response.getOutputStream();
        writer.flush(out, true);
        out.flush();
        writer.close();
        out.close();
    }

    /**
     * 批量导入入库单（导入后为待审核状态）
     */
    @PostMapping("/import")
    public Result importData(@RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            return Result.error("500", "请选择要上传的文件");
        }
        try {
            List<Map<String, Object>> rows = ExcelUtil.getReader(file.getInputStream()).readAll();
            if (rows == null || rows.isEmpty()) {
                return Result.error("500", "文件中没有数据");
            }
            // 表头（显示名称）→ 字段标识：字段改名后仍能正确导入
            Map<String, String> labelToKey = new LinkedHashMap<>();
            for (Map.Entry<String, String> entry : inLabelMap().entrySet()) {
                labelToKey.put(entry.getKey(), entry.getValue());
            }
            List<AssetsIn> list = new ArrayList<>();
            for (Map<String, Object> row : rows) {
                AssetsIn assetsIn = new AssetsIn();
                for (Map.Entry<String, Object> entry : row.entrySet()) {
                    String key = labelToKey.get(String.valueOf(entry.getKey()).trim());
                    if (key != null) {
                        setInValue(assetsIn, key, entry.getValue());
                    }
                }
                if (StrUtil.isNotBlank(assetsIn.getName())) {
                    list.add(assetsIn);
                }
            }
            if (list.isEmpty()) {
                return Result.error("500", "文件中没有可导入的数据，请确认资产名称列已填写");
            }
            int count = assetsInService.addBatch(list);
            return Result.success("成功导入 " + count + " 条入库单，请等待审核");
        } catch (Exception e) {
            return Result.error("500", "导入失败：" + e.getMessage());
        }
    }

    /**
     * 入库导入/模板的 列名 → 字段标识（系统字段名称取自定义字段配置）
     */
    private Map<String, String> inLabelMap() {
        Map<String, String> labels = assetFieldConfigService.labelMap();
        Map<String, String> map = new LinkedHashMap<>();
        map.put(labelOf(labels, "name", "资产名称"), "name");
        map.put(labelOf(labels, "category", "资产分类"), "category");
        map.put(labelOf(labels, "model", "资产型号"), "model");
        map.put(labelOf(labels, "num", "数量"), "num");
        map.put(labelOf(labels, "money", "初始价值"), "money");
        map.put(labelOf(labels, "depreciate", "折旧方法"), "depreciate");
        map.put("采购单号", "purchaseNo");
        map.put("供应商", "supplier");
        map.put(labelOf(labels, "location", "存放地点"), "location");
        map.put(labelOf(labels, "date", "购置日期"), "date");
        map.put("验收日期", "acceptDate");
        map.put("验收人", "acceptUser");
        map.put("验收意见", "acceptResult");
        map.put(labelOf(labels, "comment", "备注"), "comment");
        return map;
    }

    private String labelOf(Map<String, String> labels, String key, String fallback) {
        String value = labels.get(key);
        return StrUtil.isBlank(value) ? fallback : value;
    }

    private Object sampleInValue(String key) {
        switch (key) {
            case "name": return "示例笔记本电脑";
            case "category": return "办公设备";
            case "model": return "ThinkPad X1";
            case "num": return 10;
            case "money": return new java.math.BigDecimal("6500.00");
            case "depreciate": return "直线法";
            case "purchaseNo": return "CG20260912001";
            case "supplier": return "联想供应商";
            case "location": return "办公楼3层仓库";
            case "date": return "2026-09-12";
            case "acceptDate": return "2026-09-12";
            case "acceptUser": return "张三";
            case "acceptResult": return "验收合格";
            case "comment": return "备注示例";
            default: return "";
        }
    }

    private void setInValue(AssetsIn assetsIn, String key, Object value) {
        if (value == null) {
            return;
        }
        String text = String.valueOf(value).trim();
        if (text.isEmpty()) {
            return;
        }
        switch (key) {
            case "name": assetsIn.setName(text); break;
            case "category": assetsIn.setCategory(text); break;
            case "model": assetsIn.setModel(text); break;
            case "num":
                try { assetsIn.setNum((int) Double.parseDouble(text)); } catch (NumberFormatException ignored) { }
                break;
            case "money":
                try { assetsIn.setMoney(new java.math.BigDecimal(text)); } catch (NumberFormatException ignored) { }
                break;
            case "depreciate": assetsIn.setDepreciate(text); break;
            case "purchaseNo": assetsIn.setPurchaseNo(text); break;
            case "supplier": assetsIn.setSupplier(text); break;
            case "location": assetsIn.setLocation(text); break;
            case "date": assetsIn.setDate(text); break;
            case "acceptDate": assetsIn.setAcceptDate(text); break;
            case "acceptUser": assetsIn.setAcceptUser(text); break;
            case "acceptResult": assetsIn.setAcceptResult(text); break;
            case "comment": assetsIn.setComment(text); break;
            default: break;
        }
    }

    /**
     * 导出入库单（按当前筛选条件）
     */
    @GetMapping("/export")
    public void exportData(AssetsIn assetsIn, HttpServletResponse response) throws IOException {
        List<AssetsIn> list = assetsInService.selectAll(assetsIn);
        // 显式以中文列名作为 Map 键：AssetsIn 字段带 @Alias 注解，用 addHeaderAlias+setOnlyAlias 会丢弃全部列
        Map<String, String> labels = assetFieldConfigService.labelMap();
        List<Map<String, Object>> rows = new ArrayList<>();
        for (AssetsIn a : list) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("采购单号", a.getPurchaseNo());
            row.put(labelOf(labels, "name", "资产名称"), a.getName());
            row.put(labelOf(labels, "category", "资产分类"), a.getCategory());
            row.put(labelOf(labels, "model", "资产型号"), a.getModel());
            row.put(labelOf(labels, "num", "数量"), a.getNum());
            row.put(labelOf(labels, "money", "初始价值"), a.getMoney());
            row.put("供应商", a.getSupplier());
            row.put(labelOf(labels, "date", "购置日期"), a.getDate());
            row.put("验收日期", a.getAcceptDate());
            row.put("验收人", a.getAcceptUser());
            row.put("验收意见", a.getAcceptResult());
            row.put(labelOf(labels, "companyName", "所属公司"), a.getCompanyName());
            row.put(labelOf(labels, "departmentName", "使用部门"), a.getDepartmentName());
            row.put(labelOf(labels, "staffName", "责任人"), a.getManagerName());
            row.put(labelOf(labels, "location", "存放地点"), a.getLocation());
            row.put("生成" + labelOf(labels, "no", "资产编号"), a.getAssetsNo());
            row.put("审核状态", a.getStatus());
            row.put("提交人", a.getStaffName());
            row.put("审核人", a.getAuditUser());
            row.put("审核日期", a.getAuditDate());
            row.put("驳回原因", a.getRejectReason());
            row.put("备注", a.getComment());
            rows.add(row);
        }

        ExcelWriter writer = ExcelUtil.getWriter(true);
        writer.write(rows, true);

        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8");
        response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode("资产入库单", "UTF-8") + ".xlsx");
        ServletOutputStream out = response.getOutputStream();
        writer.flush(out, true);
        out.flush();
        writer.close();
        out.close();
    }

}
