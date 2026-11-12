package com.example.controller;

import cn.hutool.poi.excel.ExcelUtil;
import cn.hutool.poi.excel.ExcelWriter;
import com.example.common.Result;
import com.example.entity.Department;
import com.example.service.DepartmentService;
import com.github.pagehelper.PageInfo;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 部门信息前端操作接口
 **/
@RestController
@RequestMapping("/department")
public class DepartmentController {

    @Resource
    private DepartmentService departmentService;

    /**
     * 新增
     */
    @PostMapping("/add")
    public Result add(@RequestBody Department department) {
        departmentService.add(department);
        return Result.success();
    }

    /**
     * 删除
     */
    @DeleteMapping("/delete/{id}")
    public Result deleteById(@PathVariable Integer id) {
        departmentService.deleteById(id);
        return Result.success();
    }

    /**
     * 批量删除
     */
    @DeleteMapping("/delete/batch")
    public Result deleteBatch(@RequestBody List<Integer> ids) {
        departmentService.deleteBatch(ids);
        return Result.success();
    }

    /**
     * 修改
     */
    @PutMapping("/update")
    public Result updateById(@RequestBody Department department) {
        departmentService.updateById(department);
        return Result.success();
    }

    /**
     * 根据ID查询
     */
    @GetMapping("/selectById/{id}")
    public Result selectById(@PathVariable Integer id) {
        Department department = departmentService.selectById(id);
        return Result.success(department);
    }

    /**
     * 查询所有
     */
    @GetMapping("/selectAll")
    public Result selectAll(Department department) {
        List<Department> list = departmentService.selectAll(department);
        return Result.success(list);
    }

    /**
     * 分页查询
     */
    @GetMapping("/selectPage")
    public Result selectPage(Department department,
                             @RequestParam(defaultValue = "1") Integer pageNum,
                             @RequestParam(defaultValue = "10") Integer pageSize) {
        PageInfo<Department> page = departmentService.selectPage(department, pageNum, pageSize);
        return Result.success(page);
    }

    /**
     * 查询树状表格数据
     */
    @GetMapping("/selectTree")
    public Result selectTree() {
        List<Department> tree = departmentService.selectTree();
        return Result.success(tree);
    }

    /**
     * 查询树状表格数据
     */
    @GetMapping("/selectParent")
    public Result selectParent() {
        List<Department> list = departmentService.selectParent();
        return Result.success(list);
    }

    /**
     * 下载部门导入模板
     */
    @GetMapping("/template")
    public void downloadTemplate(HttpServletResponse response) throws IOException {
        ExcelWriter writer = ExcelUtil.getWriter(true);
        Map<String, Object> row1 = new LinkedHashMap<>();
        row1.put("公司名称", "福建某某集团有限公司");
        row1.put("部门名称", "财务部");
        row1.put("上级部门", "");
        row1.put("地址", "福州市鼓楼区某某路1号");
        Map<String, Object> row2 = new LinkedHashMap<>();
        row2.put("公司名称", "福建某某集团有限公司");
        row2.put("部门名称", "会计科");
        row2.put("上级部门", "财务部");
        row2.put("地址", "");
        Map<String, Object> row3 = new LinkedHashMap<>();
        row3.put("公司名称", "厦门某某分公司");
        row3.put("部门名称", "生产部");
        row3.put("上级部门", "");
        row3.put("地址", "厦门市集美区某某路8号");
        writer.write(Arrays.asList(row1, row2, row3), true);

        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8");
        response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode("部门导入模板", "UTF-8") + ".xlsx");
        ServletOutputStream out = response.getOutputStream();
        writer.flush(out, true);
        out.flush();
        writer.close();
        out.close();
    }

    /**
     * 批量导入部门（公司不存在时自动创建，支持多级部门）
     */
    @PostMapping("/import")
    public Result importData(@RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            return Result.error("500", "请选择要上传的文件");
        }
        List<Map<String, Object>> rows = ExcelUtil.getReader(file.getInputStream()).readAll();
        String msg = departmentService.importDepartments(rows);
        return Result.success(msg);
    }
}