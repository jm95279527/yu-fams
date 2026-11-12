import Vue from 'vue'
import request from '@/utils/request'

/**
 * 资产字段配置（基础资料 → 自定义字段）
 * - 系统字段改名后通过 $field('no') 等在全站生效
 * - 自定义字段（custom1..custom10）启用后出现在资产表单/列表/详情/扫码/导入导出
 */
const CACHE_KEY = 'xm-asset-fields'

/** 配置未加载时的系统字段默认名称 */
export const DEFAULT_LABELS = {
  no: '资产编号',
  name: '资产名称',
  category: '资产分类',
  img: '资产图片',
  model: '资产型号',
  num: '数量',
  date: '购置日期',
  money: '初始价值',
  depreciate: '折旧方法',
  companyName: '所属公司',
  departmentName: '使用部门',
  staffName: '责任人',
  location: '存放地点',
  status: '资产状态',
  comment: '备注'
}

/** 扫码页可选系统字段（key 为扫码配置键，fieldKey 为字段配置标识） */
export const SCAN_SYSTEM_FIELDS = [
  { key: 'no', fieldKey: 'no' },
  { key: 'category', fieldKey: 'category' },
  { key: 'company', fieldKey: 'companyName' },
  { key: 'model', fieldKey: 'model' },
  { key: 'status', fieldKey: 'status' },
  { key: 'date', fieldKey: 'date' },
  { key: 'money', fieldKey: 'money' },
  { key: 'num', fieldKey: 'num' },
  { key: 'depreciate', fieldKey: 'depreciate' },
  { key: 'departmentName', fieldKey: 'departmentName' },
  { key: 'staffName', fieldKey: 'staffName' },
  { key: 'location', fieldKey: 'location' },
  { key: 'comment', fieldKey: 'comment' },
  { key: 'img', fieldKey: 'img' }
]

function readCache() {
  try {
    const data = JSON.parse(localStorage.getItem(CACHE_KEY) || '[]')
    return Array.isArray(data) ? data : []
  } catch (e) {
    return []
  }
}

const fieldStore = Vue.observable({ fields: readCache() })

/** 拉取字段配置（失败时静默使用缓存/默认名称） */
export function loadFieldConfig() {
  return request.get('/assetField/public').then(res => {
    if (res && res.code === '200' && Array.isArray(res.data)) {
      fieldStore.fields = res.data
      localStorage.setItem(CACHE_KEY, JSON.stringify(res.data))
    }
    return fieldStore
  }).catch(() => fieldStore)
}

/** 取字段显示名称 */
export function fieldLabel(key, fallback) {
  const list = fieldStore.fields || []
  const found = list.find(f => f.fieldKey === key)
  return (found && found.label) || fallback || DEFAULT_LABELS[key] || key
}

/** 已启用的自定义字段 */
export function customFieldList() {
  return (fieldStore.fields || []).filter(f => !f.isSystem && f.enabled !== 0)
}

/** 扫码页可配置字段（系统字段 + 已启用自定义字段），label 随改名同步 */
export function scanFieldOptions() {
  const system = SCAN_SYSTEM_FIELDS.map(f => ({ key: f.key, label: fieldLabel(f.fieldKey) }))
  const custom = customFieldList().map(f => ({ key: f.fieldKey, label: f.label }))
  return system.concat(custom)
}

/** 下拉字段的选项数组 */
export function fieldOptionList(field) {
  if (!field || field.fieldType !== 'select' || !field.options) {
    return []
  }
  return String(field.options).split(',').map(s => s.trim()).filter(Boolean)
}

export default fieldStore
