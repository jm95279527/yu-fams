package com.example.controller;

import com.example.common.Result;
import com.example.entity.SysConfig;
import com.example.service.SysConfigService;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;
import java.util.Map;

/**
 * 页面/站点配置接口
 */
@RestController
@RequestMapping("/sysConfig")
public class SysConfigController {

    @Resource
    private SysConfigService sysConfigService;

    /**
     * 前台公开配置（登录页/布局页读取，无需登录）
     */
    @GetMapping("/public")
    public Result publicConfig() {
        Map<String, Object> map = sysConfigService.publicConfig();
        return Result.success(map);
    }

    /**
     * 全部配置（后台「页面设置」页用）
     */
    @GetMapping("/selectAll")
    public Result selectAll() {
        List<SysConfig> list = sysConfigService.listAll();
        return Result.success(list);
    }

    /**
     * 批量保存配置
     */
    @PutMapping("/save")
    public Result save(@RequestBody List<SysConfig> configs) {
        sysConfigService.saveBatch(configs);
        return Result.success();
    }
}
