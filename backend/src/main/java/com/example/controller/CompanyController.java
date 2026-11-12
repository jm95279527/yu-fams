package com.example.controller;

import com.example.common.Result;
import com.example.entity.Company;
import com.example.service.CompanyService;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;

/**
 * 分子公司前端操作接口
 */
@RestController
@RequestMapping("/company")
public class CompanyController {

    @Resource
    private CompanyService companyService;

    /**
     * 查询所有
     */
    @GetMapping("/selectAll")
    public Result selectAll(Company company) {
        List<Company> list = companyService.selectAll(company);
        return Result.success(list);
    }

    /**
     * 根据ID查询
     */
    @GetMapping("/selectById/{id}")
    public Result selectById(@PathVariable Integer id) {
        return Result.success(companyService.selectById(id));
    }

    /**
     * 新增
     */
    @PostMapping("/add")
    public Result add(@RequestBody Company company) {
        companyService.add(company);
        return Result.success();
    }

    /**
     * 修改
     */
    @PutMapping("/update")
    public Result update(@RequestBody Company company) {
        companyService.updateById(company);
        return Result.success();
    }

    /**
     * 删除
     */
    @DeleteMapping("/delete/{id}")
    public Result delete(@PathVariable Integer id) {
        companyService.deleteById(id);
        return Result.success();
    }
}
