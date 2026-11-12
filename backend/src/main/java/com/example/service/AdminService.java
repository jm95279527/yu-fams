package com.example.service;

import cn.hutool.core.util.ObjectUtil;
import com.example.common.Constants;
import com.example.common.enums.ResultCodeEnum;
import com.example.common.enums.RoleEnum;
import com.example.common.utils.LoginGuard;
import com.example.entity.Account;
import com.example.entity.Admin;
import com.example.entity.SysRole;
import com.example.exception.CustomException;
import com.example.mapper.AdminMapper;
import com.example.mapper.SysRoleMapper;
import com.example.utils.TokenUtils;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * 管理员业务处理
 **/
@Service
public class AdminService {

    @Resource
    private AdminMapper adminMapper;

    @Resource
    private SysRoleMapper sysRoleMapper;

    @Resource
    private LoginGuard loginGuard;

    /**
     * 新增
     */
    public void add(Admin admin) {
        Admin dbAdmin = adminMapper.selectByUsername(admin.getUsername());
        if (ObjectUtil.isNotNull(dbAdmin)) {
            throw new CustomException(ResultCodeEnum.USER_EXIST_ERROR);
        }
        if (ObjectUtil.isEmpty(admin.getPassword())) {
            admin.setPassword(Constants.USER_DEFAULT_PASSWORD);
        }
        if (ObjectUtil.isEmpty(admin.getName())) {
            admin.setName(admin.getUsername());
        }
        admin.setRole(RoleEnum.ADMIN.name());
        // 仅超级管理员可为新管理员分配系统角色
        if (!isSuperAdmin()) {
            admin.setRoleId(null);
        } else if (admin.getRoleId() != null && sysRoleMapper.selectById(admin.getRoleId()) == null) {
            throw new CustomException("500", "所选角色不存在");
        }
        adminMapper.insert(admin);
    }

    /**
     * 删除
     */
    public void deleteById(Integer id) {
        adminMapper.deleteById(id);
    }

    /**
     * 批量删除
     */
    public void deleteBatch(List<Integer> ids) {
        for (Integer id : ids) {
            adminMapper.deleteById(id);
        }
    }

    /**
     * 修改
     * 非超级管理员且无"管理员信息"菜单权限的管理员，只能修改本人信息
     */
    public void updateById(Admin admin) {
        checkSelfOrAdminPerm(admin.getId());
        // 仅超级管理员可调整管理员的系统角色，其他人提交的 roleId 忽略
        if (!isSuperAdmin()) {
            admin.setRoleId(null);
        } else if (admin.getRoleId() != null && sysRoleMapper.selectById(admin.getRoleId()) == null) {
            throw new CustomException("500", "所选角色不存在");
        }
        adminMapper.updateById(admin);
    }

    /**
     * 校验：当前登录管理员是否可操作目标管理员记录
     * 超级管理员 或 拥有"管理员信息"菜单(id=42) 可操作任意管理员；
     * 其他管理员只能操作本人记录
     */
    public void checkSelfOrAdminPerm(Integer targetId) {
        Account currentUser = TokenUtils.getCurrentUser();
        if (!(currentUser instanceof Admin)) {
            return;
        }
        Admin me = (Admin) currentUser;
        // 本人直接放行
        if (me.getId() != null && me.getId().equals(targetId)) {
            return;
        }
        // 超级管理员放行
        if (isSuperAdmin()) {
            return;
        }
        // 拥有"管理员信息"菜单权限放行
        if (me.getRoleId() != null) {
            List<Integer> menuIds = sysRoleMapper.selectMenuIdsByRoleId(me.getRoleId());
            if (menuIds != null && menuIds.contains(42)) {
                return;
            }
        }
        throw new CustomException("403", "无权限操作其他管理员信息");
    }

    /**
     * 判断当前登录人是否为超级管理员（SUPER_ADMIN 角色）
     */
    private boolean isSuperAdmin() {
        try {
            Account currentUser = TokenUtils.getCurrentUser();
            if (currentUser instanceof Admin) {
                Admin me = (Admin) currentUser;
                if (me.getRoleId() == null) {
                    return false;
                }
                SysRole role = sysRoleMapper.selectById(me.getRoleId());
                return role != null && "SUPER_ADMIN".equals(role.getCode());
            }
        } catch (Exception ignored) {
        }
        return false;
    }

    /**
     * 根据ID查询（原始查询，供 TokenUtils 等内部调用；权限校验在 Controller 层做）
     */
    public Admin selectById(Integer id) {
        return adminMapper.selectById(id);
    }

    /**
     * 查询所有
     */
    public List<Admin> selectAll(Admin admin) {
        return adminMapper.selectAll(admin);
    }

    /**
     * 分页查询
     */
    public PageInfo<Admin> selectPage(Admin admin, Integer pageNum, Integer pageSize) {
        PageHelper.startPage(pageNum, pageSize);
        List<Admin> list = adminMapper.selectAll(admin);
        return PageInfo.of(list);
    }

    /**
     * 登录
     */
    public Account login(Account account) {
        String guardKey = RoleEnum.ADMIN.name() + ":" + account.getUsername();
        loginGuard.checkLocked(guardKey);
        Account dbAdmin = adminMapper.selectByUsername(account.getUsername());
        if (ObjectUtil.isNull(dbAdmin)) {
            loginGuard.onFailure(guardKey);
            throw new CustomException(ResultCodeEnum.USER_NOT_EXIST_ERROR);
        }
        if (!account.getPassword().equals(dbAdmin.getPassword())) {
            loginGuard.onFailure(guardKey);
            throw new CustomException(ResultCodeEnum.USER_ACCOUNT_ERROR);
        }
        loginGuard.onSuccess(guardKey);
        // 生成token
        String tokenData = dbAdmin.getId() + "-" + RoleEnum.ADMIN.name();
        String token = TokenUtils.createToken(tokenData, dbAdmin.getPassword());
        dbAdmin.setToken(token);
        return dbAdmin;
    }

    /**
     * 修改密码
     */
    public void updatePassword(Account account) {
        Admin dbAdmin = adminMapper.selectByUsername(account.getUsername());
        if (ObjectUtil.isNull(dbAdmin)) {
            throw new CustomException(ResultCodeEnum.USER_NOT_EXIST_ERROR);
        }
        if (!account.getPassword().equals(dbAdmin.getPassword())) {
            throw new CustomException(ResultCodeEnum.PARAM_PASSWORD_ERROR);
        }
        dbAdmin.setPassword(account.getNewPassword());
        adminMapper.updateById(dbAdmin);
    }

}