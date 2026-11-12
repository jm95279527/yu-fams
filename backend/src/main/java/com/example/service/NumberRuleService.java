package com.example.service;

import com.example.entity.Category;
import com.example.entity.NumberRule;
import com.example.exception.CustomException;
import com.example.mapper.AssetsMapper;
import com.example.mapper.CategoryMapper;
import com.example.mapper.NumberRuleMapper;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 资产编码规则服务：解析编码模式并生成唯一资产编号
 * 模式段：{CAT}分类编码 {YYYY}年 {YY}两位年 {MM}月 {SEQ:n}n位流水号，其余字符原样输出
 */
@Service
public class NumberRuleService {

    /** 模式段语法校验 */
    private static final Pattern SEGMENT_PATTERN = Pattern.compile("\\{(CAT|YYYY|YY|MM|SEQ(?::(\\d{1,2}))?)}");
    /** 流水号默认位数 */
    private static final int DEFAULT_SEQ_LEN = 4;
    /** 唯一性重试上限 */
    private static final int MAX_RETRY = 999;

    @Resource
    private NumberRuleMapper numberRuleMapper;
    @Resource
    private CategoryMapper categoryMapper;
    @Resource
    private AssetsMapper assetsMapper;

    /**
     * 查询规则（未配置时返回默认模板）
     */
    public NumberRule findConfig() {
        NumberRule rule = numberRuleMapper.selectOne();
        if (rule == null) {
            rule = new NumberRule();
            rule.setName("默认规则");
            rule.setPattern("{CAT}-{YYYY}-{SEQ:4}");
            rule.setEnabled(true);
        }
        return rule;
    }

    /**
     * 保存规则（单行）
     */
    public void saveConfig(NumberRule rule) {
        validatePattern(rule.getPattern());
        String now = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        NumberRule exist = numberRuleMapper.selectOne();
        if (exist == null) {
            rule.setCreateTime(now);
            rule.setUpdateTime(now);
            numberRuleMapper.insert(rule);
        } else {
            rule.setId(exist.getId());
            rule.setUpdateTime(now);
            numberRuleMapper.updateById(rule);
        }
    }

    /**
     * 校验模式合法性
     */
    public void validatePattern(String pattern) {
        if (pattern == null || pattern.trim().isEmpty()) {
            throw new CustomException("500", "编码模式不能为空");
        }
        if (!SEGMENT_PATTERN.matcher(pattern).find()) {
            throw new CustomException("500", "编码模式必须包含 {CAT}、{YYYY}、{SEQ:n} 中的至少一个有效段");
        }
        // 检查是否存在无法识别的花括号段，避免用户拼错
        Matcher unknown = Pattern.compile("\\{[^{}]*}").matcher(pattern);
        while (unknown.find()) {
            if (!SEGMENT_PATTERN.matcher(unknown.group()).matches()) {
                throw new CustomException("500", "编码模式包含无法识别的段：" + unknown.group());
            }
        }
    }

    /**
     * 生成下一个资产编号（流水号基于同前缀最大值 +1，并循环校验唯一性）
     *
     * @param categoryName 资产分类名称（用于取分类编码）
     */
    public String generate(String categoryName) {
        NumberRule rule = findConfig();
        if (!Boolean.TRUE.equals(rule.getEnabled())) {
            throw new CustomException("500", "编码规则未启用，请先在「基础资料-资产编码规则」中启用");
        }
        String prefix = renderPrefix(rule.getPattern(), categoryName);
        List<String> nos = assetsMapper.selectNoByPrefix(prefix);

        long max = 0;
        Pattern tail = Pattern.compile("^(\\d+)$");
        for (String no : nos) {
            if (no == null || !no.startsWith(prefix)) {
                continue;
            }
            Matcher m = tail.matcher(no.substring(prefix.length()));
            if (m.find()) {
                max = Math.max(max, Long.parseLong(m.group(1)));
            }
        }

        int seqLen = extractSeqLen(rule.getPattern());
        for (int i = 0; i < MAX_RETRY; i++) {
            String no = prefix + pad(max + 1 + i, seqLen);
            if (assetsMapper.countByNo(no) == 0) {
                return no;
            }
        }
        throw new CustomException("500", "生成编号失败：流水号已用尽，请调整编码模式");
    }

    /**
     * 预览编码效果（不落库）
     */
    public String preview(String pattern, String categoryName) {
        validatePattern(pattern);
        return renderPrefix(pattern, categoryName) + pad(1, extractSeqLen(pattern));
    }

    /**
     * 渲染前缀（除流水号外的所有段）
     */
    private String renderPrefix(String pattern, String categoryName) {
        String catCode = "CAT";
        if (categoryName != null && !categoryName.isEmpty()) {
            Category category = categoryMapper.selectByName(categoryName);
            if (category != null && category.getCode() != null && !category.getCode().isEmpty()) {
                catCode = category.getCode();
            }
        }
        LocalDateTime now = LocalDateTime.now();
        Matcher m = SEGMENT_PATTERN.matcher(pattern);
        StringBuilder sb = new StringBuilder();
        int last = 0;
        while (m.find()) {
            sb.append(pattern, last, m.start());
            switch (m.group(1)) {
                case "CAT":
                    sb.append(catCode);
                    break;
                case "YYYY":
                    sb.append(now.format(DateTimeFormatter.ofPattern("yyyy")));
                    break;
                case "YY":
                    sb.append(now.format(DateTimeFormatter.ofPattern("yy")));
                    break;
                case "MM":
                    sb.append(now.format(DateTimeFormatter.ofPattern("MM")));
                    break;
                default:
                    // SEQ 段属于流水号，前缀部分跳过
                    break;
            }
            last = m.end();
        }
        sb.append(pattern.substring(last));
        return sb.toString();
    }

    /**
     * 提取流水号位数（取第一个 SEQ 段的位数）
     */
    private int extractSeqLen(String pattern) {
        Matcher m = SEGMENT_PATTERN.matcher(pattern);
        while (m.find()) {
            if ("SEQ".equals(m.group(1))) {
                if (m.group(2) != null) {
                    return Integer.parseInt(m.group(2));
                }
                return DEFAULT_SEQ_LEN;
            }
        }
        return DEFAULT_SEQ_LEN;
    }

    private String pad(long num, int len) {
        String s = String.valueOf(num);
        if (s.length() >= len) {
            return s;
        }
        StringBuilder sb = new StringBuilder();
        for (int i = s.length(); i < len; i++) {
            sb.append('0');
        }
        return sb.append(s).toString();
    }
}
