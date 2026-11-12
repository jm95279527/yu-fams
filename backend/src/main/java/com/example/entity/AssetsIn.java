package com.example.entity;

import cn.hutool.core.annotation.Alias;

import java.math.BigDecimal;


/**
 * 资产入库
*/
public class AssetsIn {
    /** ID */
    private Integer id;
    /** 审核通过后生成的资产ID */
    private Integer assetsId;
    /** 资产名称 */
    @Alias("资产名称")
    private String name;
    /** 资产分类 */
    @Alias("资产分类")
    private String category;
    /** 规格型号 */
    @Alias("规格型号")
    private String model;
    /** 入库数量 */
    @Alias("数量")
    private Integer num;
    /** 初始价值（单价） */
    @Alias("初始价值")
    private BigDecimal money;
    /** 折旧方法 */
    @Alias("折旧方法")
    private String depreciate;
    /** 采购单号 */
    @Alias("采购单号")
    private String purchaseNo;
    /** 供应商 */
    @Alias("供应商")
    private String supplier;
    /** 使用部门ID */
    private Integer departmentId;
    /** 责任人ID */
    private Integer managerId;
    /** 存放地点 */
    @Alias("存放地点")
    private String location;
    /** 资产图片 */
    private String img;
    /** 操作人ID（提交人） */
    private Integer staffId;
    /** 购置日期 */
    @Alias("购置日期")
    private String date;
    /** 验收日期 */
    @Alias("验收日期")
    private String acceptDate;
    /** 验收人 */
    @Alias("验收人")
    private String acceptUser;
    /** 验收意见 */
    @Alias("验收意见")
    private String acceptResult;
    /** 备注 */
    @Alias("备注")
    private String comment;
    /** 审核状态（待审核/通过/拒绝） */
    private String status;
    /** 审核人 */
    private String auditUser;
    /** 审核日期 */
    private String auditDate;
    /** 驳回原因 */
    private String rejectReason;

    /** 查询用：资产名称 */
    private String assetsName;
    private String assetsNo;
    private String staffName;
    /** 所属公司ID（由使用部门关联查询，非持久字段） */
    private Integer companyId;
    /** 所属公司名称（由使用部门关联查询，非持久字段） */
    private String companyName;
    private String departmentName;
    private String managerName;

    public String getAssetsNo() {
        return assetsNo;
    }

    public void setAssetsNo(String assetsNo) {
        this.assetsNo = assetsNo;
    }

    public String getStaffName() {
        return staffName;
    }

    public void setStaffName(String staffName) {
        this.staffName = staffName;
    }

    public String getAssetsName() {
        return assetsName;
    }

    public void setAssetsName(String assetsName) {
        this.assetsName = assetsName;
    }

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

    public Integer getNum() {
        return num;
    }

    public void setNum(Integer num) {
        this.num = num;
    }

    public Integer getStaffId() {
        return staffId;
    }

    public void setStaffId(Integer staffId) {
        this.staffId = staffId;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
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

    public String getPurchaseNo() {
        return purchaseNo;
    }

    public void setPurchaseNo(String purchaseNo) {
        this.purchaseNo = purchaseNo;
    }

    public String getSupplier() {
        return supplier;
    }

    public void setSupplier(String supplier) {
        this.supplier = supplier;
    }

    public Integer getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(Integer departmentId) {
        this.departmentId = departmentId;
    }

    public Integer getManagerId() {
        return managerId;
    }

    public void setManagerId(Integer managerId) {
        this.managerId = managerId;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getImg() {
        return img;
    }

    public void setImg(String img) {
        this.img = img;
    }

    public String getAcceptDate() {
        return acceptDate;
    }

    public void setAcceptDate(String acceptDate) {
        this.acceptDate = acceptDate;
    }

    public String getAcceptUser() {
        return acceptUser;
    }

    public void setAcceptUser(String acceptUser) {
        this.acceptUser = acceptUser;
    }

    public String getAcceptResult() {
        return acceptResult;
    }

    public void setAcceptResult(String acceptResult) {
        this.acceptResult = acceptResult;
    }

    public String getAuditUser() {
        return auditUser;
    }

    public void setAuditUser(String auditUser) {
        this.auditUser = auditUser;
    }

    public String getAuditDate() {
        return auditDate;
    }

    public void setAuditDate(String auditDate) {
        this.auditDate = auditDate;
    }

    public String getRejectReason() {
        return rejectReason;
    }

    public void setRejectReason(String rejectReason) {
        this.rejectReason = rejectReason;
    }

    public String getDepartmentName() {
        return departmentName;
    }

    public void setDepartmentName(String departmentName) {
        this.departmentName = departmentName;
    }

    public Integer getCompanyId() {
        return companyId;
    }

    public void setCompanyId(Integer companyId) {
        this.companyId = companyId;
    }

    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getManagerName() {
        return managerName;
    }

    public void setManagerName(String managerName) {
        this.managerName = managerName;
    }

}
