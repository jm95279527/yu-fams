<template>
  <div>
    <el-card>
      <div slot="header">
        <span>资产编码规则</span>
        <el-tag size="small" style="margin-left: 10px" :type="rule.enabled ? 'success' : 'info'">
          {{ rule.enabled ? '已启用' : '未启用' }}
        </el-tag>
      </div>

      <el-form label-width="100px" style="max-width: 760px">
        <el-form-item label="是否启用">
          <el-switch v-model="rule.enabled"></el-switch>
          <span style="margin-left: 10px; color: #999; font-size: 12px">启用后，新增资产时编号留空将按规则自动生成</span>
        </el-form-item>

        <el-form-item label="规则名称">
          <el-input v-model="rule.name" placeholder="规则名称" style="width: 300px"></el-input>
        </el-form-item>

        <el-form-item label="编码模式">
          <div class="seg-box">
            <el-tag
              v-for="(seg, idx) in segments" :key="idx"
              :closable="true" @close="removeSeg(idx)" @click="editSeg(seg)"
              :type="segType(seg)" class="seg-tag" style="cursor: pointer">
              {{ segText(seg) }}
            </el-tag>
            <el-dropdown trigger="click" @command="addSeg">
              <el-button size="mini" type="primary" plain icon="el-icon-plus" style="margin-left: 8px">添加段</el-button>
              <el-dropdown-menu slot="dropdown">
                <el-dropdown-item command="CAT">分类编码</el-dropdown-item>
                <el-dropdown-item command="YYYY">年份</el-dropdown-item>
                <el-dropdown-item command="YY">两位年份</el-dropdown-item>
                <el-dropdown-item command="MM">月份</el-dropdown-item>
                <el-dropdown-item command="LITERAL">分隔符</el-dropdown-item>
                <el-dropdown-item command="SEQ">流水号</el-dropdown-item>
              </el-dropdown-menu>
            </el-dropdown>
          </div>
          <div style="margin-top: 8px; color: #999; font-size: 12px">
            生成结果 = 模式串按段渲染，流水号在同前缀内自增，保证不重复
          </div>
        </el-form-item>

        <el-form-item label="效果预览">
          <el-input :value="preview" readonly style="width: 300px; font-weight: bold">
            <template slot="prepend">示例</template>
          </el-input>
          <el-select v-model="previewCategory" placeholder="选择分类预览" size="small" style="margin-left: 10px; width: 220px" clearable @change="loadPreview">
            <el-option v-for="item in categoryOptions" :key="item.id" :value="item.name" :label="item.label"></el-option>
          </el-select>
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="save">保存规则</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px">
      <div slot="header"><span>使用说明</span></div>
      <el-alert type="info" :closable="false" show-icon title="编码模式说明">
        <div slot="default">
          <p>1. 先在「基础资料-资产分类」中为每个分类设置编码（如 办公设备=BG、电子设备=DZ）</p>
          <p>2. 模式段：{CAT} 分类编码、{YYYY} 年份、{YY} 两位年份、{MM} 月份、{SEQ:n} n 位流水号</p>
          <p>3. 例：{CAT}-{YYYY}-{SEQ:4} → BG-2026-0001，流水号同前缀内自动递增、不重复</p>
          <p>4. 新增资产时编号留空自动生成；Excel 批量导入时空编号同样自动生成</p>
          <p>5. 修改规则不影响已生成的编号，新编号按新规则流水号重新从 1 递增</p>
        </div>
      </el-alert>
    </el-card>
  </div>
</template>

<script>
export default {
  name: "NumberRule",
  data() {
    return {
      rule: {
        name: '默认规则',
        pattern: '{CAT}-{YYYY}-{SEQ:4}',
        enabled: true
      },
      segments: [],
      preview: '',
      previewCategory: '',
      categoryList: []
    }
  },
  computed: {
    // 可用于编码预览的分类：二级分类 + 没有二级分类的一级分类
    categoryOptions() {
      return this.categoryList
        .filter(c => c.pid || !this.categoryList.some(x => x.pid === c.id))
        .map(c => ({
          ...c,
          label: c.pid ? ((c.parentName ? c.parentName + ' / ' : '') + c.name) : c.name
        }))
    }
  },
  watch: {
    segments: {
      deep: true,
      handler() {
        this.rule.pattern = this.buildPattern()
        this.loadPreview()
      }
    }
  },
  created() {
    this.loadConfig()
    this.loadCategories()
  },
  methods: {
    loadConfig() {
      this.$request.get('/numberRule/config').then(res => {
        if (res.code === '200' && res.data) {
          this.rule = {
            name: res.data.name || '默认规则',
            pattern: res.data.pattern,
            enabled: !!res.data.enabled
          }
          this.segments = this.parsePattern(res.data.pattern)
          this.loadPreview()
        }
      })
    },
    loadCategories() {
      this.$request.get('/category/selectAll').then(res => {
        this.categoryList = res.data || []
        if (!this.previewCategory && this.categoryOptions.length) {
          this.previewCategory = this.categoryOptions[0].name
        }
        this.loadPreview()
      })
    },
    loadPreview() {
      this.$request.get('/numberRule/preview', {
        params: { pattern: this.rule.pattern, category: this.previewCategory || '' }
      }).then(res => {
        if (['401', '1003', '1004'].includes(String(res.code))) {
          this.preview = ''   // 登录已失效，由 request 拦截器统一跳转登录页
        } else {
          this.preview = res.code === '200' ? res.data : res.msg
        }
      })
    },
    parsePattern(pattern) {
      const segs = []
      let last = 0
      const known = /\{(CAT|YYYY|YY|MM|SEQ(?::\d{1,2})?)\}/g
      let m
      while ((m = known.exec(pattern)) !== null) {
        if (m.index > last) {
          segs.push({ type: 'LITERAL', value: pattern.slice(last, m.index) })
        }
        const token = m[1]
        if (token.startsWith('SEQ')) {
          const len = token.includes(':') ? parseInt(token.split(':')[1], 10) : 4
          segs.push({ type: 'SEQ', len })
        } else {
          segs.push({ type: token })
        }
        last = known.lastIndex
      }
      if (last < pattern.length) {
        segs.push({ type: 'LITERAL', value: pattern.slice(last) })
      }
      return segs
    },
    buildPattern() {
      return this.segments.map(seg => {
        if (seg.type === 'LITERAL') return seg.value || ''
        if (seg.type === 'SEQ') return '{SEQ:' + (seg.len || 4) + '}'
        return '{' + seg.type + '}'
      }).join('')
    },
    addSeg(type) {
      if (type === 'SEQ') {
        this.segments.push({ type: 'SEQ', len: 4 })
      } else if (type === 'LITERAL') {
        this.$prompt('请输入分隔符内容（如 - 或 /）', '添加分隔符').then(({ value }) => {
          if (value) this.segments.push({ type: 'LITERAL', value })
        }).catch(() => {})
      } else {
        this.segments.push({ type })
      }
    },
    removeSeg(idx) {
      this.segments.splice(idx, 1)
    },
    editSeg(seg) {
      if (seg.type === 'SEQ') {
        this.$prompt('请输入流水号位数（2-8位）', '编辑流水号', { inputValue: String(seg.len || 4) }).then(({ value }) => {
          const len = parseInt(value, 10)
          if (len >= 2 && len <= 8) {
            this.$set(seg, 'len', len)
          } else {
            this.$message.warning('位数需在 2-8 之间')
          }
        }).catch(() => {})
      } else if (seg.type === 'LITERAL') {
        this.$prompt('请输入分隔符内容', '编辑分隔符', { inputValue: seg.value || '' }).then(({ value }) => {
          this.$set(seg, 'value', value || '')
        }).catch(() => {})
      }
    },
    segType(seg) {
      return seg.type === 'LITERAL' ? 'info' : 'success'
    },
    segText(seg) {
      if (seg.type === 'LITERAL') return '「' + (seg.value || '') + '」'
      if (seg.type === 'SEQ') return '流水号' + (seg.len || 4) + '位'
      return { CAT: '分类编码', YYYY: '年份', YY: '两位年份', MM: '月份' }[seg.type] || seg.type
    },
    save() {
      if (!this.rule.pattern) {
        this.$message.warning('编码模式不能为空，请至少添加一个段')
        return
      }
      this.$request.post('/numberRule/config', this.rule).then(res => {
        if (res.code === '200') {
          this.$message.success('编码规则保存成功')
        } else {
          this.$message.error(res.msg)
        }
      })
    }
  }
}
</script>

<style scoped>
.seg-box {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
}
.seg-tag {
  margin: 0 6px 6px 0;
  font-size: 13px;
}
</style>
