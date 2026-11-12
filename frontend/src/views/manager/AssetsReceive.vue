<template>
  <div>
    <div class="search">
      <el-input :placeholder="'请输入' + $field('name') + '查询'" style="width: 200px" v-model="assetsName"></el-input>
      <el-button type="info" plain style="margin-left: 10px" @click="load(1)">查询</el-button>
      <el-button type="warning" plain style="margin-left: 10px" @click="reset">重置</el-button>
      <el-button type="primary" plain style="margin-left: 10px" @click="handleAdd">新增借用</el-button>
    </div>

    <div class="table">
      <el-table :data="tableData" strip @selection-change="handleSelectionChange">
        <el-table-column prop="id" label="ID" width="70" align="center" sortable></el-table-column>
        <el-table-column prop="assetsName" :label="$field('name')"></el-table-column>
        <el-table-column prop="assetsNo" :label="$field('no')"></el-table-column>
        <el-table-column label="借用人">
          <template v-slot="scope">{{ scope.row.borrowerName || scope.row.staffName }}</template>
        </el-table-column>
        <el-table-column prop="borrowerPhone" label="联系方式"></el-table-column>
        <el-table-column prop="date" label="借用时间"></el-table-column>
        <el-table-column prop="comment" label="备注"></el-table-column>
        <el-table-column prop="returnDate" label="归还日期">
          <template v-slot="scope">
            <strong style="color: red" v-if="(scope.row.returnStatus === '未归还') && (scope.row.status === '通过') &&
             (new Date(scope.row.returnDate).getTime() < new Date().getTime())">{{ scope.row.returnDate }}</strong>
            <span v-else>{{ scope.row.returnDate }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="审核状态">
          <template v-slot="scope">
            <el-tag type="info" v-if="scope.row.status === '待审核'">待审核</el-tag>
            <el-tag type="success" v-if="scope.row.status === '通过'">通过</el-tag>
            <el-tag type="danger" v-if="scope.row.status === '拒绝'">拒绝</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="returnStatus" label="归还状态">
          <template v-slot="scope">
            <span style="color: #000" v-if="scope.row.returnStatus === '未归还'">未归还</span>
            <span style="color: #049f58" v-if="scope.row.returnStatus === '已归还'">已归还</span>
          </template>
        </el-table-column>
        <el-table-column label="审核" align="center" width="180" v-if="user.role === 'ADMIN'">
          <template v-slot="scope">
            <el-button v-if="scope.row.status === '待审核'" size="mini" type="success" plain @click="changeStatus(scope.row, '通过')">通过</el-button>
            <el-button v-if="scope.row.status === '待审核'" size="mini" type="danger" plain @click="changeStatus(scope.row, '拒绝')">拒绝</el-button>
          </template>
        </el-table-column>
        <el-table-column label="操作" align="center" width="180">
          <template v-slot="scope">
            <el-button size="mini" type="success" plain @click="returnBack(scope.row)"
                       v-if="scope.row.status === '通过' && scope.row.returnStatus === '未归还'">归还</el-button>
            <el-button size="mini" type="danger" plain @click="del(scope.row)"
                       v-if="user.role === 'ADMIN' || scope.row.status !== '通过'">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
        <el-pagination
            background
            @current-change="handleCurrentChange"
            :current-page="pageNum"
            :page-sizes="[5, 10, 20]"
            :page-size="pageSize"
            layout="total, prev, pager, next"
            :total="total">
        </el-pagination>
      </div>
    </div>

    <el-dialog title="新增借用" :visible.sync="fromVisible" width="40%" :close-on-click-modal="false" destroy-on-close>
      <el-form :model="form" label-width="110px" style="padding-right: 50px" :rules="rules" ref="formRef">
        <el-form-item label="借用资产" prop="assetsId">
          <el-select v-model="form.assetsId" filterable placeholder="请选择资产" style="width: 100%">
            <el-option v-for="a in assetsList" :key="a.id" :value="a.id"
                       :label="(a.no || '') + ' ' + (a.name || '')"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="借用人" prop="borrowerName">
          <el-input v-model="form.borrowerName" placeholder="请手动输入借用人姓名"></el-input>
        </el-form-item>
        <el-form-item label="联系方式" prop="borrowerPhone">
          <el-input v-model="form.borrowerPhone" placeholder="请填写 11 位手机号" maxlength="11"></el-input>
        </el-form-item>
        <el-form-item label="归还日期" prop="returnDate">
          <el-date-picker format="yyyy-MM-dd" value-format="yyyy-MM-dd" placeholder="请选择归还日期"
                          v-model="form.returnDate" style="width: 100%"></el-date-picker>
        </el-form-item>
        <el-form-item label="备注" prop="comment">
          <el-input type="textarea" :rows="3" v-model="form.comment" placeholder="备注"></el-input>
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
  assetsName: "AssetsReceive",
  data() {
    return {
      tableData: [],  // 所有的数据
      pageNum: 1,   // 当前的页码
      pageSize: 10,  // 每页显示的个数
      total: 0,
      assetsName: null,
      fromVisible: false,
      form: {},
      user: JSON.parse(localStorage.getItem('xm-user') || '{}'),
      rules: {
        assetsId: [{ required: true, message: '请选择资产', trigger: 'change' }],
        borrowerName: [{ required: true, message: '请填写借用人', trigger: 'blur' }],
        borrowerPhone: [
          { required: true, message: '请填写联系方式', trigger: 'blur' },
          { pattern: /^1[3-9]\d{9}$/, message: '请填写正确的 11 位手机号', trigger: 'blur' }
        ],
        returnDate: [{ required: true, message: '请选择归还日期', trigger: 'change' }]
      },
      assetsList: [],
      ids: []
    }
  },
  created() {
    this.load(1)
    this.loadAssets()
  },
  methods: {
    changeStatus(row, status) {
      this.form = JSON.parse(JSON.stringify(row))
      this.form.status = status
      this.$confirm('您确定'+status+'吗？', '确认审核', {type: "warning"}).then(response => {
        this.$request.put('/assetsReceive/update', this.form).then(res => {
          if (res.code === '200') {
            this.$message.success('审核成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)  // 弹出错误的信息
          }
        })
      }).catch(e => {})
    },
    returnBack(row) {
      const who = row.borrowerName || row.staffName || '该借用人'
      this.$confirm('确认「' + who + '」已归还该资产吗？', '确认归还', { type: 'warning' }).then(() => {
        this.$request.put('/assetsReceive/update', {
          id: row.id,
          assetsId: row.assetsId,
          status: row.status,
          returnStatus: '已归还'
        }).then(res => {
          if (res.code === '200') {
            this.$message.success('归还成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {})
    },
    handleAdd() {   // 新增数据
      this.form = {}  // 新增数据的时候清空数据
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
            url: this.form.id ? '/assetsReceive/update' : '/assetsReceive/add',
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
    del(row) {   // 单个删除（管理员可删除任意状态；已借出未归还的删除后库存自动恢复）
      const borrowed = row.status === '通过' && row.returnStatus === '未归还'
      const tip = borrowed
        ? '该借用单已审核通过且未归还，删除后资产将恢复为可借状态。确定删除吗？'
        : '您确定删除吗？'
      this.$confirm(tip, '确认删除', {type: "warning"}).then(response => {
        this.$request.delete('/assetsReceive/delete/' + row.id).then(res => {
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
        this.$request.delete('/assetsReceive/delete/batch', {data: this.ids}).then(res => {
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
      this.$request.get('/assetsReceive/selectPage', {
        params: {
          pageNum: this.pageNum,
          pageSize: this.pageSize,
          assetsName: this.assetsName,
        }
      }).then(res => {
        if (res.code === '200') {
          this.tableData = res.data?.list
          this.total = res.data?.total
        } else {
          this.$message.error(res.msg)
        }
      })
    },
    loadAssets() {
      this.$request.get('/assets/selectAll').then(res => {
        if (res.code === '200') this.assetsList = res.data || []
      })
    },
    reset() {
      this.assetsName = null
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