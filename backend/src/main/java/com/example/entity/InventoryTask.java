package com.example.entity;

import cn.hutool.core.annotation.Alias;

/**
 * 资产盘点任务
 */
public class InventoryTask {
    /** ID */
    @Alias("ID")
    private Integer id;
    /** 手机扫码盘点访问码（二维码内容，唯一） */
    private String accessCode;
    /** 任务名称 */
    @Alias("任务名称")
    private String name;
    /** 盘点范围类型：ALL全部 / DEPT按部门 / COMPANY按公司 / CATEGORY按分类 */
    @Alias("范围类型")
    private String scopeType;
    /** 范围ID（部门ID/公司ID/分类ID，ALL为空） */
    private Integer scopeId;
    /** 范围名称（快照） */
    @Alias("盘点范围")
    private String scopeName;
    /** 任务状态：盘点中 / 已完成 */
    @Alias("状态")
    private String status;
    /** 创建人ID */
    private Integer creatorId;
    /** 创建人姓名 */
    @Alias("创建人")
    private String creatorName;
    /** 应盘总数（含盘盈） */
    @Alias("应盘总数")
    private Integer totalCount;
    /** 正常数量 */
    @Alias("正常")
    private Integer normalCount;
    /** 盘盈数量 */
    @Alias("盘盈")
    private Integer profitCount;
    /** 盘亏数量 */
    @Alias("盘亏")
    private Integer lossCount;
    /** 异常数量 */
    @Alias("异常")
    private Integer abnormalCount;
    /** 待处理差异数 */
    @Alias("待处理差异")
    private Integer pendingDiffCount;
    /** 备注 */
    @Alias("备注")
    private String remark;
    /** 创建时间 */
    @Alias("创建时间")
    private String createTime;
    /** 完成时间 */
    @Alias("完成时间")
    private String finishTime;
    /** 更新时间 */
    private String updateTime;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public String getAccessCode() { return accessCode; }
    public void setAccessCode(String accessCode) { this.accessCode = accessCode; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getScopeType() { return scopeType; }
    public void setScopeType(String scopeType) { this.scopeType = scopeType; }
    public Integer getScopeId() { return scopeId; }
    public void setScopeId(Integer scopeId) { this.scopeId = scopeId; }
    public String getScopeName() { return scopeName; }
    public void setScopeName(String scopeName) { this.scopeName = scopeName; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Integer getCreatorId() { return creatorId; }
    public void setCreatorId(Integer creatorId) { this.creatorId = creatorId; }
    public String getCreatorName() { return creatorName; }
    public void setCreatorName(String creatorName) { this.creatorName = creatorName; }
    public Integer getTotalCount() { return totalCount; }
    public void setTotalCount(Integer totalCount) { this.totalCount = totalCount; }
    public Integer getNormalCount() { return normalCount; }
    public void setNormalCount(Integer normalCount) { this.normalCount = normalCount; }
    public Integer getProfitCount() { return profitCount; }
    public void setProfitCount(Integer profitCount) { this.profitCount = profitCount; }
    public Integer getLossCount() { return lossCount; }
    public void setLossCount(Integer lossCount) { this.lossCount = lossCount; }
    public Integer getAbnormalCount() { return abnormalCount; }
    public void setAbnormalCount(Integer abnormalCount) { this.abnormalCount = abnormalCount; }
    public Integer getPendingDiffCount() { return pendingDiffCount; }
    public void setPendingDiffCount(Integer pendingDiffCount) { this.pendingDiffCount = pendingDiffCount; }
    public String getRemark() { return remark; }
    public void setRemark(String remark) { this.remark = remark; }
    public String getCreateTime() { return createTime; }
    public void setCreateTime(String createTime) { this.createTime = createTime; }
    public String getFinishTime() { return finishTime; }
    public void setFinishTime(String finishTime) { this.finishTime = finishTime; }
    public String getUpdateTime() { return updateTime; }
    public void setUpdateTime(String updateTime) { this.updateTime = updateTime; }
}
