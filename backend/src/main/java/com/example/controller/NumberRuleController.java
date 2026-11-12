package com.example.controller;

import com.example.common.Result;
import com.example.entity.NumberRule;
import com.example.exception.CustomException;
import com.example.service.NumberRuleService;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;

/**
 * 资产编码规则接口
 */
@RestController
@RequestMapping("/numberRule")
public class NumberRuleController {

    @Resource
    private NumberRuleService numberRuleService;

    /**
     * 获取规则配置
     */
    @GetMapping("/config")
    public Result getConfig() {
        return Result.success(numberRuleService.findConfig());
    }

    /**
     * 保存规则配置
     */
    @PostMapping("/config")
    public Result saveConfig(@RequestBody NumberRule rule) {
        numberRuleService.saveConfig(rule);
        return Result.success();
    }

    /**
     * 预览编码效果
     */
    @GetMapping("/preview")
    public Result preview(@RequestParam String pattern,
                          @RequestParam(required = false) String category) {
        try {
            return Result.success(numberRuleService.preview(pattern, category));
        } catch (CustomException e) {
            return Result.error(e.getCode(), e.getMsg());
        }
    }

    /**
     * 生成下一个编号（供新增资产时手动调用）
     */
    @GetMapping("/next")
    public Result next(@RequestParam String category) {
        try {
            return Result.success(numberRuleService.generate(category));
        } catch (CustomException e) {
            return Result.error(e.getCode(), e.getMsg());
        }
    }
}
