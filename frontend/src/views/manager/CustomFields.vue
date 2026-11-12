<template>
  <div>
    <el-alert type="info" :closable="false" show-icon style="margin-bottom: 15px">
      <div slot="default">
        <p>1. 系统字段可修改显示名称，修改后全站（台账、入库、调拨、报废、盘点、扫码页、导入导出）同步生效</p>
        <p>2. 自定义字段共 10 个字段位：填写名称并启用后，会出现在资产新增/编辑、台账列表、资产详情、扫码页和导入导出中</p>
        <p>3. 类型支持单行文本、数字、日期、下拉选项；下拉选项用英文逗号分隔，如：高,中,低</p>
      </div>
    </el-alert>

    <div class="table">
      <el-table :data="tableData" border stripe>
        <el-table-column label="字段标识" width="120" align="center">
          <template v-slot="scope">
            <span>{{ scope.row.isSystem ? scope.row.fieldKey : '自定义位 ' + scope.row.fieldKey.replace('custom', '') }}</span>
          </template>
        </el-table-column>
        <el-table-column label="显示名称" min-width="180">
          <template v-slot="scope">
            <el-input v-model="scope.row.label" maxlength="20" placeholder="请输入字段名称"></el-input>
          </template>
        </el-table-column>
        <el-table-column label="字段类型" width="150">
          <template v-slot="scope">
            <el-select v-if="!scope.row.isSystem" v-model="scope.row.fieldType" style="width: 100%" @change="onTypeChange(scope.row)">
              <el-option label="单行文本" value="text"></el-option>
              <el-option label="数字" value="number"></el-option>
              <el-option label="日期" value="date"></el-option>
              <el-option label="下拉选项" value="select"></el-option>
            </el-select>
            <span v-else class="system-text">{{ typeText(scope.row.fieldType) }}</span>
          </template>
        </el-table-column>
        <el-table-column label="下拉选项（逗号分隔）" min-width="220">
          <template v-slot="scope">
            <el-input v-if="!scope.row.isSystem" v-model="scope.row.options"
                      :disabled="scope.row.fieldType !== 'select'"
                      placeholder="如：高,中,低"></el-input>
            <span v-else class="system-text">-</span>
          </template>
        </el-table-column>
        <el-table-column label="启用" width="90" align="center">
          <template v-slot="scope">
            <el-tag v-if="scope.row.isSystem" size="small" type="success">系统字段</el-tag>
            <el-switch v-else v-model="scope.row.enabled" :active-value="1" :inactive-value="0"></el-switch>
          </template>
        </el-table-column>
        <el-table-column label="排序" width="120" align="center">
          <template v-slot="scope">
            <el-input-number v-model="scope.row.sortNum" :min="1" :max="999"
                             controls-position="right" style="width: 95px"></el-input-number>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <div class="footer">
      <el-button type="primary" :loading="saving" @click="save">保 存</el-button>
      <el-button @click="load">还 原</el-button>
    </div>
  </div>
</template>

<script>
import { loadFieldConfig } from '@/utils/fields'

export default {
  name: 'CustomFields',
  data() {
    return {
      tableData: [],
      saving: false
    }
  },
  created() {
    this.load()
  },
  methods: {
    load() {
      this.$request.get('/assetField/selectAll').then(res => {
        if (res.code === '200') {
          this.tableData = (res.data || []).map(item => ({
            ...item,
            label: item.label || '',
            fieldType: item.fieldType || 'text',
            options: item.options || '',
            enabled: item.enabled == null ? 0 : item.enabled
          }))
        } else {
          this.$message.error(res.msg || '读取字段配置失败')
        }
      })
    },
    typeText(type) {
      return { text: '单行文本', number: '数字', date: '日期', select: '下拉选项' }[type] || '单行文本'
    },
    onTypeChange(row) {
      if (row.fieldType !== 'select') {
        row.options = ''
      }
    },
    save() {
      const labels = []
      for (const row of this.tableData) {
        const label = (row.label || '').trim()
        if (!label) {
          this.$message.warning('字段名称不能为空')
          return
        }
        if (labels.includes(label)) {
          this.$message.warning('字段名称「' + label + '」重复，请修改')
          return
        }
        labels.push(label)
        if (!row.isSystem && row.enabled === 1) {
          if (row.fieldType === 'select' && !(row.options || '').trim()) {
            this.$message.warning('下拉字段「' + label + '」必须填写选项')
            return
          }
        }
      }
      this.saving = true
      this.$request.put('/assetField/save', this.tableData).then(res => {
        this.saving = false
        if (res.code === '200') {
          this.$message.success('保存成功，全站字段名称已同步')
          loadFieldConfig()
          this.load()
        } else {
          this.$message.error(res.msg || '保存失败')
        }
      }).catch(() => {
        this.saving = false
      })
    }
  }
}
</script>

<style scoped>
.system-text { color: #909399; }
.footer { margin-top: 16px; }
</style>
