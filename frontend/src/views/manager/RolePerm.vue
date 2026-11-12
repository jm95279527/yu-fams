<template>
  <div>
    <div class="btn-div">
      <el-input v-model="name" placeholder="角色名称" class="searchInput" clearable></el-input>
      <el-input v-model="code" placeholder="角色标识" class="searchInput" clearable style="margin-left: 8px"></el-input>
      <el-button type="primary" icon="el-icon-search" style="margin-left: 8px" @click="load(1)">查询</el-button>
      <el-button type="success" icon="el-icon-plus" @click="handleAdd">新增角色</el-button>
    </div>

    <el-table :data="tableData" border stripe v-loading="loading">
      <el-table-column prop="id" label="ID" width="70" align="center"></el-table-column>
      <el-table-column prop="name" label="角色名称" width="150">
        <template slot-scope="scope">
          <el-tag size="small" :type="scope.row.code === 'SUPER_ADMIN' ? 'danger' : ''">{{ scope.row.name }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="code" label="角色标识" width="160"></el-table-column>
      <el-table-column prop="description" label="描述" min-width="220" show-overflow-tooltip></el-table-column>
      <el-table-column prop="adminCount" label="管理员数" width="90" align="center"></el-table-column>
      <el-table-column prop="sort" label="排序" width="70" align="center"></el-table-column>
      <el-table-column label="操作" width="280" fixed="right" align="center">
        <template slot-scope="scope">
          <el-button type="primary" icon="el-icon-key" size="mini" @click="openPerm(scope.row)">分配权限</el-button>
          <el-button type="warning" icon="el-icon-edit" size="mini" @click="handleEdit(scope.row)">编辑</el-button>
          <el-button v-if="scope.row.code !== 'SUPER_ADMIN'" type="danger" icon="el-icon-delete" size="mini"
                     @click="del(scope.row.id)">删除</el-button>
          <el-tooltip v-else content="内置超级管理员角色不可删除" placement="top">
            <el-button type="danger" icon="el-icon-delete" size="mini" disabled></el-button>
          </el-tooltip>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination
      class="pager"
      background
      layout="prev, pager, next, total"
      :total="total"
      :page-size="pageSize"
      :current-page="pageNum"
      @current-change="onPageChange">
    </el-pagination>

    <!-- 新增/编辑角色 -->
    <el-dialog :title="form.id ? '编辑角色' : '新增角色'" :visible.sync="formVisible" width="520px" @closed="onFormClosed">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="90px">
        <el-form-item label="角色名称" prop="name">
          <el-input v-model="form.name" placeholder="如：资产管理员"></el-input>
        </el-form-item>
        <el-form-item label="角色标识" prop="code">
          <el-input v-model="form.code" placeholder="如：ASSET_ADMIN（大写字母/数字/下划线）"
                    :disabled="form._codeLocked"></el-input>
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort" :min="0" :max="999" controls-position="right"></el-input-number>
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="form.description" type="textarea" :rows="3" maxlength="200" show-word-limit
                    placeholder="角色职责与权限范围说明"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="formVisible = false">取消</el-button>
        <el-button type="primary" @click="save">确定</el-button>
      </div>
    </el-dialog>

    <!-- 分配菜单权限 -->
    <el-dialog :title="'分配菜单权限 — ' + (permRole.name || '')" :visible.sync="permVisible" width="520px" @closed="permTree = []">
      <el-alert v-if="permRole.code === 'SUPER_ADMIN'" type="warning" :closable="false" show-icon
                title="超级管理员默认拥有系统全部菜单，无需勾选" style="margin-bottom: 12px"></el-alert>
      <div v-loading="permLoading" style="max-height: 460px; overflow-y: auto">
        <el-tree
          ref="permTreeRef"
          :data="permTree"
          show-checkbox
          node-key="id"
          :props="{ label: 'name', children: 'children' }"
          :default-expand-all="true"
          :disabled="permRole.code === 'SUPER_ADMIN'">
        </el-tree>
      </div>
      <div slot="footer">
        <el-button @click="permVisible = false">取消</el-button>
        <el-button type="primary" :disabled="permRole.code === 'SUPER_ADMIN'" @click="savePerm">保存权限</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'RolePerm',
  data() {
    return {
      tableData: [],
      total: 0,
      pageNum: 1,
      pageSize: 10,
      name: '',
      code: '',
      loading: false,
      // 角色表单
      formVisible: false,
      form: {},
      rules: {
        name: [{ required: true, message: '请输入角色名称', trigger: 'blur' }],
        code: [
          { required: true, message: '请输入角色标识', trigger: 'blur' },
          { pattern: /^[A-Z][A-Z0-9_]*$/, message: '须以大写字母开头，仅含大写字母/数字/下划线', trigger: 'blur' }
        ]
      },
      // 授权
      permVisible: false,
      permLoading: false,
      permRole: {},
      permTree: []
    }
  },
  created() {
    this.load()
  },
  methods: {
    load(pageNum) {
      if (pageNum) this.pageNum = pageNum
      this.loading = true
      this.$request.get('/role/selectPage', {
        params: { pageNum: this.pageNum, pageSize: this.pageSize, name: this.name, code: this.code }
      }).then(res => {
        this.tableData = res.data.list || []
        this.total = res.data.total || 0
      }).finally(() => { this.loading = false })
    },
    onPageChange(p) { this.load(p) },
    // ---------- 新增/编辑 ----------
    handleAdd() {
      this.form = { name: '', code: '', description: '', sort: 0 }
      this.formVisible = true
      this.$nextTick(() => this.$refs.formRef && this.$refs.formRef.clearValidate())
    },
    handleEdit(row) {
      this.form = { id: row.id, name: row.name, code: row.code, description: row.description, sort: row.sort }
      // 超级管理员标识锁定不可改
      this.form._codeLocked = row.code === 'SUPER_ADMIN'
      this.formVisible = true
      this.$nextTick(() => this.$refs.formRef && this.$refs.formRef.clearValidate())
    },
    onFormClosed() {
      this.form = {}
      if (this.$refs.formRef) this.$refs.formRef.clearValidate()
    },
    save() {
      this.$refs.formRef.validate(valid => {
        if (!valid) return
        const data = {
          id: this.form.id,
          name: this.form.name,
          code: this.form.code,
          description: this.form.description,
          sort: this.form.sort
        }
        const req = this.form.id
          ? this.$request.put('/role/update', data)
          : this.$request.post('/role/add', data)
        req.then(() => {
          this.$message.success('保存成功')
          this.formVisible = false
          this.load()
        })
      })
    },
    del(id) {
      this.$confirm('确认删除该角色？删除后不可恢复。', '提示', { type: 'warning' }).then(() => {
        this.$request.delete('/role/delete/' + id).then(() => {
          this.$message.success('删除成功')
          this.load()
        })
      }).catch(() => {})
    },
    // ---------- 分配权限 ----------
    openPerm(row) {
      this.permRole = { ...row }
      this.permVisible = true
      this.permLoading = true
      // 先加载菜单树，再加载角色已有菜单并回显
      Promise.all([
        this.$request.get('/menu/tree'),
        this.$request.get('/role/selectById/' + row.id)
      ]).then(([menuRes, roleRes]) => {
        this.permTree = menuRes.data || []
        const menuIds = (roleRes.data && roleRes.data.menuIds) || []
        this.$nextTick(() => {
          this.$refs.permTreeRef.setCheckedKeys(menuIds)
        })
      }).finally(() => { this.permLoading = false })
    },
    savePerm() {
      // 勾选的叶子/全选节点 + 半选的父级目录，一并提交保证树完整
      const checked = this.$refs.permTreeRef.getCheckedKeys()
      const halfChecked = this.$refs.permTreeRef.getHalfCheckedKeys()
      const menuIds = checked.concat(halfChecked)
      this.$request.post('/role/assignMenus', { roleId: this.permRole.id, menuIds }).then(() => {
        this.$message.success('权限保存成功')
        this.permVisible = false
        this.load()
      })
    }
  }
}
</script>

<style scoped>
.btn-div { margin: 10px 0; display: flex; align-items: center; flex-wrap: wrap; }
.searchInput { width: 170px; }
.pager { margin-top: 15px; text-align: right; }
</style>
