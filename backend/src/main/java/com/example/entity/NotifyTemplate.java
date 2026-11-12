package com.example.entity;

/**
 * 通知模板（按 业务类型+事件 配置，可停用）
 */
public class NotifyTemplate {
    /** ID */
    private Integer id;
    /** 事件标识，如 SCRAP_PASS */
    private String eventKey;
    /** 业务类型：报废/调拨/入库/借用/维修 */
    private String bizType;
    /** 事件名称，如 报废审批通过 */
    private String eventName;
    /** 是否启用 */
    private Boolean enabled;
    /** 消息标题模板 */
    private String title;
    /** 消息正文模板，支持 {占位符} */
    private String content;
    /** 创建时间 */
    private String createTime;
    /** 更新时间 */
    private String updateTime;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getEventKey() {
        return eventKey;
    }

    public void setEventKey(String eventKey) {
        this.eventKey = eventKey;
    }

    public String getBizType() {
        return bizType;
    }

    public void setBizType(String bizType) {
        this.bizType = bizType;
    }

    public String getEventName() {
        return eventName;
    }

    public void setEventName(String eventName) {
        this.eventName = eventName;
    }

    public Boolean getEnabled() {
        return enabled;
    }

    public void setEnabled(Boolean enabled) {
        this.enabled = enabled;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getCreateTime() {
        return createTime;
    }

    public void setCreateTime(String createTime) {
        this.createTime = createTime;
    }

    public String getUpdateTime() {
        return updateTime;
    }

    public void setUpdateTime(String updateTime) {
        this.updateTime = updateTime;
    }
}
