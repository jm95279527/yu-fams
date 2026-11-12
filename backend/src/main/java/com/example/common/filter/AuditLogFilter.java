package com.example.common.filter;

import com.auth0.jwt.JWT;
import com.example.common.Constants;
import com.example.entity.Account;
import com.example.entity.AuditLog;
import com.example.service.AuditLogService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingRequestWrapper;
import org.springframework.web.util.ContentCachingResponseWrapper;

import javax.annotation.Resource;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 操作审计日志过滤器：
 * 记录所有非 GET 请求（写操作）与登录请求，含操作人/角色/IP/接口/脱敏参数/业务码/耗时。
 * 参数中的 password/token 等敏感字段一律脱敏为 ***，不落库。
 */
@Component
public class AuditLogFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(AuditLogFilter.class);

    /** JwtInterceptor 解析出的登录用户 request 属性名 */
    public static final String ATTR_AUDIT_USER = "auditUser";

    private static final Pattern CODE_PATTERN = Pattern.compile("\"code\"\\s*:\\s*\"?([A-Za-z0-9]+)\"?");
    private static final Pattern USERNAME_PATTERN = Pattern.compile("\"username\"\\s*:\\s*\"([^\"]{0,50})\"");
    private static final Pattern ROLE_PATTERN = Pattern.compile("\"role\"\\s*:\\s*\"([^\"]{0,20})\"");
    private static final Pattern SECRET_PATTERN =
            Pattern.compile("(\"(?:password|newPassword|oldPassword|oldpassword|token)\"\\s*:\\s*\")(?:[^\"]*)(\")", Pattern.CASE_INSENSITIVE);

    /** 静态资源等无需审计的前缀 */
    private static final String[] SKIP_PREFIXES = {
            "/files", "/qr", "/scan", "/apiConfig", "/css", "/js", "/img"
    };

    @Resource
    private AuditLogService auditLogService;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String uri = request.getRequestURI();
        if ("OPTIONS".equalsIgnoreCase(request.getMethod()) || "GET".equalsIgnoreCase(request.getMethod())) {
            return true;
        }
        for (String prefix : SKIP_PREFIXES) {
            if (uri.startsWith(prefix)) {
                return true;
            }
        }
        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        ContentCachingRequestWrapper wrappedRequest = new ContentCachingRequestWrapper(request);
        ContentCachingResponseWrapper wrappedResponse = new ContentCachingResponseWrapper(response);
        long start = System.currentTimeMillis();
        try {
            chain.doFilter(wrappedRequest, wrappedResponse);
        } finally {
            try {
                saveLog(wrappedRequest, wrappedResponse, System.currentTimeMillis() - start);
            } catch (Exception e) {
                log.warn("审计日志记录失败: {}", e.getMessage());
            }
            wrappedResponse.copyBodyToResponse();
        }
    }

    private void saveLog(ContentCachingRequestWrapper request, ContentCachingResponseWrapper response, long costMs) {
        String uri = request.getRequestURI();
        // 操作人：优先取拦截器解析出的登录用户；登录等匿名接口从请求体解析
        boolean isLogin = "/login".equals(uri);

        AuditLog al = new AuditLog();
        al.setMethod(request.getMethod());
        al.setUri(uri);
        al.setStatus(response.getStatus());
        al.setCostMs((int) Math.min(costMs, Integer.MAX_VALUE));
        al.setIp(resolveIp(request));

        // 操作人：优先取拦截器解析出的登录用户；登录等匿名接口从请求体解析
        String username = null;
        String role = null;
        Object auditUser = request.getAttribute(ATTR_AUDIT_USER);
        if (auditUser instanceof Account) {
            username = ((Account) auditUser).getUsername();
            role = ((Account) auditUser).getRole();
        }
        String body = readBody(request);
        if (username == null && isLogin) {
            username = firstGroup(USERNAME_PATTERN, body);
            role = firstGroup(ROLE_PATTERN, body);
        }
        if (username == null) {
            username = "unknown";
        }
        al.setUsername(username);
        al.setRole(role);

        // 请求参数脱敏后记录
        if (body.length() > 0) {
            String contentType = request.getContentType();
            if (contentType != null && contentType.contains("multipart")) {
                al.setParams("[multipart]");
            } else {
                al.setParams(truncate(maskSecrets(body), 2000));
            }
        }

        // 业务码（统一返回 Result JSON，HTTP 恒 200，业务码在 body）
        String respBody = readBody(response);
        if (respBody.length() > 0) {
            al.setResultCode(firstGroup(CODE_PATTERN, respBody));
        }

        auditLogService.add(al);
    }

    private String readBody(ContentCachingRequestWrapper request) {
        try {
            return new String(request.getContentAsByteArray(), StandardCharsets.UTF_8);
        } catch (Exception e) {
            return "";
        }
    }

    private String readBody(ContentCachingResponseWrapper response) {
        try {
            String contentType = response.getContentType();
            // 二进制导出（xlsx/图片等）不解析
            if (contentType != null && !contentType.contains("json")) {
                return "";
            }
            return new String(response.getContentAsByteArray(), StandardCharsets.UTF_8);
        } catch (Exception e) {
            return "";
        }
    }

    private String maskSecrets(String body) {
        return SECRET_PATTERN.matcher(body).replaceAll("$1***$2");
    }

    private String truncate(String s, int max) {
        return s.length() > max ? s.substring(0, max) : s;
    }

    private String firstGroup(Pattern pattern, String input) {
        if (input == null || input.isEmpty()) {
            return null;
        }
        Matcher m = pattern.matcher(input);
        return m.find() ? m.group(1) : null;
    }

    private String resolveIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip != null && !ip.isEmpty() && !"unknown".equalsIgnoreCase(ip)) {
            int idx = ip.indexOf(',');
            return idx > 0 ? ip.substring(0, idx).trim() : ip.trim();
        }
        ip = request.getHeader("X-Real-IP");
        if (ip != null && !ip.isEmpty() && !"unknown".equalsIgnoreCase(ip)) {
            return ip;
        }
        return request.getRemoteAddr();
    }
}
