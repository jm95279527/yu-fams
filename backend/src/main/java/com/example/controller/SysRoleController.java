package com.example.controller;

import com.example.common.Result;
import com.example.entity.SysMenu;
import com.example.entity.SysRole;
import com.example.service.SysRoleService;
import com.github.pagehelper.PageInfo;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;
import java.util.Map;

/**
 * 系统角色前端操作接口
 **/
@RestController
@RequestMapping("/role")
public class SysRoleController {

    @Resource
    private SysRoleService sysRoleService;

    /**
     * 新增角色
     */
    @PostMapping("/add")
    public Result add(@RequestBody SysRole role) {
        sysRoleService.add(role);
        return Result.success();
    }

    /**
     * 删除角色
     */
    @DeleteMapping("/delete/{id}")
    public Result deleteById(@PathVariable Integer id) {
        sysRoleService.deleteById(id);
        return Result.success();
    }

    /**
     * 修改角色
     */
    @PutMapping("/update")
    public Result updateById(@RequestBody SysRole role) {
        sysRoleService.updateById(role);
        return Result.success();
    }

    /**
     * 根据ID查询（含 menuIds）
     */
    @GetMapping("/selectById/{id}")
    public Result selectById(@PathVariable Integer id) {
        return Result.success(sysRoleService.selectById(id));
    }

    /**
     * 查询全部角色
     */
    @GetMapping("/selectAll")
    public Result selectAll(SysRole role) {
        return Result.success(sysRoleService.selectAll(role));
    }

    /**
     * 分页查询
     */
    @GetMapping("/selectPage")
    public Result selectPage(SysRole role,
                             @RequestParam(defaultValue = "1") Integer pageNum,
                             @RequestParam(defaultValue = "10") Integer pageSize) {
        PageInfo<SysRole> page = sysRoleService.selectPage(role, pageNum, pageSize);
        return Result.success(page);
    }

    /**
     * 分配菜单权限：body {"roleId":1,"menuIds":[1,10,11,...]}
     */
    @PostMapping("/assignMenus")
    public Result assignMenus(@RequestBody Map<String, Object> body) {
        Object roleIdObj = body.get("roleId");
        if (roleIdObj == null) {
            return Result.error("400", "缺少角色ID");
        }
        Integer roleId = Integer.valueOf(roleIdObj.toString());
        @SuppressWarnings("unchecked")
        List<Integer> menuIds = (List<Integer>) body.get("menuIds");
        sysRoleService.assignMenus(roleId, menuIds);
        return Result.success();
    }

    /**
     * 当前登录管理员拥有的菜单树（动态侧边栏）
     */
    @GetMapping("/myMenus")
    public Result myMenus() {
        List<SysMenu> tree = sysRoleService.myMenuTree();
        return Result.success(tree);
    }
}
