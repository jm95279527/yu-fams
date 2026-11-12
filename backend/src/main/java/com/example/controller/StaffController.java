package com.example.controller;

import cn.hutool.poi.excel.ExcelUtil;
import cn.hutool.poi.excel.ExcelWriter;
import com.example.common.Result;
import com.example.entity.Staff;
import com.example.service.StaffService;
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
 * 员工前端操作接口
 **/
@RestController
@RequestMapping("/staff")
public class StaffController {

    @Resource
    private StaffService staffService;

    /**
     * 新增
     */
    @PostMapping("/add")
    public Result add(@RequestBody Staff staff) {
        staffService.add(staff);
        return Result.success();
    }

    /**
     * 删除
     */
    @DeleteMapping("/delete/{id}")
    public Result deleteById(@PathVariable Integer id) {
        staffService.deleteById(id);
        return Result.success();
    }

    /**
     * 批量删除
     */
    @DeleteMapping("/delete/batch")
    public Result deleteBatch(@RequestBody List<Integer> ids) {
        staffService.deleteBatch(ids);
        return Result.success();
    }

    /**
     * 修改
     */
    @PutMapping("/update")
    public Result updateById(@RequestBody Staff staff) {
        staffService.updateById(staff);
        return Result.success();
    }

    /**
     * 重置密码为系统默认密码
     */
    @PutMapping("/resetPassword/{id}")
    public Result resetPassword(@PathVariable Integer id) {
        staffService.resetPassword(id);
        return Result.success();
    }

    /**
     * 一键离职（单个）
     */
    @PutMapping("/leave/{id}")
    public Result leave(@PathVariable Integer id) {
        staffService.leave(id);
        return Result.success();
    }

    /**
     * 一键离职（批量）
     */
    @PutMapping("/leave/batch")
    public Result leaveBatch(@RequestBody List<Integer> ids) {
        return Result.success(staffService.leaveBatch(ids));
    }

    /**
     * 根据ID查询
     */
    @GetMapping("/selectById/{id}")
    public Result selectById(@PathVariable Integer id) {
        Staff staff = staffService.selectById(id);
        if (staff != null) {
            staff.setPassword(null);
        }
        return Result.success(staff);
    }

    /**
     * 查询所有
     */
    @GetMapping("/selectAll")
    public Result selectAll(Staff staff) {
        List<Staff> list = staffService.selectAll(staff);
        list.forEach(s -> s.setPassword(null));
        return Result.success(list);
    }

    /**
     * 分页查询
     */
    @GetMapping("/selectPage")
    public Result selectPage(Staff staff,
                             @RequestParam(defaultValue = "1") Integer pageNum,
                             @RequestParam(defaultValue = "10") Integer pageSize) {
        PageInfo<Staff> page = staffService.selectPage(staff, pageNum, pageSize);
        page.getList().forEach(s -> s.setPassword(null));
        return Result.success(page);
    }

    /**
     * 下载员工导入模板
     */
    @GetMapping("/template")
    public void downloadTemplate(HttpServletResponse response) throws IOException {
        ExcelWriter writer = ExcelUtil.getWriter(true);
        Map<String, Object> row1 = new LinkedHashMap<>();
        row1.put("工号", "HM0001");
        row1.put("姓名", "张三");
        row1.put("账号", "zhangsan");
        row1.put("性别", "男");
        row1.put("电话", "13800000001");
        row1.put("邮箱", "zhangsan@example.com");
        row1.put("身份证号", "350100199001011234");
        row1.put("公司", "赫玛科技");
        row1.put("部门", "财务中心");
        row1.put("职位", "会计");
        row1.put("学历", "本科");
        row1.put("入职日期", "2026-01-05");
        row1.put("状态", "在职");
        row1.put("籍贯", "福建福州");
        row1.put("家庭住址", "福州市鼓楼区某某路1号");
        row1.put("紧急联系人", "李四");
        row1.put("紧急联系电话", "13900000002");
        row1.put("备注", "示例行，可删除");
        Map<String, Object> row2 = new LinkedHashMap<>();
        row2.put("工号", "HM0002");
        row2.put("姓名", "王五");
        row2.put("账号", "");
        row2.put("性别", "女");
        row2.put("电话", "13800000003");
        row2.put("公司", "堡格丽");
        row2.put("部门", "财务中心");
        row2.put("职位", "出纳");
        row2.put("入职日期", "2026-02-01");
        row2.put("状态", "");
        writer.write(Arrays.asList(row1, row2), true);

        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8");
        response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode("员工导入模板", "UTF-8") + ".xlsx");
        ServletOutputStream out = response.getOutputStream();
        writer.flush(out, true);
        out.flush();
        writer.close();
        out.close();
    }

    /**
     * 批量导入员工
     */
    @PostMapping("/import")
    public Result importData(@RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            return Result.error("500", "请选择要上传的文件");
        }
        List<Map<String, Object>> rows = ExcelUtil.getReader(file.getInputStream()).readAll();
        String msg = staffService.importStaff(rows);
        return Result.success(msg);
    }

    /**
     * 导出员工信息
     */
    @GetMapping("/export")
    public void exportData(Staff query, HttpServletResponse response) throws IOException {
        ExcelWriter writer = ExcelUtil.getWriter(true);
        writer.addHeaderAlias("empNo", "工号");
        writer.addHeaderAlias("username", "账号");
        writer.addHeaderAlias("name", "姓名");
        writer.addHeaderAlias("gender", "性别");
        writer.addHeaderAlias("phone", "电话");
        writer.addHeaderAlias("email", "邮箱");
        writer.addHeaderAlias("idCard", "身份证号");
        writer.addHeaderAlias("birthDate", "出生日期");
        writer.addHeaderAlias("departmentName", "部门");
        writer.addHeaderAlias("position", "职位");
        writer.addHeaderAlias("education", "学历");
        writer.addHeaderAlias("entryDate", "入职日期");
        writer.addHeaderAlias("status", "状态");
        writer.addHeaderAlias("leaveDate", "离职日期");
        writer.addHeaderAlias("nativePlace", "籍贯");
        writer.addHeaderAlias("address", "家庭住址");
        writer.addHeaderAlias("emergencyContact", "紧急联系人");
        writer.addHeaderAlias("emergencyPhone", "紧急联系电话");
        writer.addHeaderAlias("remark", "备注");

        List<Staff> list = staffService.selectAll(query);
        list.forEach(s -> s.setPassword(null));
        // 必须在 write 之前设置，否则全部实体字段（id/role 等）都会被导出
        writer.setOnlyAlias(true);
        writer.write(list, true);

        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8");
        response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode("员工信息表", "UTF-8") + ".xlsx");
        ServletOutputStream outputStream = response.getOutputStream();
        writer.flush(outputStream, true);
        outputStream.flush();
        writer.close();
        outputStream.close();
    }

}
