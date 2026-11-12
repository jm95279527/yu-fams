package com.example.controller;

import cn.hutool.poi.excel.ExcelUtil;
import cn.hutool.poi.excel.ExcelWriter;
import com.example.common.Result;
import com.example.entity.AssetsScrap;
import com.example.service.AssetFieldConfigService;
import com.example.service.AssetsScrapService;
import com.github.pagehelper.PageInfo;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 资产报废前端操作接口
 **/
@RestController
@RequestMapping("/assetsScrap")
public class AssetsScrapController {

    @Resource
    private AssetsScrapService assetsScrapService;

    @Resource
    private AssetFieldConfigService assetFieldConfigService;

    /**
     * 提交报废申请
     */
    @PostMapping("/add")
    public Result add(@RequestBody AssetsScrap assetsScrap) {
        assetsScrapService.add(assetsScrap);
        return Result.success();
    }

    /**
     * 删除
     */
    @DeleteMapping("/delete/{id}")
    public Result deleteById(@PathVariable Integer id) {
        assetsScrapService.deleteById(id);
        return Result.success();
    }

    /**
     * 批量删除
     */
    @DeleteMapping("/delete/batch")
    public Result deleteBatch(@RequestBody List<Integer> ids) {
        assetsScrapService.deleteBatch(ids);
        return Result.success();
    }

    /**
     * 修改（申请人编辑待审批单据）
     */
    @PutMapping("/update")
    public Result updateById(@RequestBody AssetsScrap assetsScrap) {
        assetsScrapService.updateById(assetsScrap);
        return Result.success();
    }

    /**
     * 根据ID查询
     */
    @GetMapping("/selectById/{id}")
    public Result selectById(@PathVariable Integer id) {
        return Result.success(assetsScrapService.selectById(id));
    }

    /**
     * 查询所有
     */
    @GetMapping("/selectAll")
    public Result selectAll(AssetsScrap assetsScrap) {
        List<AssetsScrap> list = assetsScrapService.selectAll(assetsScrap);
        return Result.success(list);
    }

    /**
     * 分页查询
     */
    @GetMapping("/selectPage")
    public Result selectPage(AssetsScrap assetsScrap,
                             @RequestParam(defaultValue = "1") Integer pageNum,
                             @RequestParam(defaultValue = "10") Integer pageSize) {
        PageInfo<AssetsScrap> page = assetsScrapService.selectPage(assetsScrap, pageNum, pageSize);
        return Result.success(page);
    }

    /**
     * 根据资产ID查询报废记录（历史追溯）
     */
    @GetMapping("/selectByAssetsId/{assetsId}")
    public Result selectByAssetsId(@PathVariable Integer assetsId) {
        return Result.success(assetsScrapService.selectByAssetsId(assetsId));
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
        assetsScrapService.audit(id, pass, comment);
        return Result.success();
    }

    /**
     * 导出报废记录
     */
    @GetMapping("/export")
    public void exportData(AssetsScrap query, HttpServletResponse response) throws IOException {
        List<AssetsScrap> list = assetsScrapService.selectAll(query);
        // 显式以中文列名作为 Map 键（快照资产信息+报废信息+审批信息）：AssetsScrap 字段带 @Alias 注解，
        // 用 addHeaderAlias+setOnlyAlias 会因键名被注解改写而丢弃全部列
        Map<String, String> labels = assetFieldConfigService.labelMap();
        List<Map<String, Object>> rows = new ArrayList<>();
        for (AssetsScrap s : list) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put(labels.getOrDefault("no", "资产编号"), s.getAssetsNo());
            row.put(labels.getOrDefault("name", "资产名称"), s.getAssetsName());
            row.put(labels.getOrDefault("category", "资产分类"), s.getCategory());
            row.put(labels.getOrDefault("model", "资产型号"), s.getModel());
            row.put(labels.getOrDefault("money", "初始价值"), s.getMoney());
            row.put(labels.getOrDefault("depreciate", "折旧方法"), s.getDepreciate());
            row.put(labels.getOrDefault("departmentName", "使用部门"), s.getDepartmentName());
            row.put(labels.getOrDefault("staffName", "责任人"), s.getStaffName());
            row.put(labels.getOrDefault("location", "存放地点"), s.getLocation());
            row.put("报废类型", s.getScrapType());
            row.put("报废原因", s.getReason());
            row.put("残值", s.getResidualValue());
            row.put("申请人", s.getApplicantName());
            row.put("申请时间", s.getApplyTime());
            row.put("状态", s.getStatus());
            row.put("审批人", s.getApproverName());
            row.put("审批时间", s.getApproveTime());
            row.put("审批意见", s.getApproveComment());
            row.put("备注", s.getComment());
            rows.add(row);
        }

        ExcelWriter writer = ExcelUtil.getWriter(true);
        writer.write(rows, true);

        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8");
        response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode("资产报废表", "UTF-8") + ".xlsx");
        ServletOutputStream outputStream = response.getOutputStream();
        writer.flush(outputStream, true);
        outputStream.flush();
        writer.close();
        outputStream.close();
    }
}
