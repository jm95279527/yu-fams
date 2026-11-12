package com.example.controller;

import cn.hutool.poi.excel.ExcelUtil;
import cn.hutool.poi.excel.ExcelWriter;
import com.example.common.Result;
import com.example.entity.AssetsTransfer;
import com.example.service.AssetFieldConfigService;
import com.example.service.AssetsTransferService;
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
 * 资产调拨前端操作接口
 **/
@RestController
@RequestMapping("/assetsTransfer")
public class AssetsTransferController {

    /** 批量导入模板列（顺序即模板列顺序） */
    private static final List<String> IMPORT_HEADERS = Arrays.asList(
            "资产编号", "新所属公司", "新使用部门", "新使用人", "新存放地点", "调拨原因", "备注");

    @Resource
    private AssetsTransferService assetsTransferService;

    @Resource
    private AssetFieldConfigService assetFieldConfigService;

    /**
     * 提交调拨申请
     */
    @PostMapping("/add")
    public Result add(@RequestBody AssetsTransfer assetsTransfer) {
        assetsTransferService.add(assetsTransfer);
        return Result.success();
    }

    /**
     * 删除
     */
    @DeleteMapping("/delete/{id}")
    public Result deleteById(@PathVariable Integer id) {
        assetsTransferService.deleteById(id);
        return Result.success();
    }

    /**
     * 批量删除
     */
    @DeleteMapping("/delete/batch")
    public Result deleteBatch(@RequestBody List<Integer> ids) {
        assetsTransferService.deleteBatch(ids);
        return Result.success();
    }

    /**
     * 修改（申请人编辑待审批单据）
     */
    @PutMapping("/update")
    public Result updateById(@RequestBody AssetsTransfer assetsTransfer) {
        assetsTransferService.updateById(assetsTransfer);
        return Result.success();
    }

    /**
     * 根据ID查询
     */
    @GetMapping("/selectById/{id}")
    public Result selectById(@PathVariable Integer id) {
        return Result.success(assetsTransferService.selectById(id));
    }

    /**
     * 查询所有
     */
    @GetMapping("/selectAll")
    public Result selectAll(AssetsTransfer assetsTransfer) {
        List<AssetsTransfer> list = assetsTransferService.selectAll(assetsTransfer);
        return Result.success(list);
    }

    /**
     * 分页查询
     */
    @GetMapping("/selectPage")
    public Result selectPage(AssetsTransfer assetsTransfer,
                             @RequestParam(defaultValue = "1") Integer pageNum,
                             @RequestParam(defaultValue = "10") Integer pageSize) {
        PageInfo<AssetsTransfer> page = assetsTransferService.selectPage(assetsTransfer, pageNum, pageSize);
        return Result.success(page);
    }

    /**
     * 根据资产ID查询调拨历史（历史追溯）
     */
    @GetMapping("/selectByAssetsId/{assetsId}")
    public Result selectByAssetsId(@PathVariable Integer assetsId) {
        return Result.success(assetsTransferService.selectByAssetsId(assetsId));
    }

    /**
     * 管理员审核：body {"pass": true/false, "rejectReason": "驳回原因"}
     */
    @PostMapping("/audit/{id}")
    public Result audit(@PathVariable Integer id, @RequestBody Map<String, Object> body) {
        Object passObj = body.get("pass");
        boolean pass = passObj != null && Boolean.parseBoolean(passObj.toString());
        String comment = body.get("rejectReason") == null ? null : body.get("rejectReason").toString();
        if (!pass && (comment == null || comment.trim().isEmpty())) {
            return Result.error("400", "驳回时必须填写原因");
        }
        assetsTransferService.audit(id, pass, comment);
        return Result.success();
    }

    /**
     * 下载批量调拨导入模板
     */
    @GetMapping("/template")
    public void downloadTemplate(HttpServletResponse response) throws IOException {
        ExcelWriter writer = ExcelUtil.getWriter(true);
        writer.writeHeadRow(IMPORT_HEADERS);
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8");
        response.setHeader("Content-Disposition",
                "attachment;filename=" + URLEncoder.encode("资产调拨导入模板", "UTF-8") + ".xlsx");
        ServletOutputStream out = response.getOutputStream();
        writer.flush(out, true);
        out.flush();
        writer.close();
        out.close();
    }

    /**
     * 批量导入调拨申请（逐行校验，导入后为待审批）
     */
    @PostMapping("/import")
    public Result importData(@RequestParam("file") MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            return Result.error("500", "请选择要上传的文件");
        }
        try {
            List<Map<String, Object>> rows = ExcelUtil.getReader(file.getInputStream()).readAll();
            if (rows == null || rows.isEmpty()) {
                return Result.error("500", "文件中没有数据");
            }
            List<Map<String, String>> list = new ArrayList<>();
            int index = 1;
            for (Map<String, Object> row : rows) {
                index++;
                Map<String, String> item = new LinkedHashMap<>();
                boolean empty = true;
                for (String header : IMPORT_HEADERS) {
                    String value = cell(row, header);
                    item.put(header, value);
                    if (!value.isEmpty()) {
                        empty = false;
                    }
                }
                if (empty) {
                    continue;
                }
                item.put("__row", String.valueOf(index));
                list.add(item);
            }
            if (list.isEmpty()) {
                return Result.error("500", "文件中没有可导入的数据");
            }
            return Result.success(assetsTransferService.importBatch(list));
        } catch (Exception e) {
            return Result.error("500", "导入失败：" + e.getMessage());
        }
    }

    /**
     * 读取单元格（表头容错空格；数字型编号去掉 .0）
     */
    private String cell(Map<String, Object> row, String header) {
        Object value = row.get(header);
        if (value == null) {
            for (Map.Entry<String, Object> entry : row.entrySet()) {
                if (entry.getKey() != null && entry.getKey().trim().equals(header)) {
                    value = entry.getValue();
                    break;
                }
            }
        }
        if (value == null) {
            return "";
        }
        if (value instanceof Number) {
            double d = ((Number) value).doubleValue();
            if (!Double.isNaN(d) && !Double.isInfinite(d) && d == Math.floor(d)) {
                return String.valueOf((long) d);
            }
        }
        return String.valueOf(value).trim();
    }

    /**
     * 导出调拨记录
     */
    @GetMapping("/export")
    public void exportData(HttpServletResponse response) throws IOException {
        ExcelWriter writer = ExcelUtil.getWriter(true);
        List<AssetsTransfer> list = assetsTransferService.selectAll(null);
        // 列名取字段配置，系统字段改名后导出同步生效
        Map<String, String> labels = assetFieldConfigService.labelMap();
        List<Map<String, Object>> rows = new ArrayList<>();
        for (AssetsTransfer t : list) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put(labels.getOrDefault("no", "资产编号"), t.getAssetsNo());
            row.put(labels.getOrDefault("name", "资产名称"), t.getAssetsName());
            row.put("申请时间", t.getTransferTime());
            row.put("申请人", t.getTransferStaffName());
            row.put(labels.getOrDefault("companyName", "所属公司") + "（调拨前）", t.getFromCompanyName());
            row.put(labels.getOrDefault("departmentName", "使用部门") + "（调拨前）", t.getFromDepartmentName());
            row.put(labels.getOrDefault("staffName", "责任人") + "（调拨前）", t.getFromStaffName());
            row.put(labels.getOrDefault("location", "存放地点") + "（调拨前）", t.getFromLocation());
            row.put(labels.getOrDefault("companyName", "所属公司") + "（调拨后）", t.getToCompanyName());
            row.put(labels.getOrDefault("departmentName", "使用部门") + "（调拨后）", t.getToDepartmentName());
            row.put(labels.getOrDefault("staffName", "责任人") + "（调拨后）", t.getToStaffName());
            row.put(labels.getOrDefault("location", "存放地点") + "（调拨后）", t.getToLocation());
            row.put("调拨原因", t.getReason());
            row.put("状态", t.getStatus());
            row.put("审批人", t.getApproverName());
            row.put("审批时间", t.getApproveTime());
            row.put("审批意见", t.getApproveComment());
            row.put("备注", t.getComment());
            rows.add(row);
        }
        writer.write(rows, true);

        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8");
        response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode("资产调拨表", "UTF-8") + ".xlsx");
        ServletOutputStream outputStream = response.getOutputStream();
        writer.flush(outputStream, true);
        outputStream.flush();
        writer.close();
        outputStream.close();
    }
}
