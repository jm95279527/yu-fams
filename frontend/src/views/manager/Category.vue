<template>
  <div>
    <div class="search">
      <el-input placeholder="请输入分类名称查询" style="width: 200px" v-model="name" clearable
                @keyup.enter.native="load"></el-input>
      <el-button type="info" plain style="margin-left: 10px" @click="load">查询</el-button>
      <el-button type="warning" plain style="margin-left: 10px" @click="reset">重置</el-button>
    </div>

    <div class="operation">
      <el-button type="primary" plain @click="handleAdd">新增</el-button>
      <el-button type="danger" plain @click="delBatch">批量删除</el-button>
      <span class="tip">最多支持二级分类；一级分类可继续添加二级分类</span>
    </div>

    <div class="table">
      <el-table :data="tableData" row-key="id" :tree-props="{children: 'children'}" default-expand-all
                @selection-change="handleSelectionChange">
        <el-table-column type="selection" width="55" align="center"></el-table-column>
        <el-table-column prop="name" label="分类名称"></el-table-column>
        <el-table-column label="上级分类" width="180">
          <template v-slot="scope">
            <span v-if="scope.row.pid">{{ scope.row.parentName || '-' }}</span>
            <el-tag v-else size="small" type="info">一级分类</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="code" label="分类编码" width="140">
          <template v-slot="scope">
            <el-tag size="small" type="success" v-if="scope.row.code">{{ scope.row.code }}</el-tag>
            <span v-else style="color: #f56c6c">未设置</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" align="center" width="220">
          <template v-slot="scope">
            <el-button size="mini" type="text" @click="handleAddChild(scope.row)"
                       v-if="!scope.row.pid">添加二级</el-button>
            <el-button size="mini" type="text" @click="handleEdit(scope.row)">编辑</el-button>
            <el-button size="mini" type="text" style="color: #f56c6c" @click="del(scope.row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <el-dialog title="资产分类" :visible.sync="fromVisible" width="40%" :close-on-click-modal="false" destroy-on-close>
      <el-form :model="form" label-width="100px" style="padding-right: 50px" :rules="rules" ref="formRef">
        <el-form-item label="上级分类">
          <el-select v-model="form.pid" style="width: 100%" :disabled="parentSelectDisabled">
            <el-option :value="0" label="无（一级分类）"></el-option>
            <el-option v-for="item in parentOptions" :key="item.id" :value="item.id"
                       :label="item.name"></el-option>
          </el-select>
          <div class="form-tip" v-if="parentSelectDisabled">该分类下已有二级分类，必须保持为一级分类</div>
        </el-form-item>
        <el-form-item label="分类名称" prop="name">
          <el-input v-model="form.name" placeholder="分类名称"></el-input>
        </el-form-item>
        <el-form-item label="分类编码" prop="code">
          <el-input v-model="form.code" placeholder="如 BG、DZ，用于资产编号自动生成" maxlength="20"></el-input>
          <div class="form-tip">建议二级分类填写编码；一级分类可不填</div>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="fromVisible = false">取 消</el-button>
        <el-button type="primary" @click="save">确 定</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: "Category",
  data() {
    return {
      allCategories: [],
      tableData: [],
      name: null,
      fromVisible: false,
      form: {},
      rules: {
        name: [{ required: true, message: '请输入分类名称', trigger: 'blur' }]
      },
      ids: []
    }
  },
  computed: {
    // 可作为上级的分类：一级分类，编辑时排除自身
    parentOptions() {
      return this.allCategories.filter(c => !c.pid && c.id !== this.form.id)
    },
    // 已有二级分类的分类不能再降为二级
    parentSelectDisabled() {
      if (!this.form.id) return false
      return this.allCategories.some(c => c.pid === this.form.id)
    }
  },
  created() {
    this.load()
  },
  methods: {
    load() {
      this.$request.get('/category/selectAll').then(res => {
        if (res.code !== '200') {
          this.$message.error(res.msg || '读取分类失败')
          return
        }
        this.allCategories = res.data || []
        this.buildTree()
      })
    },
    buildTree() {
      const keyword = (this.name || '').trim()
      const parents = this.allCategories.filter(c => !c.pid)
      this.tableData = parents.map(parent => {
        const parentMatched = !keyword || parent.name.indexOf(keyword) >= 0
        const children = this.allCategories.filter(c => c.pid === parent.id
          && (parentMatched || c.name.indexOf(keyword) >= 0))
        return Object.assign({}, parent, { children })
      }).filter(parent => {
        if (!keyword) return true
        return parent.name.indexOf(keyword) >= 0 || parent.children.length > 0
      })
    },
    handleAdd() {
      this.form = { pid: 0, name: '', code: '' }
      this.fromVisible = true
      this.$nextTick(() => this.$refs.formRef && this.$refs.formRef.clearValidate())
    },
    handleAddChild(row) {
      this.form = { pid: row.id, name: '', code: '' }
      this.fromVisible = true
      this.$nextTick(() => this.$refs.formRef && this.$refs.formRef.clearValidate())
    },
    handleEdit(row) {
      this.form = {
        id: row.id,
        pid: row.pid || 0,
        name: row.name,
        code: row.code || ''
      }
      this.fromVisible = true
      this.$nextTick(() => this.$refs.formRef && this.$refs.formRef.clearValidate())
    },
    save() {
      this.$refs.formRef.validate(valid => {
        if (!valid) return
        this.$request({
          url: this.form.id ? '/category/update' : '/category/add',
          method: this.form.id ? 'PUT' : 'POST',
          data: this.form
        }).then(res => {
          if (res.code === '200') {
            this.$message.success('保存成功')
            this.fromVisible = false
            this.load()
          } else {
            this.$message.error(res.msg)
          }
        })
      })
    },
    del(id) {
      this.$confirm('您确定删除吗？有二级分类或已被资产使用的分类不能删除。', '确认删除', { type: 'warning' }).then(() => {
        this.$request.delete('/category/delete/' + id).then(res => {
          if (res.code === '200') {
            this.$message.success('操作成功')
            this.load()
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {})
    },
    handleSelectionChange(rows) {
      this.ids = rows.map(v => v.id)
    },
    delBatch() {
      if (!this.ids.length) {
        this.$message.warning('请选择数据')
        return
      }
      this.$confirm('您确定批量删除这些分类吗？有二级分类或已被资产使用的分类不能删除。', '确认删除', { type: 'warning' }).then(() => {
        this.$request.delete('/category/delete/batch', { data: this.ids }).then(res => {
          if (res.code === '200') {
            this.$message.success('操作成功')
            this.load()
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {})
    },
    reset() {
      this.name = null
      this.load()
    }
  }
}
</script>

<style scoped>
.operation { display: flex; align-items: center; flex-wrap: wrap; }
.tip { color: #909399; font-size: 12px; margin-left: 10px; }
.form-tip { color: #909399; font-size: 12px; line-height: 1.4; margin-top: 4px; }
</style>
