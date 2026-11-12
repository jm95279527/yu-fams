package com.example.entity;

import cn.hutool.core.annotation.Alias;

import java.math.BigDecimal;

/**
 * 资产报废单
 */
public class AssetsScrap {
    /** ID */
    @Alias("ID")
    private Integer id;
    /** 资产ID */
    @Alias("资产ID")
    private Integer assetsId;
    /** 资产编号（快照） */
    @Alias("资产编号")
    private String assetsNo;
    /** 资产名称（快照） */
    @Alias("资产名称")
    private String assetsName;
    /** 分类（快照） */
    @Alias("分类")
    private String category;
    /** 型号（快照） */
    @Alias("型号")
    private String model;
    /** 原值（快照） */
    @Alias("原值")
    private BigDecimal money;
    /** 折旧（快照，与 Assets.depreciate 一致为 String） */
    @Alias("折旧")
    private String depreciate;
    /** 部门ID（快照） */
    private Integer departmentId;
    /** 部门名称（快照） */
    @Alias("部门")
    private String departmentName;
    /** 责任人ID（快照） */
    private Integer staffId;
    /** 责任人名称（快照） */
    @Alias("责任人")
    private String staffName;
    /** 存放地点（快照） */
    @Alias("存放地点")
    private String location;
    /** 报废类型：正常报废/毁损/丢失/其他 */
    @Alias("报废类型")
    private String scrapType;
    /** 报废原因 */
    @Alias("报废原因")
    private String reason;
    /** 残值 */
    @Alias("残值")
    private BigDecimal residualValue;
    /** 申请时间 */
    @Alias("申请时间")
    private String applyTime;
    /** 申请人ID */
    private Integer applicantId;
    /** 申请人姓名 */
    @Alias("申请人")
    private String applicantName;
    /** 状态：待审批/已报废/已拒绝 */
    @Alias("状态")
    private String status;
    /** 审批人ID */
    private Integer approverId;
    /** 审批人姓名 */
    @Alias("审批人")
    private String approverName;
    /** 审批时间 */
    @Alias("审批时间")
    private String approveTime;
    /** 审批意见/驳回原因 */
    @Alias("审批意见")
    private String approveComment;
    /** 备注 */
    @Alias("备注")
    private String comment;
    /** 创建时间 */
    @Alias("创建时间")
    private String createTime;
    /** 更新时间 */
    @Alias("更新时间")
    private String updateTime;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getAssetsId() {
        return assetsId;
    }

    public void setAssetsId(Integer assetsId) {
        this.assetsId = assetsId;
    }

    public String getAssetsNo() {
        return assetsNo;
    }

    public void setAssetsNo(String assetsNo) {
        this.assetsNo = assetsNo;
    }

    public String getAssetsName() {
        return assetsName;
    }

    public void setAssetsName(String assetsName) {
        this.assetsName = assetsName;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public BigDecimal getMoney() {
        return money;
    }

    public void setMoney(BigDecimal money) {
        this.money = money;
    }

    public String getDepreciate() {
        return depreciate;
    }

    public void setDepreciate(String depreciate) {
        this.depreciate = depreciate;
    }

    public Integer getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(Integer departmentId) {
        this.departmentId = departmentId;
    }

    public String getDepartmentName() {
        return departmentName;
    }

    public void setDepartmentName(String departmentName) {
        this.departmentName = departmentName;
    }

    public Integer getStaffId() {
        return staffId;
    }

    public void setStaffId(Integer staffId) {
        this.staffId = staffId;
    }

    public String getStaffName() {
        return staffName;
    }

    public void setStaffName(String staffName) {
        this.staffName = staffName;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getScrapType() {
        return scrapType;
    }

    public void setScrapType(String scrapType) {
        this.scrapType = scrapType;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public BigDecimal getResidualValue() {
        return residualValue;
    }

    public void setResidualValue(BigDecimal residualValue) {
        this.residualValue = residualValue;
    }

    public String getApplyTime() {
        return applyTime;
    }

    public void setApplyTime(String applyTime) {
        this.applyTime = applyTime;
    }

    public Integer getApplicantId() {
        return applicantId;
    }

    public void setApplicantId(Integer applicantId) {
        this.applicantId = applicantId;
    }

    public String getApplicantName() {
        return applicantName;
    }

    public void setApplicantName(String applicantName) {
        this.applicantName = applicantName;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Integer getApproverId() {
        return approverId;
    }

    public void setApproverId(Integer approverId) {
        this.approverId = approverId;
    }

    public String getApproverName() {
        return approverName;
    }

    public void setApproverName(String approverName) {
        this.approverName = approverName;
    }

    public String getApproveTime() {
        return approveTime;
    }

    public void setApproveTime(String approveTime) {
        this.approveTime = approveTime;
    }

    public String getApproveComment() {
        return approveComment;
    }

    public void setApproveComment(String approveComment) {
        this.approveComment = approveComment;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
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
