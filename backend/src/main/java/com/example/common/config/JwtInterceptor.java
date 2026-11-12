package com.example.common.config;

import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.exceptions.TokenExpiredException;
import com.example.common.Constants;
import com.example.common.enums.ResultCodeEnum;
import com.example.common.enums.RoleEnum;
import com.example.entity.Account;
import com.example.entity.Admin;
import com.example.entity.Staff;
import com.example.exception.CustomException;
import com.example.service.AdminService;
import com.example.service.StaffService;
import com.example.service.SysRoleService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.annotation.Resource;
import javax.servlet.DispatcherType;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.List;

/**
 * jwt拦截器 - 优化版本（含接口级角色鉴权）
 */
@Component
public class JwtInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(JwtInterceptor.class);

    @Resource
    private AdminService adminService;

    @Resource
    private StaffService staffService;

    @Resource
    private SysRoleService sysRoleService;

    /** 任何登录管理员都可访问的接口前缀（与角色无关：首页/菜单/改密/个人信息/公告） */
    private static final String[] ADMIN_COMMON_PREFIXES = {
            "/dashboard",
            "/role/myMenus",
            "/updatePassword",
            "/notice",
            "/admin/selectById",
            "/admin/update"
    };

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        // 只对最初的 REQUEST 分发做鉴权：FORWARD / ERROR 等内部分发直接放行，
        // 否则容器转发到 /error 时会被再次拦截，把 404 变成 500
        if (request.getDispatcherType() != DispatcherType.REQUEST) {
            return true;
        }
        // 非 Controller 方法（静态资源处理器等）不做校验：
        // 未映射路径会落到静态资源处理器上，若在这里抛异常，全局异常处理无法把它转成 404，
        // 最终冒泡成 Tomcat 的 500 报错页；放行后由资源处理器正常返回 404
        if (!(handler instanceof HandlerMethod)) {
            return true;
        }

        // 1. 从header或参数中获取token
        String token = request.getHeader(Constants.TOKEN);
        if (StrUtil.isBlank(token)) {
            token = request.getParameter(Constants.TOKEN);
        }

        // 2. 验证token是否存在
        if (StrUtil.isBlank(token)) {
            log.warn("请求路径 {} 缺少Token", request.getRequestURI());
            throw new CustomException(ResultCodeEnum.TOKEN_INVALID_ERROR);
        }

        // 3. 解析token并获取用户信息
        Account account = null;
        String userId = null;
        String role = null;

        try {
            // 3.1 解码token
            String userRole = JWT.decode(token).getAudience().get(0);

            // 3.2 安全分割字符串
            if (!userRole.contains("-")) {
                throw new CustomException(ResultCodeEnum.TOKEN_CHECK_ERROR.getCode(), "Token格式错误");
            }

            String[] parts = userRole.split("-", 2);
            userId = parts[0];
            role = parts[1];

            // 3.3 根据角色查询用户
            if (RoleEnum.ADMIN.name().equals(role)) {
                account = adminService.selectById(Integer.valueOf(userId));
            } else if (RoleEnum.STAFF.name().equals(role)) {
                account = staffService.selectById(Integer.valueOf(userId));
            } else {
                throw new CustomException("403", "用户角色无效");
            }
        } catch (Exception e) {
            // 添加详细的错误日志
            log.error("Token解析失败: {} | Token: {}", e.getMessage(), token, e);
            throw new CustomException(ResultCodeEnum.TOKEN_CHECK_ERROR.getCode(), "Token解析失败: " + e.getMessage());
        }

        // 4. 验证用户是否存在
        if (ObjectUtil.isNull(account)) {
            log.warn("用户不存在: ID={}, Role={}", userId, role);
            throw new CustomException(ResultCodeEnum.USER_NOT_EXIST_ERROR);
        }

        // 4.1 离职员工账号立即停用（即使持有旧 token 也拒绝）
        if (RoleEnum.STAFF.name().equals(role) && "离职".equals(((Staff) account).getStatus())) {
            log.warn("离职员工访问被拒绝: ID={}, username={}", userId, account.getUsername());
            throw new CustomException("401", "该账号已离职停用");
        }

        // 4.2 挂载当前用户供审计日志过滤器使用（AuditLogFilter.ATTR_AUDIT_USER）
        request.setAttribute(com.example.common.filter.AuditLogFilter.ATTR_AUDIT_USER, account);

        // 5. 验证token有效性
        try {
            JWTVerifier jwtVerifier = JWT.require(Algorithm.HMAC256(account.getPassword())).build();
            jwtVerifier.verify(token);
        } catch (TokenExpiredException e) {
            log.warn("Token已过期: {}", token);
            throw new CustomException(ResultCodeEnum.TOKEN_EXPIRED_ERROR);
        } catch (JWTVerificationException e) {
            log.error("Token验证失败: {} | Account: {}", e.getMessage(), account.getUsername(), e);
            throw new CustomException(ResultCodeEnum.TOKEN_CHECK_ERROR.getCode(), "Token验证失败: " + e.getMessage());
        } catch (Exception e) {
            log.error("Token验证异常: {}", e.getMessage(), e);
            throw new CustomException(ResultCodeEnum.SYSTEM_ERROR.getCode(), "Token验证异常");
        }

        // 6. 接口级角色鉴权
        checkApiPermission(request, account);

        return true;
    }

    /**
     * 接口级权限校验：
     * - 员工(STAFF)：直接放行（员工端接口已在 service 层按本人范围过滤）
     * - 管理员(ADMIN)：
     *   - 超级管理员：放行全部
     *   - 普通管理员：请求路径须命中"管理员通用前缀"或其角色被授予菜单的 api 前缀，否则 403
     */
    private void checkApiPermission(HttpServletRequest request, Account account) {
        // CORS 预检放行
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return;
        }
        if (account == null) {
            throw new CustomException("403", "无权限访问");
        }
        // 员工走自身接口，不做菜单级 URL 限制
        if (RoleEnum.STAFF.name().equals(account.getRole())) {
            return;
        }
        if (!RoleEnum.ADMIN.name().equals(account.getRole())) {
            throw new CustomException("403", "无权限访问");
        }
        Admin admin = (Admin) account;
        String uri = request.getRequestURI();

        // 管理员通用接口（首页/菜单/改密/个人信息/公告）任何管理员均可访问
        for (String prefix : ADMIN_COMMON_PREFIXES) {
            if (matchPrefix(uri, prefix)) {
                return;
            }
        }

        List<String> prefixes = sysRoleService.getApiPrefixes(admin);
        // null 表示超级管理员，放行全部
        if (prefixes == null) {
            return;
        }
        // 普通管理员：必须命中被授予菜单的 api 前缀
        for (String prefix : prefixes) {
            if (matchPrefix(uri, prefix)) {
                return;
            }
        }
        log.warn("管理员 {} 无权限访问接口 {}", account.getUsername(), uri);
        throw new CustomException("403", "无权限访问该接口");
    }

    /**
     * 前缀匹配：uri 等于 prefix，或以 "prefix/" 开头
     * 避免 /assets 误匹配 /assetsScrap、/assetsIn 等
     */
    private boolean matchPrefix(String uri, String prefix) {
        return uri.equals(prefix) || uri.startsWith(prefix + "/");
    }
}