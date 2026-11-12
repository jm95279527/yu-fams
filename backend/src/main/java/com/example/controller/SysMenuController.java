package com.example.controller;

import com.example.common.Result;
import com.example.entity.SysMenu;
import com.example.service.SysMenuService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import java.util.List;

/**
 * 系统菜单前端操作接口
 **/
@RestController
@RequestMapping("/menu")
public class SysMenuController {

    @Resource
    private SysMenuService sysMenuService;

    /**
     * 全部菜单树（角色授权弹窗使用）
     */
    @GetMapping("/tree")
    public Result tree() {
        List<SysMenu> tree = sysMenuService.tree();
        return Result.success(tree);
    }

    /**
     * 全部菜单平铺列表
     */
    @GetMapping("/all")
    public Result all() {
        return Result.success(sysMenuService.selectAll());
    }
}
