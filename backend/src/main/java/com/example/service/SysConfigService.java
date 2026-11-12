package com.example.service;

import cn.hutool.core.date.DateUtil;
import cn.hutool.core.util.StrUtil;
import com.example.entity.SysConfig;
import com.example.exception.CustomException;
import com.example.mapper.SysConfigMapper;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 页面/站点配置业务处理
 */
@Service
public class SysConfigService {

    /** 允许配置的键（防止写入无关键值） */
    private static final List<String> ALLOWED_KEYS = Arrays.asList(
            "system_name", "browser_title", "login_subtitle",
            "login_bg", "logo", "footer_text", "dashboard_welcome", "scan_fields",
            "scan_title", "scan_footer", "scan_borrow_text", "scan_repair_text");

    /** 内置默认值（留空时使用） */
    public static final String DEFAULT_SYSTEM_NAME = "固定资产管理系统";
    public static final String DEFAULT_LOGIN_SUBTITLE = "欢迎使用";
    public static final String DEFAULT_WELCOME = "欢迎使用固定资产管理系统";
    /** 扫码页默认显示字段（与改造前保持一致：不含 数量/折旧方法） */
    public static final String DEFAULT_SCAN_FIELDS =
            "no,category,company,model,status,date,money,departmentName,staffName,location,comment,img";
    /** 扫码页固定文字默认值 */
    public static final String DEFAULT_SCAN_TITLE = "资产信息";
    public static final String DEFAULT_SCAN_FOOTER = "固定资产管理系统";
    public static final String DEFAULT_SCAN_BORROW_TEXT = "申请借用";
    public static final String DEFAULT_SCAN_REPAIR_TEXT = "申请报修";

    @Resource
    private SysConfigMapper sysConfigMapper;

    /**
     * 全部配置（后台「页面设置」页用）
     */
    public List<SysConfig> listAll() {
        return sysConfigMapper.selectAll();
    }

    /**
     * 前台公开配置（登录页 / 布局页用，无需登录即可读取）
     * 返回驼峰键，并把留空的项补成内置默认值
     */
    public Map<String, Object> publicConfig() {
        Map<String, String> raw = new LinkedHashMap<>();
        for (SysConfig c : sysConfigMapper.selectAll()) {
            raw.put(c.getConfigKey(), c.getConfigValue());
        }
        String systemName = StrUtil.blankToDefault(raw.get("system_name"), DEFAULT_SYSTEM_NAME);
        String browserTitle = StrUtil.blankToDefault(raw.get("browser_title"), systemName);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("systemName", systemName);
        result.put("browserTitle", browserTitle);
        result.put("loginSubtitle", StrUtil.blankToDefault(raw.get("login_subtitle"), DEFAULT_LOGIN_SUBTITLE));
        result.put("loginBg", StrUtil.blankToDefault(raw.get("login_bg"), ""));
        result.put("logo", StrUtil.blankToDefault(raw.get("logo"), ""));
        result.put("footerText", StrUtil.blankToDefault(raw.get("footer_text"), ""));
        result.put("dashboardWelcome", StrUtil.blankToDefault(raw.get("dashboard_welcome"), DEFAULT_WELCOME));

        // 扫码页显示字段：逗号分隔字符串 → 列表
        // 注意：只有「配置项不存在」时才用内置默认；用户主动全部取消勾选（空字符串）应保持为空
        String scanFieldsRaw = raw.get("scan_fields");
        if (scanFieldsRaw == null) {
            scanFieldsRaw = DEFAULT_SCAN_FIELDS;
        }
        List<String> scanFields = new ArrayList<>();
        if (StrUtil.isNotBlank(scanFieldsRaw)) {
            for (String key : scanFieldsRaw.split(",")) {
                if (StrUtil.isNotBlank(key)) {
                    scanFields.add(key.trim());
                }
            }
        }
        result.put("scanFields", scanFields);

        // 扫码页固定文字（留空用内置默认）
        result.put("scanTitle", StrUtil.blankToDefault(raw.get("scan_title"), DEFAULT_SCAN_TITLE));
        result.put("scanFooter", StrUtil.blankToDefault(raw.get("scan_footer"), DEFAULT_SCAN_FOOTER));
        result.put("scanBorrowText", StrUtil.blankToDefault(raw.get("scan_borrow_text"), DEFAULT_SCAN_BORROW_TEXT));
        result.put("scanRepairText", StrUtil.blankToDefault(raw.get("scan_repair_text"), DEFAULT_SCAN_REPAIR_TEXT));
        return result;
    }

    /**
     * 批量保存配置
     */
    public void saveBatch(List<SysConfig> configs) {
        if (configs == null || configs.isEmpty()) {
            return;
        }
        for (SysConfig config : configs) {
            if (StrUtil.isBlank(config.getConfigKey())) {
                continue;
            }
            if (!ALLOWED_KEYS.contains(config.getConfigKey())) {
                throw new CustomException("500", "不支持的配置项：" + config.getConfigKey());
            }
            config.setConfigValue(config.getConfigValue() == null ? "" : config.getConfigValue().trim());
            config.setUpdateTime(DateUtil.now());
            sysConfigMapper.save(config);
        }
    }
}
