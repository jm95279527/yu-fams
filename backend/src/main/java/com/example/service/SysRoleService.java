package com.example.service;

import com.example.common.enums.RoleEnum;
import com.example.entity.Account;
import com.example.entity.Admin;
import com.example.entity.SysMenu;
import com.example.entity.SysRole;
import com.example.exception.CustomException;
import com.example.mapper.SysRoleMapper;
import com.example.utils.TokenUtils;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.List;

/**
 * 系统角色业务处理
 **/
@Service
public class SysRoleService {

    /** 超级管理员角色标识：代码层直接放行全部菜单 */
    public static final String SUPER_ADMIN = "SUPER_ADMIN";

    @Resource
    private SysRoleMapper sysRoleMapper;

    @Resource
    private SysMenuService sysMenuService;

    /**
     * 分页查询角色（附带管理员数量）
     */
    public PageInfo<SysRole> selectPage(SysRole role, Integer pageNum, Integer pageSize) {
        PageHelper.startPage(pageNum, pageSize);
        List<SysRole> list = sysRoleMapper.selectAll(role);
        for (SysRole r : list) {
            r.setAdminCount(sysRoleMapper.countAdminsByRoleId(r.getId()));
        }
        return PageInfo.of(list);
    }

    /**
     * 查询全部角色（下拉选择用）
     */
    public List<SysRole> selectAll(SysRole role) {
        List<SysRole> list = sysRoleMapper.selectAll(role);
        for (SysRole r : list) {
            r.setAdminCount(sysRoleMapper.countAdminsByRoleId(r.getId()));
        }
        return list;
    }

    /**
     * 根据ID查询（含 menuIds 回显）
     */
    public SysRole selectById(Integer id) {
        SysRole role = sysRoleMapper.selectById(id);
        if (role != null) {
            role.setMenuIds(sysRoleMapper.selectMenuIdsByRoleId(id));
            role.setAdminCount(sysRoleMapper.countAdminsByRoleId(id));
        }
        return role;
    }

    /**
     * 新增角色（仅超级管理员）
     */
    public void add(SysRole role) {
        requireSuperAdmin();
        validateRole(role);
        if (sysRoleMapper.selectByCode(role.getCode()) != null) {
            throw new CustomException("500", "角色标识已存在");
        }
        if (role.getSort() == null) {
            role.setSort(0);
        }
        sysRoleMapper.insert(role);
    }

    /**
     * 修改角色（仅超级管理员；超级管理员角色的 code 不可改）
     */
    public void updateById(SysRole role) {
        requireSuperAdmin();
        SysRole old = sysRoleMapper.selectById(role.getId());
        if (old == null) {
            throw new CustomException("500", "角色不存在");
        }
        validateRole(role);
        if (SUPER_ADMIN.equals(old.getCode()) && !SUPER_ADMIN.equals(role.getCode())) {
            throw new CustomException("500", "超级管理员角色标识不可修改");
        }
        sysRoleMapper.updateById(role);
    }

    /**
     * 删除角色（仅超级管理员；内置角色与已分配管理员的角色不可删）
     */
    public void deleteById(Integer id) {
        requireSuperAdmin();
        SysRole role = sysRoleMapper.selectById(id);
        if (role == null) {
            throw new CustomException("500", "角色不存在");
        }
        if (SUPER_ADMIN.equals(role.getCode())) {
            throw new CustomException("500", "内置超级管理员角色不可删除");
        }
        int count = sysRoleMapper.countAdminsByRoleId(id);
        if (count > 0) {
            throw new CustomException("500", "该角色下还有 " + count + " 个管理员，请先调整其角色后再删除");
        }
        sysRoleMapper.deleteRoleMenus(id);
        sysRoleMapper.deleteById(id);
    }

    /**
     * 分配菜单权限（仅超级管理员）
     */
    @Transactional
    public void assignMenus(Integer roleId, List<Integer> menuIds) {
        requireSuperAdmin();
        SysRole role = sysRoleMapper.selectById(roleId);
        if (role == null) {
            throw new CustomException("500", "角色不存在");
        }
        if (SUPER_ADMIN.equals(role.getCode())) {
            throw new CustomException("500", "超级管理员默认拥有全部菜单，无需单独分配");
        }
        sysRoleMapper.deleteRoleMenus(roleId);
        if (menuIds != null && !menuIds.isEmpty()) {
            sysRoleMapper.batchInsertRoleMenus(roleId, menuIds);
        }
    }

    /**
     * 当前登录管理员的菜单树（前端动态渲染侧边栏）
     */
    public List<SysMenu> myMenuTree() {
        Account currentUser = TokenUtils.getCurrentUser();
        if (!RoleEnum.ADMIN.name().equals(currentUser.getRole())) {
            // 员工使用前端固定菜单，不返回动态菜单
            return java.util.Collections.emptyList();
        }
        Admin admin = (Admin) currentUser;
        if (admin.getRoleId() == null) {
            return java.util.Collections.emptyList();
        }
        SysRole role = sysRoleMapper.selectById(admin.getRoleId());
        if (role == null) {
            return java.util.Collections.emptyList();
        }
        if (SUPER_ADMIN.equals(role.getCode())) {
            return sysMenuService.tree();
        }
        List<Integer> menuIds = sysRoleMapper.selectMenuIdsByRoleId(role.getId());
        return sysMenuService.treeByIds(menuIds);
    }

    /**
     * 获取指定管理员被授予的全部后端接口路径前缀（接口级鉴权用）
     * 返回 null 表示超级管理员放行全部；返回空列表表示无任何业务接口权限
     */
    public java.util.List<String> getApiPrefixes(Admin admin) {
        if (admin == null || admin.getRoleId() == null) {
            return new java.util.ArrayList<>();
        }
        SysRole role = sysRoleMapper.selectById(admin.getRoleId());
        if (role == null) {
            return new java.util.ArrayList<>();
        }
        if (SUPER_ADMIN.equals(role.getCode())) {
            return null; // 超级管理员：null 表示放行全部
        }
        java.util.List<Integer> menuIds = sysRoleMapper.selectMenuIdsByRoleId(role.getId());
        java.util.List<String> prefixes = new java.util.ArrayList<>();
        if (menuIds == null || menuIds.isEmpty()) {
            return prefixes;
        }
        for (SysMenu m : sysMenuService.selectAll()) {
            if (menuIds.contains(m.getId()) && m.getApi() != null && !m.getApi().trim().isEmpty()) {
                for (String p : m.getApi().split(",")) {
                    String t = p.trim();
                    if (!t.isEmpty()) {
                        prefixes.add(t);
                    }
                }
            }
        }
        return prefixes;
    }

    /**
     * 判断指定管理员是否拥有某菜单（按菜单ID）
     */
    public boolean hasMenu(Admin admin, Integer menuId) {
        if (admin == null || admin.getRoleId() == null || menuId == null) {
            return false;
        }
        SysRole role = sysRoleMapper.selectById(admin.getRoleId());
        if (role == null) {
            return false;
        }
        if (SUPER_ADMIN.equals(role.getCode())) {
            return true;
        }
        java.util.List<Integer> menuIds = sysRoleMapper.selectMenuIdsByRoleId(role.getId());
        return menuIds != null && menuIds.contains(menuId);
    }

    private void validateRole(SysRole role) {
        if (role.getName() == null || role.getName().trim().isEmpty()) {
            throw new CustomException("500", "角色名称不能为空");
        }
        if (role.getCode() == null || role.getCode().trim().isEmpty()) {
            throw new CustomException("500", "角色标识不能为空");
        }
        // 标识仅允许大写字母/数字/下划线
        if (!role.getCode().matches("[A-Z][A-Z0-9_]*")) {
            throw new CustomException("500", "角色标识须以大写字母开头，仅含大写字母、数字、下划线");
        }
    }

    /**
     * 校验当前登录人必须是超级管理员，否则禁止操作
     */
    private void requireSuperAdmin() {
        Account currentUser = TokenUtils.getCurrentUser();
        if (!RoleEnum.ADMIN.name().equals(currentUser.getRole())) {
            throw new CustomException("403", "无权限操作");
        }
        Admin admin = (Admin) currentUser;
        if (admin.getRoleId() == null) {
            throw new CustomException("403", "无权限操作");
        }
        SysRole role = sysRoleMapper.selectById(admin.getRoleId());
        if (role == null || !SUPER_ADMIN.equals(role.getCode())) {
            throw new CustomException("403", "仅超级管理员可进行角色权限操作");
        }
    }
}
