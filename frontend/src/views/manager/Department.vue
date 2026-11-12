<template>
  <div>
    <div class="operation">
      <el-button type="primary" plain @click="handleAdd">新增</el-button>
      <el-button type="success" plain @click="importVisible = true">Excel批量导入</el-button>
    </div>

    <div class="table">
      <el-table row-key="id" default-expand-all :data="tableData" strip>
        <el-table-column prop="companyName" label="所属公司" width="200">
          <template v-slot="scope">
            <span v-if="scope.row.companyName">{{ scope.row.companyName }}</span>
            <span v-else style="color: #f56c6c">未设置</span>
          </template>
        </el-table-column>
        <el-table-column prop="name" label="名称"></el-table-column>
        <el-table-column prop="address" label="地址"></el-table-column>
        <el-table-column prop="pid" label="父级ID"></el-table-column>
        <el-table-column prop="level" label="层级"></el-table-column>
        <el-table-column label="操作" align="center" width="180"  v-if="user.role=='ADMIN'">
          <template v-slot="scope">
            <el-button size="mini" type="primary" plain @click="handleEdit(scope.row)">编辑</el-button>
            <el-button size="mini" type="danger" plain @click="del(scope.row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <el-dialog title="部门信息" :visible.sync="fromVisible" width="40%" :close-on-click-modal="false" destroy-on-close>
      <el-form :model="form" label-width="100px" style="padding-right: 50px" :rules="rules" ref="formRef">
        <el-form-item label="所属公司" prop="companyId">
          <el-select v-model="form.companyId" style="width: 100%" placeholder="请选择所属公司" filterable>
            <el-option v-for="item in companies" :key="item.id" :label="item.name" :value="item.id"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" placeholder="名称"></el-input>
        </el-form-item>
        <el-form-item label="地址" prop="address">
          <el-input v-model="form.address" placeholder="地址"></el-input>
        </el-form-item>
        <el-form-item label="父级" prop="pid">
          <el-select v-model="form.pid" style="width: 100%" clearable placeholder="不选则为一级部门" filterable>
            <el-option v-for="item in parent" :key="item.id" :label="item.label || item.name" :value="item.id"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="层级" prop="level">
          <el-input-number v-model="form.level" :min="1" :max="10" controls-position="right"></el-input-number>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="fromVisible = false">取 消</el-button>
        <el-button type="primary" @click="save">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 部门导入 -->
    <el-dialog title="批量导入部门" :visible.sync="importVisible" width="45%" :close-on-click-modal="false" destroy-on-close>
      <el-alert type="info" :closable="false" show-icon style="margin-bottom: 15px">
        <div slot="default">
          <p>1. 下载模板按格式填写，必填：公司名称、部门名称</p>
          <p>2. 「上级部门」留空表示一级部门；要建下级部门时填写上级部门名称（需在同一公司内）</p>
          <p>3. 公司名称不存在时会自动创建公司；已存在的同名部门会自动跳过</p>
        </div>
      </el-alert>
      <el-button type="primary" @click="downloadTemplate" style="margin-bottom: 15px">下载模板</el-button>
      <el-upload
        :action="$baseUrl + '/department/import'"
        :headers="{ token: user.token }"
        :on-success="handleImportSuccess"
        :on-error="handleImportError"
        accept=".xlsx,.xls"
        :limit="1">
        <el-button type="success">选择文件</el-button>
        <div slot="tip" class="el-upload__tip">只能上传 xlsx/xls 文件</div>
      </el-upload>
      <div slot="footer">
        <el-button @click="importVisible = false">取 消</el-button>
      </div>
    </el-dialog>
  </div>
</template>
<script>
export default {
  name: "Department",
  data() {
    return {
      tableData: [],  // 所有的数据
      pageNum: 1,   // 当前的页码
      pageSize: 10,  // 每页显示的个数
      total: 0,
      name: null,
      fromVisible: false,
      importVisible: false,
      form: {},
      user: JSON.parse(localStorage.getItem('xm-user') || '{}'),
      rules: {
        companyId: [
          { required: true, message: '请选择所属公司', trigger: 'change' }
        ],
        name: [
          { required: true, message: '请输入部门名称', trigger: 'blur' }
        ],
        level: [
          { required: true, message: '请输入层级', trigger: 'blur' }
        ]
      },
      ids: [],
      parent: [],
      companies: []
    }
  },
  created() {
    this.load(1)
    this.loadParent()
    this.loadCompany()
  },
  methods: {
    loadCompany() {
      this.$request.get('/company/selectAll').then(res => {
        this.companies = res.data || []
      })
    },
    loadParent() {
      this.$request.get('/department/selectParent').then(res => {
        this.parent = res.data || []
      })
    },
    handleAdd() {   // 新增数据
      this.form = { level: 1 }  // 新增数据的时候清空数据
      this.fromVisible = true   // 打开弹窗
    },
    handleEdit(row) {   // 编辑数据
      this.form = JSON.parse(JSON.stringify(row))  // 给form对象赋值  注意要深拷贝数据
      this.fromVisible = true   // 打开弹窗
    },
    save() {   // 保存按钮触发的逻辑  它会触发新增或者更新
      this.$refs.formRef.validate((valid) => {
        if (valid) {
          this.$request({
            url: this.form.id ? '/department/update' : '/department/add',
            method: this.form.id ? 'PUT' : 'POST',
            data: this.form
          }).then(res => {
            if (res.code === '200') {  // 表示成功保存
              this.$message.success('保存成功')
              this.load(1)
              this.fromVisible = false
            } else {
              this.$message.error(res.msg)  // 弹出错误的信息
            }
          })
        }
      })
    },
    del(id) {   // 单个删除
      this.$confirm('您确定删除吗？', '确认删除', {type: "warning"}).then(response => {
        this.$request.delete('/department/delete/' + id).then(res => {
          if (res.code === '200') {   // 表示操作成功
            this.$message.success('操作成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)  // 弹出错误的信息
          }
        })
      }).catch(() => {
      })
    },
    handleSelectionChange(rows) {   // 当前选中的所有的行数据
      this.ids = rows.map(v => v.id)
    },
    delBatch() {   // 批量删除
      if (!this.ids.length) {
        this.$message.warning('请选择数据')
        return
      }
      this.$confirm('您确定批量删除这些数据吗？', '确认删除', {type: "warning"}).then(response => {
        this.$request.delete('/department/delete/batch', {data: this.ids}).then(res => {
          if (res.code === '200') {   // 表示操作成功
            this.$message.success('操作成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)  // 弹出错误的信息
          }
        })
      }).catch(() => {
      })
    },
    load(pageNum) {  // 分页查询
      if (pageNum) this.pageNum = pageNum
      this.$request.get('/department/selectTree').then(res => {
        if (res.code === '200') {
          this.tableData = res.data
        } else {
          this.$message.error(res.msg)
        }
      })
    },
    downloadTemplate() {
      window.open(this.$baseUrl + '/department/template?token=' + this.user.token)
    },
    handleImportSuccess(response) {
      if (response.code === '200') {
        this.$message.success(response.data || response.msg || '导入成功')
        this.importVisible = false
        this.load(1)
        this.loadParent()
      } else {
        this.$message.error(response.msg || '导入失败')
      }
    },
    handleImportError() {
      this.$message.error('导入失败，请检查文件格式')
    },
    reset() {
      this.name = null
      this.load(1)
    },
    handleCurrentChange(pageNum) {
      this.load(pageNum)
    },
  }
}
</script>

<style scoped>

</style>