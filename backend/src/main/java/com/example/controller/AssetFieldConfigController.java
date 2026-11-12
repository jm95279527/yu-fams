package com.example.controller;

import com.example.common.Result;
import com.example.entity.AssetFieldConfig;
import com.example.service.AssetFieldConfigService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import java.util.List;

/**
 * 资产字段配置接口
 */
@RestController
@RequestMapping("/assetField")
public class AssetFieldConfigController {

    @Resource
    private AssetFieldConfigService assetFieldConfigService;

    /**
     * 全部字段（后台「自定义字段」页）
     */
    @GetMapping("/selectAll")
    public Result selectAll() {
        return Result.success(assetFieldConfigService.selectAll());
    }

    /**
     * 已启用字段（全站字段名称/自定义字段展示用，公开接口）
     */
    @GetMapping("/public")
    public Result publicFields() {
        return Result.success(assetFieldConfigService.publicFields());
    }

    /**
     * 批量保存
     */
    @PutMapping("/save")
    public Result save(@RequestBody List<AssetFieldConfig> list) {
        assetFieldConfigService.saveBatch(list);
        return Result.success();
    }
}
