package com.example.entity;

import java.util.ArrayList;
import java.util.List;

/**
 * 系统菜单
 */
public class SysMenu {
    /** 菜单ID */
    private Integer id;
    /** 父菜单ID，0=顶级 */
    private Integer parentId;
    /** 菜单名称 */
    private String name;
    /** 路由路径（目录为空） */
    private String path;
    /** 该菜单控制的后端接口路径前缀，多个用逗号分隔（接口级鉴权用） */
    private String api;
    /** 图标 class */
    private String icon;
    /** 类型：1=目录 2=菜单 */
    private Integer type;
    /** 排序 */
    private Integer sort;
    /** 创建时间 */
    private String createTime;
    /** 子菜单（树形组装用，非DB字段） */
    private List<SysMenu> children = new ArrayList<>();

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getParentId() {
        return parentId;
    }

    public void setParentId(Integer parentId) {
        this.parentId = parentId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public String getApi() {
        return api;
    }

    public void setApi(String api) {
        this.api = api;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public Integer getType() {
        return type;
    }

    public void setType(Integer type) {
        this.type = type;
    }

    public Integer getSort() {
        return sort;
    }

    public void setSort(Integer sort) {
        this.sort = sort;
    }

    public String getCreateTime() {
        return createTime;
    }

    public void setCreateTime(String createTime) {
        this.createTime = createTime;
    }

    public List<SysMenu> getChildren() {
        return children;
    }

    public void setChildren(List<SysMenu> children) {
        this.children = children;
    }
}
