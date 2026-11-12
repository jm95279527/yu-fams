<template>
  <div>
    <div class="search">
      <el-input placeholder="请输入账号" style="width: 140px" v-model="query.username" clearable></el-input>
      <el-input placeholder="请输入工号" style="width: 140px; margin-left: 10px" v-model="query.empNo" clearable></el-input>
      <el-input placeholder="请输入姓名" style="width: 140px; margin-left: 10px" v-model="query.name" clearable></el-input>
      <el-input placeholder="请输入手机号" style="width: 150px; margin-left: 10px" v-model="query.phone" clearable></el-input>
      <el-select placeholder="请选择部门" style="width: 150px; margin-left: 10px" v-model="query.departmentId" clearable>
        <el-option v-for="d in departments" :key="d.id" :label="d.label || d.name" :value="d.id"></el-option>
      </el-select>
      <el-select placeholder="请选择状态" style="width: 110px; margin-left: 10px" v-model="query.status" clearable>
        <el-option label="在职" value="在职"></el-option>
        <el-option label="离职" value="离职"></el-option>
      </el-select>
      <el-button type="info" plain style="margin-left: 10px" @click="load(1)">查询</el-button>
      <el-button type="warning" plain style="margin-left: 10px" @click="reset">重置</el-button>
    </div>

    <div class="operation">
      <el-button type="primary" plain @click="handleAdd">新增</el-button>
      <el-button type="success" plain @click="importVisible = true">Excel批量导入</el-button>
      <el-button type="info" plain @click="leaveBatch">批量离职</el-button>
      <el-button type="danger" plain @click="delBatch">批量删除</el-button>
      <el-button type="warning" plain icon="el-icon-download" @click="exportData">导出</el-button>
    </div>

    <div class="table">
      <el-table :data="tableData" stripe @selection-change="handleSelectionChange">
        <el-table-column type="selection" width="55" align="center"></el-table-column>

        <el-table-column prop="empNo" label="工号" width="100"></el-table-column>
        <el-table-column prop="username" label="账号" width="110"></el-table-column>
        <el-table-column label="密码" width="80">
          <template v-slot="scope">
            ********
          </template>
        </el-table-column>
        <el-table-column prop="name" label="姓名" width="90"></el-table-column>
        <el-table-column prop="gender" label="性别" width="65"></el-table-column>
        <el-table-column prop="phone" label="电话" width="120"></el-table-column>
        <el-table-column prop="email" label="邮箱" width="170" show-overflow-tooltip></el-table-column>
        <el-table-column prop="departmentName" label="部门" width="100"></el-table-column>
        <el-table-column prop="position" label="职位" width="100"></el-table-column>
        <el-table-column prop="entryDate" label="入职日期" width="105"></el-table-column>
        <el-table-column label="状态" width="80">
          <template v-slot="scope">
            <el-tag :type="scope.row.status === '离职' ? 'danger' : 'success'" size="small">
              {{ scope.row.status || '在职' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="头像" width="70">
          <template v-slot="scope">
            <el-image style="width: 40px; height: 40px; border-radius: 50%" v-if="scope.row.avatar"
                      :src="scope.row.avatar" :preview-src-list="[scope.row.avatar]"></el-image>
          </template>
        </el-table-column>
        <el-table-column label="操作" align="center" width="300" fixed="right">
          <template v-slot="scope">
            <el-button size="mini" type="primary" plain @click="handleEdit(scope.row)">编辑</el-button>
            <el-button size="mini" type="warning" plain @click="resetPwd(scope.row)">重置密码</el-button>
            <el-button size="mini" type="danger" plain @click="leave(scope.row)"
                       v-if="scope.row.status !== '离职'">离职</el-button>
            <el-button size="mini" type="danger" plain @click="del(scope.row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
        <el-pagination
            background
            @current-change="handleCurrentChange"
            @size-change="handleSizeChange"
            :current-page="pageNum"
            :page-sizes="[10, 20, 50]"
            :page-size="pageSize"
            layout="total, sizes, prev, pager, next"
            :total="total">
        </el-pagination>
      </div>
    </div>


    <el-dialog title="员工信息" :visible.sync="fromVisible" width="60%" :close-on-click-modal="false" destroy-on-close>
      <el-form :model="form" label-width="100px" :rules="rules" ref="formRef">
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item label="工号">
              <el-input v-model="form.empNo" placeholder="请输入工号"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="用户名" prop="username">
              <el-input v-model="form.username" placeholder="登录账号"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="密码" prop="password">
              <el-input v-model="form.password" :placeholder="form.id ? '留空则不修改密码' : '留空则使用默认密码 123'"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="姓名" prop="name">
              <el-input v-model="form.name" placeholder="姓名"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="性别">
              <el-select v-model="form.gender" placeholder="请选择性别" style="width: 100%" clearable>
                <el-option label="男" value="男"></el-option>
                <el-option label="女" value="女"></el-option>
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="电话" prop="phone">
              <el-input v-model="form.phone" placeholder="电话"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="邮箱">
              <el-input v-model="form.email" placeholder="邮箱"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="身份证号" prop="idCard">
              <el-input v-model="form.idCard" placeholder="身份证号" maxlength="18"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="出生日期">
              <el-date-picker v-model="form.birthDate" type="date" placeholder="选择出生日期"
                              value-format="yyyy-MM-dd" style="width: 100%"></el-date-picker>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="学历">
              <el-select v-model="form.education" placeholder="请选择学历" style="width: 100%" clearable>
                <el-option label="高中" value="高中"></el-option>
                <el-option label="大专" value="大专"></el-option>
                <el-option label="本科" value="本科"></el-option>
                <el-option label="硕士" value="硕士"></el-option>
                <el-option label="博士" value="博士"></el-option>
                <el-option label="其他" value="其他"></el-option>
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="部门">
              <el-select v-model="form.departmentId" placeholder="请选择部门" style="width: 100%" clearable>
                <el-option v-for="d in departments" :key="d.id" :label="d.label || d.name" :value="d.id"></el-option>
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="职位">
              <el-input v-model="form.position" placeholder="如：资产管理员、工程师"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="入职日期">
              <el-date-picker v-model="form.entryDate" type="date" placeholder="选择入职日期"
                              value-format="yyyy-MM-dd" style="width: 100%"></el-date-picker>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="状态">
              <el-select v-model="form.status" placeholder="请选择状态" style="width: 100%">
                <el-option label="在职" value="在职"></el-option>
                <el-option label="离职" value="离职"></el-option>
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12" v-if="form.status === '离职'">
            <el-form-item label="离职日期">
              <el-date-picker v-model="form.leaveDate" type="date" placeholder="不填默认为今天"
                              value-format="yyyy-MM-dd" style="width: 100%"></el-date-picker>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="籍贯">
              <el-input v-model="form.nativePlace" placeholder="籍贯"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="家庭住址">
              <el-input v-model="form.address" placeholder="家庭住址"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="紧急联系人">
              <el-input v-model="form.emergencyContact" placeholder="紧急联系人"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="紧急联系电话" prop="emergencyPhone">
              <el-input v-model="form.emergencyPhone" placeholder="紧急联系电话"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="头像">
              <el-upload
                  class="avatar-uploader"
                  :action="$baseUrl + '/files/upload'"
                  :headers="{ token: user.token }"
                  list-type="picture"
                  :show-file-list="false"
                  :on-success="handleAvatarSuccess"
              >
                <el-button type="primary">上传头像</el-button>
                <span v-if="form.avatar" style="margin-left: 10px; color: #67c23a">已上传</span>
              </el-upload>
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="备注">
              <el-input type="textarea" v-model="form.remark" :rows="2" placeholder="备注"></el-input>
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>

      <div slot="footer" class="dialog-footer">
        <el-button @click="fromVisible = false">取 消</el-button>
        <el-button type="primary" @click="save">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 员工批量导入 -->
    <el-dialog title="批量导入员工" :visible.sync="importVisible" width="45%" :close-on-click-modal="false" destroy-on-close>
      <el-alert type="info" :closable="false" show-icon style="margin-bottom: 15px">
        <div slot="default">
          <p>1. 下载模板按格式填写，必填：姓名（账号留空时自动用工号作为登录账号）</p>
          <p>2. 「公司」「部门」按基础资料里的名称填写；多个公司有同名部门时，必须填「公司」以区分</p>
          <p>3. 账号或工号已存在的员工会自动跳过，可重复导入</p>
          <p>4. 导入的员工登录密码统一为系统默认密码 123</p>
        </div>
      </el-alert>
      <el-button type="primary" @click="downloadTemplate" style="margin-bottom: 15px">下载模板</el-button>
      <el-upload
        :action="$baseUrl + '/staff/import'"
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
  name: "Staff",
  data() {
    return {
      tableData: [],
      pageNum: 1,
      pageSize: 10,
      total: 0,
      query: {
        username: null,
        empNo: null,
        name: null,
        phone: null,
        departmentId: null,
        status: null
      },
      departments: [],
      fromVisible: false,
      importVisible: false,
      form: {},
      user: JSON.parse(localStorage.getItem('xm-user') || '{}'),
      rules: {
        username: [
          {required: true, message: '请输入登录账号', trigger: 'blur'},
        ],
        name: [
          {required: true, message: '请输入姓名', trigger: 'blur'},
        ],
        password: [
          {validator: (rule, value, callback) => {
            // 留空=默认密码123/不修改；显式输入123也允许；其余自设密码须有强度
            if (value && value !== '123' && !/^(?=.*[A-Za-z])(?=.*\d)\S{6,20}$/.test(value)) {
              callback(new Error('密码需6-20位且同时包含字母和数字'))
            } else {
              callback()
            }
          }, trigger: 'blur'}
        ],
        phone: [
          {validator: (rule, value, callback) => {
            if (value && !/^1[3-9]\d{9}$/.test(value)) {
              callback(new Error('手机号格式不正确'))
            } else {
              callback()
            }
          }, trigger: 'blur'}
        ],
        idCard: [
          {validator: (rule, value, callback) => {
            if (value && !/^(\d{15}|\d{17}[\dXx])$/.test(value)) {
              callback(new Error('身份证号格式不正确'))
            } else {
              callback()
            }
          }, trigger: 'blur'}
        ],
        emergencyPhone: [
          {validator: (rule, value, callback) => {
            if (value && !/^1[3-9]\d{9}$/.test(value)) {
              callback(new Error('手机号格式不正确'))
            } else {
              callback()
            }
          }, trigger: 'blur'}
        ]
      },
      ids: []
    }
  },
  created() {
    this.loadDepartments()
    this.load(1)
  },
  methods: {
    loadDepartments() {
      this.$request.get('/department/selectAll').then(res => {
        if (res.code === '200') {
          this.departments = res.data || []
        }
      })
    },
    handleAdd() {
      this.form = {
        status: '在职'
      }
      this.fromVisible = true
      this.$nextTick(() => {
        this.$refs.formRef && this.$refs.formRef.clearValidate()
      })
    },
    handleEdit(row) {
      this.form = JSON.parse(JSON.stringify(row))
      this.form.password = ''
      this.fromVisible = true
      this.$nextTick(() => {
        this.$refs.formRef && this.$refs.formRef.clearValidate()
      })
    },
    save() {
      this.$refs.formRef.validate((valid) => {
        if (!valid) {
          return
        }
        // 编辑时密码留空则不修改
        const payload = JSON.parse(JSON.stringify(this.form))
        if (payload.id && !payload.password) {
          delete payload.password
        }
        this.$request({
          url: payload.id ? '/staff/update' : '/staff/add',
          method: payload.id ? 'PUT' : 'POST',
          data: payload
        }).then(res => {
          if (res.code === '200') {
            this.$message.success('保存成功')
            this.load(1)
            this.fromVisible = false
          } else {
            this.$message.error(res.msg)
          }
        })
      })
    },
    resetPwd(row) {
      this.$confirm('确定将员工「' + row.name + '」的密码重置为默认密码 123 吗？', '重置密码', {type: "warning"}).then(() => {
        this.$request.put('/staff/resetPassword/' + row.id).then(res => {
          if (res.code === '200') {
            this.$message.success('密码已重置为默认密码：123')
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {
      })
    },
    del(id) {
      this.$confirm('您确定删除吗？存在资产/业务关联的员工不能删除。', '确认删除', {type: "warning"}).then(() => {
        this.$request.delete('/staff/delete/' + id).then(res => {
          if (res.code === '200') {
            this.$message.success('操作成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {
      })
    },
    handleSelectionChange(rows) {
      this.ids = rows.map(v => v.id)
    },
    leave(row) {   // 一键离职
      this.$confirm('确定为员工「' + row.name + '」办理离职吗？离职后该账号将无法登录，历史资产与记录会保留并标注（离职）。', '一键离职', {type: "warning"}).then(() => {
        this.$request.put('/staff/leave/' + row.id).then(res => {
          if (res.code === '200') {
            this.$message.success('已办理离职')
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {
      })
    },
    leaveBatch() {   // 批量离职
      if (!this.ids.length) {
        this.$message.warning('请先勾选员工')
        return
      }
      this.$confirm('确定为选中的 ' + this.ids.length + ' 名员工批量办理离职吗？已离职的会自动跳过。', '批量离职', {type: "warning"}).then(() => {
        this.$request.put('/staff/leave/batch', this.ids).then(res => {
          if (res.code === '200') {
            this.$message.success(res.data || '操作成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {
      })
    },
    downloadTemplate() {
      window.open(this.$baseUrl + '/staff/template?token=' + this.user.token)
    },
    handleImportSuccess(response) {
      if (response.code === '200') {
        this.$message.success(response.data || response.msg || '导入成功')
        this.importVisible = false
        this.load(1)
      } else {
        this.$message.error(response.msg || '导入失败')
      }
    },
    handleImportError() {
      this.$message.error('导入失败，请检查文件格式')
    },
    delBatch() {
      if (!this.ids.length) {
        this.$message.warning('请选择数据')
        return
      }
      this.$confirm('您确定批量删除这些数据吗？存在资产/业务关联的员工不能删除。', '确认删除', {type: "warning"}).then(() => {
        this.$request.delete('/staff/delete/batch', {data: this.ids}).then(res => {
          if (res.code === '200') {
            this.$message.success('操作成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {
      })
    },
    load(pageNum) {
      if (pageNum) this.pageNum = pageNum
      this.$request.get('/staff/selectPage', {
        params: {
          pageNum: this.pageNum,
          pageSize: this.pageSize,
          username: this.query.username,
          empNo: this.query.empNo,
          name: this.query.name,
          phone: this.query.phone,
          departmentId: this.query.departmentId,
          status: this.query.status
        }
      }).then(res => {
        this.tableData = res.data?.list
        this.total = res.data?.total
      })
    },
    reset() {
      this.query = {username: null, empNo: null, name: null, phone: null, departmentId: null, status: null}
      this.load(1)
    },
    handleCurrentChange(pageNum) {
      this.load(pageNum)
    },
    handleSizeChange(size) {
      this.pageSize = size
      this.load(1)
    },
    handleAvatarSuccess(response) {
      this.$set(this.form, 'avatar', response.data)
    },
    exportData() {
      const user = JSON.parse(localStorage.getItem('xm-user') || '{}')
      this.$request({
        url: '/staff/export',
        method: 'get',
        params: {
          username: this.query.username,
          empNo: this.query.empNo,
          name: this.query.name,
          phone: this.query.phone,
          departmentId: this.query.departmentId,
          status: this.query.status
        },
        responseType: 'blob',
        headers: {token: user.token}
      }).then(res => {
        const blob = new Blob([res.data], {type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'})
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = '员工信息表.xlsx'
        a.click()
        URL.revokeObjectURL(url)
      })
    }
  }
}
</script>

<style scoped>

</style>
