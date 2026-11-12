package com.example.service;

import com.example.entity.SysMenu;
import com.example.mapper.SysMenuMapper;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 系统菜单业务处理
 **/
@Service
public class SysMenuService {

    @Resource
    private SysMenuMapper sysMenuMapper;

    /**
     * 全部菜单（平铺，按排序）
     */
    public List<SysMenu> selectAll() {
        return sysMenuMapper.selectAll();
    }

    /**
     * 全部菜单树（角色授权弹窗用）
     */
    public List<SysMenu> tree() {
        return buildTree(sysMenuMapper.selectAll());
    }

    /**
     * 根据菜单ID集合构建菜单树（自动补齐父级目录）
     */
    public List<SysMenu> treeByIds(List<Integer> ids) {
        if (ids == null || ids.isEmpty()) {
            return new ArrayList<>();
        }
        List<SysMenu> menus = sysMenuMapper.selectByIds(ids);
        // 补齐祖先目录，保证树结构完整
        Map<Integer, SysMenu> map = new LinkedHashMap<>();
        for (SysMenu m : menus) {
            map.put(m.getId(), m);
        }
        boolean added = true;
        while (added) {
            added = false;
            for (SysMenu m : new ArrayList<>(map.values())) {
                Integer pid = m.getParentId();
                if (pid != null && pid != 0 && !map.containsKey(pid)) {
                    SysMenu parent = findById(pid);
                    if (parent != null) {
                        map.put(parent.getId(), parent);
                        added = true;
                    }
                }
            }
        }
        List<SysMenu> all = new ArrayList<>(map.values());
        all.sort((a, b) -> {
            int c = Integer.compare(a.getSort() == null ? 0 : a.getSort(), b.getSort() == null ? 0 : b.getSort());
            return c != 0 ? c : Integer.compare(a.getId(), b.getId());
        });
        return buildTree(all);
    }

    private SysMenu findById(Integer id) {
        for (SysMenu m : sysMenuMapper.selectAll()) {
            if (m.getId().equals(id)) {
                return m;
            }
        }
        return null;
    }

    /**
     * 平铺列表 → 树
     */
    private List<SysMenu> buildTree(List<SysMenu> all) {
        Map<Integer, SysMenu> map = new LinkedHashMap<>();
        for (SysMenu m : all) {
            m.setChildren(new ArrayList<>());
            map.put(m.getId(), m);
        }
        List<SysMenu> roots = new ArrayList<>();
        for (SysMenu m : all) {
            Integer pid = m.getParentId();
            if (pid == null || pid == 0 || !map.containsKey(pid)) {
                roots.add(m);
            } else {
                map.get(pid).getChildren().add(m);
            }
        }
        return roots;
    }
}
