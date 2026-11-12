<template>
  <div class="manager-container">
    <!--  头部  -->
    <div class="manager-header">
      <div class="manager-header-left">
        <img :src="$cfg.logo || defaultLogo" />
        <div class="title">{{ $cfg.systemName }}</div>
      </div>

      <div class="manager-header-center">
        <el-breadcrumb separator-class="el-icon-arrow-right">
          <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
          <el-breadcrumb-item :to="{ path: $route.path }">{{ $route.meta.name }}</el-breadcrumb-item>
        </el-breadcrumb>
      </div>

      <div class="manager-header-right">
        <el-dropdown placement="bottom">
          <div class="avatar">
            <img :src="user.avatar || 'https://cube.elemecdn.com/3/7c/3ea6beec64369c2642b92c6726f1epng.png'" />
            <div>{{ user.name ||  '管理员' }}</div>
          </div>
          <el-dropdown-menu slot="dropdown">
            <el-dropdown-item @click.native="goToPerson">个人信息</el-dropdown-item>
            <el-dropdown-item @click.native="$router.push('/password')">修改密码</el-dropdown-item>
            <el-dropdown-item @click.native="logout">退出登录</el-dropdown-item>
          </el-dropdown-menu>
        </el-dropdown>
      </div>
    </div>

    <!--  主体  -->
    <div class="manager-main">
      <!--  侧边栏  -->
      <div class="manager-main-left">
        <el-menu :default-openeds="openeds" router style="border: none" :default-active="$route.path">
          <!-- ============ 员工：固定菜单（保持原逻辑） ============ -->
          <template v-if="user.role === 'STAFF'">
            <el-menu-item index="/home">
              <i class="el-icon-data-analysis"></i>
              <span slot="title">资产驾驶舱</span>
            </el-menu-item>
            <el-submenu index="assets">
              <template slot="title">
                <i class="el-icon-box"></i><span>资产管理</span>
              </template>
              <el-menu-item index="/assets">固定资产台账</el-menu-item>
              <el-menu-item index="/assetsReceive">资产借用</el-menu-item>
              <el-menu-item index="/assetsRepair">资产维修</el-menu-item>
              <el-menu-item index="/staffAssets">个人资产</el-menu-item>
            </el-submenu>
          </template>

          <!-- ============ 管理员：按角色权限动态渲染 ============ -->
          <template v-else>
            <template v-for="m in menuTree">
              <el-menu-item v-if="m.type === 2" :key="m.id" :index="m.path">
                <i :class="m.icon"></i>
                <span slot="title">{{ m.name }}</span>
              </el-menu-item>
              <el-submenu v-else :key="m.id" :index="'group-' + m.id">
                <template slot="title">
                  <i :class="m.icon"></i><span>{{ m.name }}</span>
                </template>
                <el-menu-item v-for="c in m.children" :key="c.id" :index="c.path">{{ c.name }}</el-menu-item>
              </el-submenu>
            </template>
          </template>
        </el-menu>
      </div>

      <!--  数据表格  -->
      <div class="manager-main-right">
        <router-view @update:user="updateUser" />
        <!--  页脚版权信息（在「页面设置」里配置，留空则不显示）  -->
        <div class="manager-footer" v-if="$cfg.footerText">{{ $cfg.footerText }}</div>
      </div>
    </div>

  </div>
</template>

<script>
import { getMyMenuTree, resetMenuCache } from '@/router'
import defaultLogo from '@/assets/imgs/logo.png'

export default {
  name: "Manager",
  data() {
    return {
      user: JSON.parse(localStorage.getItem('xm-user') || '{}'),
      openeds: ['assets', 'base', 'perm', 'system', 'group-10', 'group-20', 'group-30', 'group-40', 'group-50'],
      menuTree: [],
      defaultLogo
    }
  },
  created() {
    if (!this.user.id) {
      this.$router.push('/login')
      return
    }
    if (this.user.role === 'ADMIN') {
      this.loadMenus()
    }
  },
  methods: {
    // 复用路由守卫的菜单缓存（按 token），避免重复请求
    loadMenus() {
      getMyMenuTree().then(tree => { this.menuTree = tree })
    },
    updateUser() {
      this.user = JSON.parse(localStorage.getItem('xm-user') || '{}')   // 重新获取下用户的最新信息
    },
    goToPerson() {
      if (this.user.role === 'ADMIN') {
        this.$router.push('/adminPerson')
      }else if(this.user.role === 'STAFF') {
        this.$router.push('/staffPerson')
      }
    },
    logout() {
      localStorage.removeItem('xm-user')
      resetMenuCache()
      this.$router.push('/login')
    }
  }
}
</script>

<style scoped>
@import '../assets/css/manager.css';

/* 页脚版权信息（在「页面设置」里配置） */
.manager-footer {
  margin-top: 10px;
  padding: 12px 0;
  text-align: center;
  color: #909399;
  font-size: 12px;
}
</style>
