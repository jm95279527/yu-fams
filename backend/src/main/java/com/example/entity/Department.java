package com.example.entity;


import java.util.List;

/**
 * 部门信息
 */
public class Department {
    /** ID */
    private Integer id;
    /** 名称 */
    private String name;
    /** 地址 */
    private String address;
    /** 父级ID */
    private Integer pid;
    /** 层级 */
    private Integer level;
    /** 所属公司ID */
    private Integer companyId;
    /** 所属公司名称（关联查询） */
    private String companyName;
    /** 展示名：公司-部门（关联查询，用于下拉/树展示） */
    private String label;
    private List Children;

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

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public List getChildren() {
        return Children;
    }

    public void setChildren(List children) {
        Children = children;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public Integer getPid() {
        return pid;
    }

    public void setPid(Integer pid) {
        this.pid = pid;
    }

    public Integer getLevel() {
        return level;
    }

    public void setLevel(Integer level) {
        this.level = level;
    }

}