package com.example.entity;

import cn.hutool.core.annotation.Alias;

/**
 * 资产盘点明细
 */
public class InventoryItem {
    /** ID */
    @Alias("ID")
    private Integer id;
    /** 盘点任务ID */
    private Integer taskId;
    /** 资产ID */
    @Alias("资产ID")
    private Integer assetsId;
    /** 资产编号 */
    @Alias("资产编号")
    private String assetsNo;
    /** 资产名称 */
    @Alias("资产名称")
    private String assetsName;
    /** 资产型号（快照） */
    @Alias("资产型号")
    private String model;
    /** 资产分类 */
    @Alias("分类")
    private String category;
    /** 台账部门ID */
    private Integer departmentId;
    /** 台账部门 */
    @Alias("台账部门")
    private String departmentName;
    /** 台账责任人ID */
    private Integer staffId;
    /** 台账责任人 */
    @Alias("台账责任人")
    private String staffName;
    /** 台账地点 */
    @Alias("台账地点")
    private String location;
    /** 实盘地点 */
    @Alias("实盘地点")
    private String actualLocation;
    /** 明细状态：未盘 / 正常 / 异常 / 盘亏 / 盘盈 */
    @Alias("盘点结果")
    private String itemStatus;
    /** 是否范围外盘盈：0否 1是 */
    private Integer isExtra;
    /** 差异处理状态：待处理 / 已处理（正常、未盘项为空） */
    @Alias("处理状态")
    private String dealStatus;
    /** 处理方式 */
    @Alias("处理方式")
    private String dealType;
    /** 处理说明 */
    @Alias("处理说明")
    private String dealRemark;
    /** 处理人ID */
    private Integer dealUserId;
    /** 处理人姓名 */
    @Alias("处理人")
    private String dealUser;
    /** 处理时间 */
    @Alias("处理时间")
    private String dealTime;
    /** 盘点人ID */
    private Integer scannerId;
    /** 盘点人姓名 */
    @Alias("盘点人")
    private String scannerName;
    /** 盘点时间 */
    @Alias("盘点时间")
    private String scanTime;
    /** 备注 */
    @Alias("备注")
    private String comment;
    /** 创建时间 */
    private String createTime;
    /** 更新时间 */
    private String updateTime;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public Integer getTaskId() { return taskId; }
    public void setTaskId(Integer taskId) { this.taskId = taskId; }
    public Integer getAssetsId() { return assetsId; }
    public void setAssetsId(Integer assetsId) { this.assetsId = assetsId; }
    public String getAssetsNo() { return assetsNo; }
    public void setAssetsNo(String assetsNo) { this.assetsNo = assetsNo; }
    public String getAssetsName() { return assetsName; }
    public void setAssetsName(String assetsName) { this.assetsName = assetsName; }
    public String getModel() { return model; }
    public void setModel(String model) { this.model = model; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public Integer getDepartmentId() { return departmentId; }
    public void setDepartmentId(Integer departmentId) { this.departmentId = departmentId; }
    public String getDepartmentName() { return departmentName; }
    public void setDepartmentName(String departmentName) { this.departmentName = departmentName; }
    public Integer getStaffId() { return staffId; }
    public void setStaffId(Integer staffId) { this.staffId = staffId; }
    public String getStaffName() { return staffName; }
    public void setStaffName(String staffName) { this.staffName = staffName; }
    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }
    public String getActualLocation() { return actualLocation; }
    public void setActualLocation(String actualLocation) { this.actualLocation = actualLocation; }
    public String getItemStatus() { return itemStatus; }
    public void setItemStatus(String itemStatus) { this.itemStatus = itemStatus; }
    public Integer getIsExtra() { return isExtra; }
    public void setIsExtra(Integer isExtra) { this.isExtra = isExtra; }
    public String getDealStatus() { return dealStatus; }
    public void setDealStatus(String dealStatus) { this.dealStatus = dealStatus; }
    public String getDealType() { return dealType; }
    public void setDealType(String dealType) { this.dealType = dealType; }
    public String getDealRemark() { return dealRemark; }
    public void setDealRemark(String dealRemark) { this.dealRemark = dealRemark; }
    public Integer getDealUserId() { return dealUserId; }
    public void setDealUserId(Integer dealUserId) { this.dealUserId = dealUserId; }
    public String getDealUser() { return dealUser; }
    public void setDealUser(String dealUser) { this.dealUser = dealUser; }
    public String getDealTime() { return dealTime; }
    public void setDealTime(String dealTime) { this.dealTime = dealTime; }
    public Integer getScannerId() { return scannerId; }
    public void setScannerId(Integer scannerId) { this.scannerId = scannerId; }
    public String getScannerName() { return scannerName; }
    public void setScannerName(String scannerName) { this.scannerName = scannerName; }
    public String getScanTime() { return scanTime; }
    public void setScanTime(String scanTime) { this.scanTime = scanTime; }
    public String getComment() { return comment; }
    public void setComment(String comment) { this.comment = comment; }
    public String getCreateTime() { return createTime; }
    public void setCreateTime(String createTime) { this.createTime = createTime; }
    public String getUpdateTime() { return updateTime; }
    public void setUpdateTime(String updateTime) { this.updateTime = updateTime; }
}
