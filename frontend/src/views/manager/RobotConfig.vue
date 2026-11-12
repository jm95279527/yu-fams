<template>
  <div>
    <div class="search">
      <el-input placeholder="机器人名称" style="width: 180px" v-model="query.name" clearable @keyup.enter.native="load"></el-input>
      <el-button type="info" plain style="margin-left: 10px" @click="load">查询</el-button>
      <el-button type="warning" plain style="margin-left: 10px" @click="reset">重置</el-button>
      <el-button type="primary" plain style="margin-left: 10px" @click="handleAdd">新增机器人</el-button>
    </div>

    <el-alert type="info" :closable="false" show-icon style="margin-bottom: 12px"
              title="在企业微信群里添加「群机器人」，把生成的 Webhook 地址填到下面即可；若机器人开启了「加签」，请一并填写加签密钥">
    </el-alert>

    <el-table :data="tableData" border stripe>
      <el-table-column prop="name" label="机器人名称" min-width="140"></el-table-column>
      <el-table-column label="类型" width="110" align="center">
        <template slot-scope="scope">
          <el-tag size="small" type="success">{{ scope.row.type === 'wechat' ? '企业微信' : scope.row.type }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="webhookUrl" label="Webhook 地址" min-width="320" show-overflow-tooltip></el-table-column>
      <el-table-column label="加签" width="80" align="center">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.secret" size="small" type="warning">已开</el-tag>
          <span v-else style="color:#c0c4cc">未开</span>
        </template>
      </el-table-column>
      <el-table-column label="启用" width="90" align="center">
        <template slot-scope="scope">
          <el-switch v-model="scope.row.enabled" @change="toggleEnabled(scope.row)"></el-switch>
        </template>
      </el-table-column>
      <el-table-column prop="remark" label="备注" min-width="140" show-overflow-tooltip></el-table-column>
      <el-table-column label="操作" width="200" align="center" fixed="right">
        <template slot-scope="scope">
          <el-button size="mini" type="success" plain @click="testSend(scope.row)">测试</el-button>
          <el-button size="mini" type="primary" plain @click="handleEdit(scope.row)">编辑</el-button>
          <el-button size="mini" type="danger" plain @click="del(scope.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, prev, pager, next"
      :total="tableData.length" :page-size="10" :current-page="1" style="margin-top: 12px; text-align: right">
    </el-pagination>

    <!-- 新增/编辑 -->
    <el-dialog :title="form.id ? '编辑机器人' : '新增机器人'" :visible.sync="formVisible" width="46%" :close-on-click-modal="false" destroy-on-close>
      <el-form :model="form" label-width="110px" :rules="rules" ref="formRef" style="padding-right: 30px">
        <el-form-item label="机器人名称" prop="name">
          <el-input v-model="form.name" placeholder="如：资产运维群机器人"></el-input>
        </el-form-item>
        <el-form-item label="Webhook 地址" prop="webhookUrl">
          <el-input type="textarea" :rows="3" v-model="form.webhookUrl"
                    placeholder="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxxxxxxx"></el-input>
        </el-form-item>
        <el-form-item label="加签密钥" prop="secret">
          <el-input v-model="form.secret" show-password placeholder="机器人开启「加签」时填写，未开启可留空"></el-input>
        </el-form-item>
        <el-form-item label="是否启用">
          <el-switch v-model="form.enabled"></el-switch>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" placeholder="备注"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="formVisible = false">取 消</el-button>
        <el-button type="primary" @click="save">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 测试发送 -->
    <el-dialog title="测试发送" :visible.sync="testVisible" width="46%" :close-on-click-modal="false" destroy-on-close>
      <el-form label-width="110px" style="padding-right: 30px">
        <el-form-item label="机器人">
          <el-input :value="testForm.name" disabled></el-input>
        </el-form-item>
        <el-form-item label="消息内容">
          <el-input type="textarea" :rows="5" v-model="testForm.message"
                    placeholder="留空则发送默认的连通性测试消息"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="testVisible = false">关 闭</el-button>
        <el-button type="primary" :loading="testing" @click="doTest">发 送</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'RobotConfig',
  data() {
    return {
      query: { name: null },
      tableData: [],
      formVisible: false,
      form: {},
      rules: {
        name: [{ required: true, message: '请输入机器人名称', trigger: 'blur' }],
        webhookUrl: [{ required: true, message: '请输入 Webhook 地址', trigger: 'blur' }]
      },
      testVisible: false,
      testing: false,
      testForm: { id: null, name: '', message: '' }
    }
  },
  created() {
    this.load()
  },
  methods: {
    load() {
      this.$request.get('/robotConfig/selectAll', { params: this.query }).then(res => {
        if (res.code === '200') this.tableData = res.data || []
        else this.$message.error(res.msg)
      })
    },
    reset() {
      this.query = { name: null }
      this.load()
    },
    handleAdd() {
      this.form = { type: 'wechat', enabled: true }
      this.formVisible = true
    },
    handleEdit(row) {
      this.form = JSON.parse(JSON.stringify(row))
      this.formVisible = true
    },
    save() {
      this.$refs.formRef.validate(valid => {
        if (!valid) return
        const url = this.form.id ? '/robotConfig/update' : '/robotConfig/add'
        const method = this.form.id ? 'put' : 'post'
        this.$request({ url, method, data: this.form }).then(res => {
          if (res.code === '200') {
            this.$message.success('保存成功')
            this.formVisible = false
            this.load()
          } else {
            this.$message.error(res.msg)
          }
        })
      })
    },
    del(row) {
      this.$confirm('确定删除机器人「' + row.name + '」吗？', '确认删除', { type: 'warning' }).then(() => {
        this.$request.delete('/robotConfig/delete/' + row.id).then(res => {
          if (res.code === '200') {
            this.$message.success('删除成功')
            this.load()
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {})
    },
    toggleEnabled(row) {
      this.$request.put('/robotConfig/update', row).then(res => {
        if (res.code === '200') this.$message.success(row.enabled ? '已启用' : '已停用')
        else {
          this.$message.error(res.msg)
          this.load()
        }
      })
    },
    testSend(row) {
      this.testForm = { id: row.id, name: row.name, message: '' }
      this.testVisible = true
    },
    doTest() {
      this.testing = true
      this.$request.post('/robotConfig/test/' + this.testForm.id, null, {
        params: { message: this.testForm.message }
      }).then(res => {
        this.testing = false
        if (res.code === '200' && res.data && res.data.status === '成功') {
          this.$message.success('发送成功，请到群里查看')
        } else {
          const r = res.data && res.data.response ? res.data.response : res.msg
          this.$message.error('发送失败：' + r)
        }
      }).catch(() => { this.testing = false })
    }
  }
}
</script>

<style scoped>
</style>
