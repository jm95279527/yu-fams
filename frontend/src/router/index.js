import Vue from 'vue'
import VueRouter from 'vue-router'
import request from '@/utils/request'

Vue.use(VueRouter)

// ==================== 菜单级 RBAC ====================
// 与业务无关、任何登录管理员都可访问的页面（个人信息/密码/403/首页）
const PERM_WHITE = ['/home', '/adminPerson', '/staffPerson', '/password', '/403']

// 菜单树按登录 token 缓存：同一次登录内所有路由跳转共用同一个请求，
// 切换账号（token 变化）自动重新拉取
let menuCache = { token: '', promise: null }

function collectPaths(menus) {
  const paths = []
  const walk = list => {
    list.forEach(m => {
      if (m.path) paths.push(m.path)
      if (m.children && m.children.length) walk(m.children)
    })
  }
  walk(menus || [])
  return paths
}

export function getMyMenuTree() {
  const user = JSON.parse(localStorage.getItem('xm-user') || '{}')
  if (!user.token) return Promise.resolve([])
  if (menuCache.token !== user.token) {
    menuCache.token = user.token
    menuCache.promise = request.get('/role/myMenus')
      .then(res => res.code === '200' ? (res.data || []) : [])
      .catch(() => [])
  }
  return menuCache.promise
}

export function resetMenuCache() {
  menuCache = { token: '', promise: null }
}

// 解决导航栏或者底部导航tabBar中的vue-router在3.0版本以上频繁点击菜单报错的问题。
const originalPush = VueRouter.prototype.push
VueRouter.prototype.push = function push (location) {
  return originalPush.call(this, location).catch(err => err)
}

const routes = [
  {
    path: '/',
    name: 'Manager',
    component: () => import('../views/Manager.vue'),
    redirect: '/home',  // 重定向到主页
    children: [
      { path: '403', name: 'NoAuth', meta: { name: '无权限' }, component: () => import('../views/manager/403') },
      { path: 'home', name: 'Home', meta: { name: '系统首页' }, component: () => import('../views/manager/Home') },
      { path: 'admin', name: 'Admin', meta: { name: '管理员信息' }, component: () => import('../views/manager/Admin') },
      { path: 'staff', name: 'Staff', meta: { name: '员工信息' }, component: () => import('../views/manager/Staff') },
      { path: 'staffPerson', name: 'StaffPerson', meta: { name: '员工个人信息' }, component: () => import('../views/manager/StaffPerson') },
      { path: 'adminPerson', name: 'AdminPerson', meta: { name: '个人信息' }, component: () => import('../views/manager/AdminPerson') },
      { path: 'password', name: 'Password', meta: { name: '修改密码' }, component: () => import('../views/manager/Password') },
      { path: 'notice', name: 'Notice', meta: { name: '公告信息' }, component: () => import('../views/manager/Notice') },
      { path: 'department', name: 'Department', meta: { name: '部门信息' }, component: () => import('../views/manager/Department') },
      { path: 'company', name: 'Company', meta: { name: '公司信息' }, component: () => import('../views/manager/Company') },
      { path: 'category', name: 'Category', meta: { name: '资产分类' }, component: () => import('../views/manager/Category') },
      { path: 'assets', name: 'Assets', meta: { name: '固定资产台账' }, component: () => import('../views/manager/Assets') },
      { path: 'assetsReceive', name: 'AssetsReceive', meta: { name: '资产借用' }, component: () => import('../views/manager/AssetsReceive') },
      { path: 'assetsIn', name: 'AssetsIn', meta: { name: '资产入库' }, component: () => import('../views/manager/AssetsIn') },
      { path: 'staffAssets', name: 'StaffAssets', meta: { name: '个人资产' }, component: () => import('../views/manager/StaffAssets') },
      { path: 'assetsRepair', name: 'AssetsRepair', meta: { name: '资产维修' }, component: () => import('../views/manager/AssetsRepair') },
      { path: 'assetsTransfer', name: 'AssetsTransfer', meta: { name: '资产调拨' }, component: () => import('../views/manager/AssetsTransfer') },
      { path: 'assetsInventory', name: 'AssetsInventory', meta: { name: '资产盘点' }, component: () => import('../views/manager/AssetsInventory') },
      { path: 'assetsScrap', name: 'AssetsScrap', meta: { name: '资产报废' }, component: () => import('../views/manager/AssetsScrap') },
      { path: 'numberRule', name: 'NumberRule', meta: { name: '资产编码规则' }, component: () => import('../views/manager/NumberRule') },
      { path: 'customFields', name: 'CustomFields', meta: { name: '自定义字段' }, component: () => import('../views/manager/CustomFields') },
      { path: 'rolePerm', name: 'RolePerm', meta: { name: '角色权限' }, component: () => import('../views/manager/RolePerm') },
      { path: 'auditLog', name: 'AuditLog', meta: { name: '日志审计' }, component: () => import('../views/manager/AuditLog') },
      { path: 'pageSetting', name: 'PageSetting', meta: { name: '页面设置' }, component: () => import('../views/manager/PageSetting') },
      { path: 'dataBackup', name: 'DataBackup', meta: { name: '数据备份' }, component: () => import('../views/manager/DataBackup') },
      { path: 'robotConfig', name: 'RobotConfig', meta: { name: '机器人配置' }, component: () => import('../views/manager/RobotConfig') },
      { path: 'notifyConfig', name: 'NotifyConfig', meta: { name: '通知信息' }, component: () => import('../views/manager/NotifyConfig') },

    ]
  },
  {
    path: '/front',
    name: 'Front',
    component: () => import('../views/Front.vue'),
    children: [
      { path: 'home', name: 'Home', meta: { name: '系统首页' }, component: () => import('../views/front/Home') },
      { path: 'person', name: 'Person', meta: { name: '个人信息' }, component: () => import('../views/front/Person') },
    ]
  },
  { path: '/login', name: 'Login', meta: { name: '登录' }, component: () => import('../views/Login.vue') },
  { path: '/scan/:code', name: 'Scan', meta: { name: '扫码查看资产' }, component: () => import('../views/Scan.vue') },
  { path: '/inventory/:code', name: 'InventoryScan', meta: { name: '手机扫码盘点' }, component: () => import('../views/InventoryScan.vue') },
  { path: '*', name: 'NotFound', meta: { name: '无法访问' }, component: () => import('../views/404.vue') },
]

const router = new VueRouter({
  mode: 'history',
  base: process.env.BASE_URL,
  routes
})

// 管理员菜单级权限守卫：进入后台路由前先确保菜单已加载，
// 在导航确认前完成鉴权，避免硬刷新越权页时的懒加载 chunk 时序竞争
router.beforeEach(async (to, from, next) => {
  const user = JSON.parse(localStorage.getItem('xm-user') || '{}')
  // 仅对后台布局（'/'）下的 ADMIN 生效；员工保持原固定菜单逻辑
  // 注意：vue-router 3 会把父记录 '/' 规范化为 ''，故用 name 判断布局
  const isManagerArea = to.matched.some(r => r.name === 'Manager')
  if (user.id && user.role === 'ADMIN' && isManagerArea) {
    const tree = await getMyMenuTree()
    if (!PERM_WHITE.includes(to.path) && !collectPaths(tree).includes(to.path)) {
      return next('/403')
    }
  }
  next()
})

export default router
