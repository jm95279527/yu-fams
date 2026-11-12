package com.example.entity;

/**
 * 资产字段配置：系统字段重命名 + 自定义字段（custom1..custom10）定义
 */
public class AssetFieldConfig {
    /** ID */
    private Integer id;
    /** 字段标识：系统字段=实体属性名，自定义字段=custom1..custom10 */
    private String fieldKey;
    /** 显示名称 */
    private String label;
    /** 字段类型：text/number/date/select */
    private String fieldType;
    /** 下拉选项（逗号分隔，仅 select 类型使用） */
    private String options;
    /** 是否启用：1启用 0停用 */
    private Integer enabled;
    /** 是否系统字段：1是 0否 */
    private Integer isSystem;
    /** 排序 */
    private Integer sortNum;
    /** 更新时间 */
    private String updateTime;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getFieldKey() {
        return fieldKey;
    }

    public void setFieldKey(String fieldKey) {
        this.fieldKey = fieldKey;
    }

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public String getFieldType() {
        return fieldType;
    }

    public void setFieldType(String fieldType) {
        this.fieldType = fieldType;
    }

    public String getOptions() {
        return options;
    }

    public void setOptions(String options) {
        this.options = options;
    }

    public Integer getEnabled() {
        return enabled;
    }

    public void setEnabled(Integer enabled) {
        this.enabled = enabled;
    }

    public Integer getIsSystem() {
        return isSystem;
    }

    public void setIsSystem(Integer isSystem) {
        this.isSystem = isSystem;
    }

    public Integer getSortNum() {
        return sortNum;
    }

    public void setSortNum(Integer sortNum) {
        this.sortNum = sortNum;
    }

    public String getUpdateTime() {
        return updateTime;
    }

    public void setUpdateTime(String updateTime) {
        this.updateTime = updateTime;
    }
}
