package com.example.controller;

import cn.hutool.core.util.StrUtil;
import cn.hutool.poi.excel.ExcelUtil;
import cn.hutool.poi.excel.ExcelWriter;
import com.example.common.Result;
import com.example.entity.AssetFieldConfig;
import com.example.entity.Assets;
import com.example.entity.Company;
import com.example.entity.Department;
import com.example.entity.Staff;
import com.example.exception.CustomException;
import com.example.mapper.CompanyMapper;
import com.example.mapper.DepartmentMapper;
import com.example.mapper.StaffMapper;
import com.example.service.AssetFieldConfigService;
import com.example.service.AssetsService;
import com.github.pagehelper.PageInfo;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * 资产信息前端操作接口
 **/
@RestController
@RequestMapping("/assets")
public class AssetsController {

    /** 可导出的系统字段（字段标识） */
    private static final List<String> EXPORT_KEYS = Arrays.asList(
            "no", "name", "category", "model", "num", "date", "money", "depreciate",
            "companyName", "departmentName", "staffName", "location", "status", "comment");

    /** 可通过 Excel 导入的系统字段（公司/部门/责任人按名称匹配后转ID） */
    private static final List<String> IMPORT_KEYS = Arrays.asList(
            "no", "name", "category", "model", "num", "date", "money", "depreciate",
            "companyName", "departmentName", "staffName", "location", "status", "comment");

    /** 关联字段（导入时按名称解析，不直接赋值） */
    private static final List<String> ORG_KEYS = Arrays.asList(
            "companyName", "departmentName", "staffName");

    @Resource
    private AssetsService assetsService;

    @Resource
    private AssetFieldConfigService assetFieldConfigService;

    @Resource
    private CompanyMapper companyMapper;

    @Resource
    private DepartmentMapper departmentMapper;

    @Resource
    private StaffMapper staffMapper;

    /** 资产二维码扫码链接的前端基地址（必须是扫码设备能访问到的地址，如外网映射地址） */
    @Value("${front-base-url:}")
    private String frontBaseUrl;

    /**
     * 新增
     */
    @PostMapping("/add")
    public Result add(@RequestBody Assets assets) {
        assetsService.add(assets);
        return Result.success();
    }

    /**
     * 删除
     */
    @DeleteMapping("/delete/{id}")
    public Result deleteById(@PathVariable Integer id) {
        assetsService.deleteById(id);
        return Result.success();
    }

    /**
     * 批量删除
     */
    @DeleteMapping("/delete/batch")
    public Result deleteBatch(@RequestBody List<Integer> ids) {
        assetsService.deleteBatch(ids);
        return Result.success();
    }

    /**
     * 修改
     */
    @PutMapping("/update")
    public Result updateById(@RequestBody Assets assets) {
        assetsService.updateById(assets);
        return Result.success();
    }

    /**
     * 根据ID查询
     */
    @GetMapping("/selectById/{id}")
    public Result selectById(@PathVariable Integer id) {
        Assets assets = assetsService.selectById(id);
        return Result.success(assets);
    }

    /**
     * 查询所有
     */
    @GetMapping("/selectAll")
    public Result selectAll(Assets assets) {
        List<Assets> list = assetsService.selectAll(assets);
        return Result.success(list);
    }

    /**
     * 分页查询
     */
    @GetMapping("/selectPage")
    public Result selectPage(Assets assets,
                             @RequestParam(defaultValue = "1") Integer pageNum,
                             @RequestParam(defaultValue = "10") Integer pageSize) {
        PageInfo<Assets> page = assetsService.selectPage(assets, pageNum, pageSize);
        return Result.success(page);
    }

    /**
     * 批量导出数据（支持按当前筛选条件导出）
     */
    @GetMapping("/export")
    public void exportData(Assets assets, HttpServletResponse response) throws IOException {
        List<Assets> list = assetsService.selectAll(assets);
        // 显式以中文列名作为 Map 键：Assets 字段带 @Alias 注解，若用 addHeaderAlias+setOnlyAlias，
        // hutool 转 Map 时键名会被注解改写成中文，与别名表的字段名键不匹配，导致所有列被丢弃
        // 列名取「基础资料 → 自定义字段」配置，系统字段改名后导出同步生效
        List<AssetFieldConfig> fields = assetFieldConfigService.publicFields();
        List<Map<String, Object>> rows = new ArrayList<>();
        for (Assets a : list) {
            Map<String, Object> row = new LinkedHashMap<>();
            for (AssetFieldConfig field : fields) {
                if (Integer.valueOf(1).equals(field.getIsSystem())
                        && !EXPORT_KEYS.contains(field.getFieldKey())) {
                    continue;
                }
                row.put(field.getLabel(), fieldValue(a, field.getFieldKey()));
            }
            row.put("二维码链接", scanUrl(a));
            rows.add(row);
        }

        ExcelWriter writer = ExcelUtil.getWriter(true);
        writer.write(rows, true);

        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8");
        response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode("资产信息表", "UTF-8") + ".xlsx");
        ServletOutputStream outputStream = response.getOutputStream();
        writer.flush(outputStream, true);
        outputStream.flush();
        writer.close();
        outputStream.close();
    }

    /**
     * 批量下载二维码（zip 包）
     */
    @GetMapping("/qrcode/batch")
    public void batchQrcode(@RequestParam List<Integer> ids, HttpServletResponse response) throws Exception {
        response.setContentType("application/zip");
        response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode("资产二维码", "UTF-8") + ".zip");
        ZipOutputStream zos = new ZipOutputStream(response.getOutputStream());
        try {
            for (Integer id : ids) {
                Assets assets = assetsService.selectById(id);
                if (assets == null) continue;
                String text = scanUrl(assets);
                byte[] png = generateQrPng(text, 300);
                String name = (assets.getNo() != null && !assets.getNo().isEmpty() ? assets.getNo() : assets.getName());
                name = name.replaceAll("[\\\\/:*?\"<>|]", "-") + ".png";
                ZipEntry entry = new ZipEntry(name);
                zos.putNextEntry(entry);
                zos.write(png);
                zos.closeEntry();
            }
        } finally {
            zos.close();
        }
    }

    /**
     * 资产扫码页地址：/scan/{资产编号} 是前端路由，须用扫码设备可达的前端地址（front-base-url）
     * 无资产编号时回退为 ID（兼容历史数据）
     */
    private String scanUrl(Assets assets) {
        String code = assets.getNo();
        if (code == null || code.trim().isEmpty()) {
            code = String.valueOf(assets.getId());
        }
        try {
            code = URLEncoder.encode(code, "UTF-8").replace("+", "%20");
        } catch (Exception ignored) {
            // 编码失败时按原值拼接
        }
        return frontBaseUrl + "/scan/" + code;
    }

    private byte[] generateQrPng(String text, int size) throws Exception {
        Map<EncodeHintType, Object> hints = new LinkedHashMap<>();
        hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");
        hints.put(EncodeHintType.MARGIN, 1);
        BitMatrix matrix = new QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, size, size, hints);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        MatrixToImageWriter.writeToStream(matrix, "PNG", baos);
        return baos.toByteArray();
    }

    /**
     * 下载导入模板
     */
    @GetMapping("/template")
    public void downloadTemplate(HttpServletResponse response) throws IOException {
        ExcelWriter writer = ExcelUtil.getWriter(true);

        // 模板列名取字段配置：系统字段改名、启用自定义字段后同步生效
        Map<String, Object> sample = new LinkedHashMap<>();
        for (AssetFieldConfig field : assetFieldConfigService.publicFields()) {
            if (Integer.valueOf(1).equals(field.getIsSystem())
                    && !IMPORT_KEYS.contains(field.getFieldKey())) {
                continue;
            }
            sample.put(field.getLabel(), sampleValue(field));
        }
        writer.write(java.util.Collections.singletonList(sample), true);

        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8");
        response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode("资产导入模板", "UTF-8") + ".xlsx");
        ServletOutputStream outputStream = response.getOutputStream();
        writer.flush(outputStream, true);
        outputStream.flush();
        writer.close();
        outputStream.close();
    }

    /**
     * 批量导入数据（公司/部门/使用人按名称匹配，逐行校验，部分成功）
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
            for (AssetFieldConfig field : assetFieldConfigService.publicFields()) {
                if (Integer.valueOf(1).equals(field.getIsSystem())
                        && !IMPORT_KEYS.contains(field.getFieldKey())) {
                    continue;
                }
                labelToKey.put(field.getLabel().trim(), field.getFieldKey());
            }

            List<Department> departments = departmentMapper.selectAll(new Department());
            Map<Integer, Department> deptById = new HashMap<>();
            for (Department d : departments) {
                deptById.put(d.getId(), d);
            }
            List<Staff> staffs = staffMapper.selectAll(new Staff());

            int success = 0;
            List<Map<String, Object>> errors = new ArrayList<>();
            int rowNo = 1; // 第一行为表头
            for (Map<String, Object> row : rows) {
                rowNo++;
                Assets assets = new Assets();
                Map<String, String> texts = new LinkedHashMap<>();
                for (Map.Entry<String, Object> entry : row.entrySet()) {
                    String key = labelToKey.get(String.valueOf(entry.getKey()).trim());
                    if (key == null) {
                        continue;
                    }
                    texts.put(key, entry.getValue() == null ? "" : String.valueOf(entry.getValue()).trim());
                    if (!ORG_KEYS.contains(key)) {
                        setFieldValue(assets, key, entry.getValue());
                    }
                }
                if (StrUtil.isBlank(assets.getName())) {
                    continue; // 空行或未填写资产名称的行跳过
                }
                try {
                    applyOrganization(assets, texts, departments, deptById, staffs);
                    if (assets.getStatus() == null) {
                        assets.setStatus("正常");
                    }
                    if (assets.getNum() == null) {
                        assets.setNum(1);
                    }
                    assetsService.add(assets);
                    success++;
                } catch (CustomException e) {
                    errors.add(rowError(rowNo, e.getMsg()));
                } catch (Exception e) {
                    errors.add(rowError(rowNo, "导入失败：" + e.getMessage()));
                }
            }

            Map<String, Object> data = new LinkedHashMap<>();
            data.put("success", success);
            data.put("failed", errors.size());
            data.put("errors", errors);
            if (success == 0) {
                if (errors.isEmpty()) {
                    return Result.error("500", "文件中没有可导入的数据，请确认资产名称列已填写");
                }
                Result result = Result.error("500", "导入失败：共 " + errors.size() + " 行数据有误，请查看失败明细");
                result.setData(data);
                return result;
            }
            Result result = Result.success(data);
            result.setMsg(errors.isEmpty()
                    ? "成功导入 " + success + " 条数据"
                    : "成功导入 " + success + " 条数据，失败 " + errors.size() + " 条");
            return result;
        } catch (Exception e) {
            return Result.error("500", "导入失败：" + e.getMessage());
        }
    }

    /**
     * 解析所属公司 / 使用部门 / 使用人，转换为部门ID、使用人ID
     */
    private void applyOrganization(Assets assets, Map<String, String> texts, List<Department> departments,
                                   Map<Integer, Department> deptById, List<Staff> staffs) {
        String companyName = text(texts.get("companyName"));
        String deptName = text(texts.get("departmentName"));
        String staffName = text(texts.get("staffName"));

        Company company = null;
        if (!companyName.isEmpty()) {
            company = companyMapper.selectByName(companyName);
            if (company == null) {
                throw new CustomException("500", "所属公司不存在：" + companyName);
            }
        }

        Department dept = null;
        if (!deptName.isEmpty()) {
            dept = findDepartment(departments, deptName, company == null ? null : company.getId());
            if (dept == null) {
                throw new CustomException("500", company == null
                        ? "使用部门不存在：" + deptName
                        : "公司「" + companyName + "」下不存在部门：" + deptName);
            }
        }

        Staff staff = null;
        if (!staffName.isEmpty()) {
            staff = findStaff(staffs, staffName, dept, company == null ? null : company.getId(), deptById);
            if (staff == null) {
                if (dept != null) {
                    throw new CustomException("500", "使用人「" + staffName + "」不存在、已离职或不属于部门「" + dept.getName() + "」");
                }
                if (company != null) {
                    throw new CustomException("500", "使用人「" + staffName + "」不存在、已离职或不属于公司「" + companyName + "」");
                }
                throw new CustomException("500", "使用人不存在、已离职或有重名：" + staffName);
            }
            if (dept == null) {
                dept = deptById.get(staff.getDepartmentId());
                if (dept == null) {
                    throw new CustomException("500", "使用人「" + staffName + "」未分配部门，请填写使用部门");
                }
                if (company != null && !company.getId().equals(dept.getCompanyId())) {
                    throw new CustomException("500", "使用人「" + staffName + "」不属于公司「" + companyName + "」");
                }
            }
        }

        if (dept == null && company != null) {
            throw new CustomException("500", "填写了所属公司，请同时填写使用部门（公司随部门确定）");
        }

        assets.setDepartmentId(dept == null ? null : dept.getId());
        assets.setStaffId(staff == null ? null : staff.getId());
    }

    private Department findDepartment(List<Department> departments, String input, Integer companyId) {
        List<Department> matches = new ArrayList<>();
        for (Department d : departments) {
            if (companyId != null && !companyId.equals(d.getCompanyId())) {
                continue;
            }
            if (input.equals(d.getName()) || (d.getLabel() != null && input.equals(d.getLabel()))) {
                matches.add(d);
            }
        }
        if (matches.size() > 1) {
            throw new CustomException("500", "部门「" + input + "」匹配到多个，请填写「公司-部门」格式或同时填写所属公司");
        }
        return matches.isEmpty() ? null : matches.get(0);
    }

    private Staff findStaff(List<Staff> staffs, String name, Department dept, Integer companyId,
                            Map<Integer, Department> deptById) {
        List<Staff> matches = new ArrayList<>();
        for (Staff s : staffs) {
            if (!"在职".equals(s.getStatus()) || !name.equals(s.getName())) {
                continue;
            }
            if (dept != null && !dept.getId().equals(s.getDepartmentId())) {
                continue;
            }
            if (dept == null && companyId != null) {
                Department sd = deptById.get(s.getDepartmentId());
                if (sd == null || !companyId.equals(sd.getCompanyId())) {
                    continue;
                }
            }
            matches.add(s);
        }
        if (matches.size() > 1) {
            throw new CustomException("500", "使用人「" + name + "」存在重名，请同时填写使用部门或所属公司区分");
        }
        return matches.isEmpty() ? null : matches.get(0);
    }

    private String text(String value) {
        return value == null ? "" : value.trim();
    }

    private Map<String, Object> rowError(int row, String msg) {
        Map<String, Object> error = new LinkedHashMap<>();
        error.put("row", row);
        error.put("msg", msg);
        return error;
    }

    /**
     * 取资产字段值（导出用）
     */
    private Object fieldValue(Assets assets, String key) {
        switch (key) {
            case "no": return assets.getNo();
            case "name": return assets.getName();
            case "category": return assets.getCategory();
            case "img": return assets.getImg();
            case "model": return assets.getModel();
            case "num": return assets.getNum();
            case "date": return assets.getDate();
            case "money": return assets.getMoney();
            case "depreciate": return assets.getDepreciate();
            case "companyName": return assets.getCompanyName();
            case "departmentName": return assets.getDepartmentName();
            case "staffName": return assets.getStaffName();
            case "location": return assets.getLocation();
            case "status": return assets.getStatus();
            case "comment": return assets.getComment();
            case "custom1": return assets.getCustom1();
            case "custom2": return assets.getCustom2();
            case "custom3": return assets.getCustom3();
            case "custom4": return assets.getCustom4();
            case "custom5": return assets.getCustom5();
            case "custom6": return assets.getCustom6();
            case "custom7": return assets.getCustom7();
            case "custom8": return assets.getCustom8();
            case "custom9": return assets.getCustom9();
            case "custom10": return assets.getCustom10();
            default: return null;
        }
    }

    /**
     * 导入模板示例值
     */
    private Object sampleValue(AssetFieldConfig field) {
        if (!Integer.valueOf(1).equals(field.getIsSystem())) {
            String type = StrUtil.blankToDefault(field.getFieldType(), "text");
            if ("number".equals(type)) {
                return 1;
            }
            if ("date".equals(type)) {
                return "2024-01-01";
            }
            if ("select".equals(type)) {
                String options = StrUtil.blankToDefault(field.getOptions(), "");
                return options.trim().isEmpty() ? "" : options.split(",")[0].trim();
            }
            return "示例";
        }
        switch (field.getFieldKey()) {
            case "no": return "ZC001";
            case "name": return "示例资产";
            case "category": return "办公设备";
            case "model": return "型号示例";
            case "num": return 1;
            case "date": return "2024-01-01";
            case "money": return new java.math.BigDecimal("1000.00");
            case "depreciate": return "直线法";
            case "companyName": return "示例公司";
            case "departmentName": return "示例部门";
            case "staffName": return "张三";
            case "location": return "办公室";
            case "status": return "正常";
            case "comment": return "备注示例";
            default: return "";
        }
    }

    /**
     * 导入赋值（按字段标识）
     */
    private void setFieldValue(Assets assets, String key, Object value) {
        if (value == null) {
            return;
        }
        String text = String.valueOf(value).trim();
        if (text.isEmpty()) {
            return;
        }
        switch (key) {
            case "no": assets.setNo(text); break;
            case "name": assets.setName(text); break;
            case "category": assets.setCategory(text); break;
            case "model": assets.setModel(text); break;
            case "num":
                try { assets.setNum((int) Double.parseDouble(text)); } catch (NumberFormatException ignored) { }
                break;
            case "date": assets.setDate(text); break;
            case "money":
                try { assets.setMoney(new java.math.BigDecimal(text)); } catch (NumberFormatException ignored) { }
                break;
            case "depreciate": assets.setDepreciate(text); break;
            case "location": assets.setLocation(text); break;
            case "status": assets.setStatus(text); break;
            case "comment": assets.setComment(text); break;
            case "custom1": assets.setCustom1(text); break;
            case "custom2": assets.setCustom2(text); break;
            case "custom3": assets.setCustom3(text); break;
            case "custom4": assets.setCustom4(text); break;
            case "custom5": assets.setCustom5(text); break;
            case "custom6": assets.setCustom6(text); break;
            case "custom7": assets.setCustom7(text); break;
            case "custom8": assets.setCustom8(text); break;
            case "custom9": assets.setCustom9(text); break;
            case "custom10": assets.setCustom10(text); break;
            default: break;
        }
    }



}