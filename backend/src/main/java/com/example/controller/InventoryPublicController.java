package com.example.controller;

import com.example.common.Result;
import com.example.service.AssetsInventoryService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import java.util.Map;

/**
 * 手机扫码盘点公开接口（无需登录，凭盘点单二维码中的 accessCode 访问）
 * 只提供查询与盘点，完结/删除等管理操作仍只能在后台完成
 */
@RestController
@RequestMapping("/inventoryPublic")
public class InventoryPublicController {

    @Resource
    private AssetsInventoryService inventoryService;

    /**
     * 盘点任务概览
     */
    @GetMapping("/task/{accessCode}")
    public Result task(@PathVariable String accessCode) {
        return Result.success(inventoryService.publicTask(accessCode));
    }

    /**
     * 明细列表：?tab=已盘/未盘&keyword=编号或名称
     */
    @GetMapping("/items/{accessCode}")
    public Result items(@PathVariable String accessCode,
                        @RequestParam(required = false) String tab,
                        @RequestParam(required = false) String keyword) {
        return Result.success(inventoryService.publicItems(accessCode, tab, keyword));
    }

    /**
     * 扫码后查询资产：body {"code":"二维码内容/资产编号"}
     */
    @PostMapping("/lookup/{accessCode}")
    public Result lookup(@PathVariable String accessCode, @RequestBody Map<String, Object> body) {
        String code = body.get("code") == null ? null : body.get("code").toString();
        return Result.success(inventoryService.lookup(accessCode, code));
    }

    /**
     * 确认盘点：body {"code":"二维码内容/资产编号","comment":"备注"}
     */
    @PostMapping("/scan/{accessCode}")
    public Result scan(@PathVariable String accessCode, @RequestBody Map<String, Object> body) {
        String code = body.get("code") == null ? null : body.get("code").toString();
        String comment = body.get("comment") == null ? null : body.get("comment").toString();
        return Result.success(inventoryService.publicScan(accessCode, code, comment));
    }
}
