package com.example.service;

import cn.hutool.core.date.DateUtil;
import cn.hutool.core.util.StrUtil;
import com.example.entity.AssetFieldConfig;
import com.example.entity.SysConfig;
import com.example.exception.CustomException;
import com.example.mapper.AssetFieldConfigMapper;
import com.example.mapper.SysConfigMapper;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 资产字段配置业务处理：系统字段改名 + 自定义字段定义
 */
@Service
public class AssetFieldConfigService {

    /** 支持的自定义字段类型 */
    private static final List<String> TYPES = Arrays.asList("text", "number", "date", "select");

    @Resource
    private AssetFieldConfigMapper assetFieldConfigMapper;

    @Resource
    private SysConfigMapper sysConfigMapper;

    /**
     * 全部字段配置（后台「自定义字段」页用）
     */
    public List<AssetFieldConfig> selectAll() {
        return assetFieldConfigMapper.selectAll();
    }

    /**
     * 公开字段配置（已启用）
     */
    public List<AssetFieldConfig> publicFields() {
        List<AssetFieldConfig> result = new ArrayList<>();
        for (AssetFieldConfig config : selectAll()) {
            if (Integer.valueOf(1).equals(config.getEnabled())) {
                result.add(config);
            }
        }
        return result;
    }

    /**
     * 取字段显示名（找不到时用 fallback）
     */
    public String label(String fieldKey, String fallback) {
        if (StrUtil.isNotBlank(fieldKey)) {
            for (AssetFieldConfig config : assetFieldConfigMapper.selectAll()) {
                if (fieldKey.equals(config.getFieldKey()) && StrUtil.isNotBlank(config.getLabel())) {
                    return config.getLabel();
                }
            }
        }
        return StrUtil.blankToDefault(fallback, fieldKey);
    }

    /**
     * 全部字段的 标识 → 显示名
     */
    public Map<String, String> labelMap() {
        Map<String, String> map = new LinkedHashMap<>();
        for (AssetFieldConfig config : assetFieldConfigMapper.selectAll()) {
            map.put(config.getFieldKey(), StrUtil.blankToDefault(config.getLabel(), config.getFieldKey()));
        }
        return map;
    }

    /**
     * 批量保存：系统字段只允许改名/排序；自定义字段可配置类型、选项、启用状态
     */
    public void saveBatch(List<AssetFieldConfig> list) {
        if (list == null || list.isEmpty()) {
            return;
        }
        for (AssetFieldConfig input : list) {
            if (StrUtil.isBlank(input.getFieldKey())) {
                continue;
            }
            AssetFieldConfig old = assetFieldConfigMapper.selectByKey(input.getFieldKey());
            if (old == null) {
                continue;   // 只能修改预置字段，不允许凭空新增字段标识
            }
            String label = StrUtil.trim(input.getLabel());
            if (StrUtil.isBlank(label)) {
                throw new CustomException("500", "字段名称不能为空");
            }
            for (AssetFieldConfig other : assetFieldConfigMapper.selectAll()) {
                if (!old.getId().equals(other.getId()) && label.equals(StrUtil.trim(other.getLabel()))) {
                    throw new CustomException("500", "字段名称「" + label + "」已存在，请换一个名称");
                }
            }
            AssetFieldConfig update = new AssetFieldConfig();
            update.setId(old.getId());
            update.setLabel(label);
            update.setSortNum(input.getSortNum() == null ? old.getSortNum() : input.getSortNum());

            if (Integer.valueOf(1).equals(old.getIsSystem())) {
                // 系统字段：仅允许修改显示名称与排序
                assetFieldConfigMapper.updateById(update);
            } else {
                String type = StrUtil.blankToDefault(input.getFieldType(), "text");
                if (!TYPES.contains(type)) {
                    throw new CustomException("500", "不支持的字段类型：" + type);
                }
                if ("select".equals(type) && StrUtil.isBlank(input.getOptions())) {
                    throw new CustomException("500", "下拉字段「" + label + "」必须填写选项");
                }
                update.setFieldType(type);
                update.setOptions(input.getOptions() == null ? "" : input.getOptions().trim());
                update.setEnabled(input.getEnabled() == null ? 0 : input.getEnabled());
                assetFieldConfigMapper.updateById(update);
            }
        }
        syncScanFields();
    }

    /**
     * 自定义字段启用/停用时，同步维护扫码页显示字段（scan_fields）
     */
    private void syncScanFields() {
        String raw = null;
        for (SysConfig config : sysConfigMapper.selectAll()) {
            if ("scan_fields".equals(config.getConfigKey())) {
                raw = config.getConfigValue();
                break;
            }
        }
        if (StrUtil.isBlank(raw)) {
            return;   // 未初始化或用户主动全部取消勾选时，保持原样
        }
        List<String> keys = new ArrayList<>();
        for (String key : raw.split(",")) {
            if (StrUtil.isNotBlank(key)) {
                keys.add(key.trim());
            }
        }
        for (AssetFieldConfig config : assetFieldConfigMapper.selectAll()) {
            if (Integer.valueOf(1).equals(config.getIsSystem())) {
                continue;
            }
            boolean exists = keys.contains(config.getFieldKey());
            if (Integer.valueOf(1).equals(config.getEnabled())) {
                if (!exists) {
                    keys.add(config.getFieldKey());
                }
            } else if (exists) {
                keys.remove(config.getFieldKey());
            }
        }
        SysConfig save = new SysConfig();
        save.setConfigKey("scan_fields");
        save.setConfigValue(String.join(",", keys));
        save.setUpdateTime(DateUtil.now());
        sysConfigMapper.save(save);
    }
}
