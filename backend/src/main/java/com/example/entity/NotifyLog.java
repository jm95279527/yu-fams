package com.example.entity;

/**
 * 通知记录
 */
public class NotifyLog {
    /** ID */
    private Integer id;
    /** 事件标识 */
    private String eventKey;
    /** 业务类型 */
    private String bizType;
    /** 业务单据ID */
    private Integer bizId;
    /** 推送标题 */
    private String title;
    /** 推送内容 */
    private String content;
    /** 机器人ID */
    private Integer robotId;
    /** 机器人名称 */
    private String robotName;
    /** 推送结果：成功/失败 */
    private String status;
    /** 机器人接口返回内容 */
    private String response;
    /** 推送时间 */
    private String createTime;

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

    public Integer getBizId() {
        return bizId;
    }

    public void setBizId(Integer bizId) {
        this.bizId = bizId;
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

    public Integer getRobotId() {
        return robotId;
    }

    public void setRobotId(Integer robotId) {
        this.robotId = robotId;
    }

    public String getRobotName() {
        return robotName;
    }

    public void setRobotName(String robotName) {
        this.robotName = robotName;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getResponse() {
        return response;
    }

    public void setResponse(String response) {
        this.response = response;
    }

    public String getCreateTime() {
        return createTime;
    }

    public void setCreateTime(String createTime) {
        this.createTime = createTime;
    }
}
