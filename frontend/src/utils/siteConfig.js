import Vue from 'vue'
import request from '@/utils/request'

/**
 * 站点/页面配置（页面设置页维护）
 * - 先用 localStorage 缓存立即渲染（避免登录页闪烁），再异步拉取最新配置
 * - 用 Vue.observable 保证配置更新后引用它的组件自动重新渲染
 */
const CACHE_KEY = 'xm-site-config'

/**
 * 扫码页可显示的字段字典（顺序即页面展示顺序）
 * 与「系统管理 → 页面设置 → 扫码页显示字段」共用
 */
export const SCAN_FIELDS = [
  { key: 'no', label: '资产编号' },
  { key: 'category', label: '资产分类' },
  { key: 'company', label: '所属公司' },
  { key: 'model', label: '资产型号' },
  { key: 'status', label: '资产状态' },
  { key: 'date', label: '购置日期' },
  { key: 'money', label: '初始价值' },
  { key: 'num', label: '数量' },
  { key: 'depreciate', label: '折旧方法' },
  { key: 'departmentName', label: '使用部门' },
  { key: 'staffName', label: '责任人' },
  { key: 'location', label: '存放地点' },
  { key: 'comment', label: '备注' },
  { key: 'img', label: '资产图片' }
]

/** 默认显示字段（含所属公司；不含 数量/折旧方法） */
const DEFAULT_SCAN_FIELDS = ['no', 'category', 'company', 'model', 'status', 'date', 'money',
  'departmentName', 'staffName', 'location', 'comment', 'img']

const DEFAULTS = {
  systemName: '固定资产管理系统',   // 系统名称：后台顶栏 + 登录页标题
  browserTitle: '',                // 浏览器标签标题（留空跟随系统名称）
  loginSubtitle: '欢迎使用',        // 登录页副标题
  loginBg: '',                     // 登录页壁纸（空=内置背景图）
  logo: '',                        // Logo（空=内置 Logo）
  footerText: '',                  // 页脚版权信息（空=不显示）
  dashboardWelcome: '欢迎使用固定资产管理系统', // 驾驶舱欢迎词
  scanFields: DEFAULT_SCAN_FIELDS, // 扫码页显示字段（字段 key 列表）
  // 扫码页固定文字
  scanTitle: '资产信息',
  scanFooter: '固定资产管理系统',
  scanBorrowText: '申请借用',
  scanRepairText: '申请报修'
}

function readCache() {
  try {
    return JSON.parse(localStorage.getItem(CACHE_KEY) || '{}') || {}
  } catch (e) {
    return {}
  }
}

const siteConfig = Vue.observable(Object.assign({}, DEFAULTS, readCache()))

function applyBrowserTitle() {
  const title = siteConfig.browserTitle || siteConfig.systemName
  if (title) {
    document.title = title
  }
}

function saveCache() {
  const data = {}
  Object.keys(DEFAULTS).forEach(k => { data[k] = siteConfig[k] })
  localStorage.setItem(CACHE_KEY, JSON.stringify(data))
}

/**
 * 拉取公开配置；失败时静默使用缓存/默认值，不影响页面
 */
export function loadSiteConfig() {
  return request.get('/sysConfig/public').then(res => {
    if (res && res.code === '200' && res.data) {
      Object.keys(DEFAULTS).forEach(k => {
        const v = res.data[k]
        if (v !== undefined && v !== null) {
          siteConfig[k] = v
        }
      })
      saveCache()
    }
    applyBrowserTitle()
    return siteConfig
  }).catch(() => {
    applyBrowserTitle()
    return siteConfig
  })
}

applyBrowserTitle()

export default siteConfig
