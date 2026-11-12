package com.example.entity;


/**
 * 资产分类
 */
public class Category {
    /** ID */
    private Integer id;
    /** 分类名称 */
    private String name;
    /** 分类编码（用于资产编号生成） */
    private String code;
    /** 上级分类ID（0=一级分类） */
    private Integer pid;
    /** 上级分类名称（关联查询） */
    private String parentName;

    public Integer getPid() {
        return pid;
    }

    public void setPid(Integer pid) {
        this.pid = pid;
    }

    public String getParentName() {
        return parentName;
    }

    public void setParentName(String parentName) {
        this.parentName = parentName;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
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

}