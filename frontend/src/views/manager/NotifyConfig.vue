<template>
  <div>
    <el-tabs v-model="activeTab" type="card">
      <!-- ============ 通知模板 ============ -->
      <el-tab-pane label="通知模板" name="template">
        <el-alert type="info" :closable="false" show-icon style="margin-bottom: 12px"
                  title="申请提交、审批结果都会按模板推送到已启用的群机器人；停用某条目即不再推送该类通知">
          <div slot="default">
            <p>可用变量：{assetsName} {assetsNo} {assetsCode} {category} {num} {money} {scrapType} {reason} {faultDesc} {fromText} {toText} {purchaseNo} {returnDate} {comment} {applicant} {borrowerPhone} {reporterPhone} {approver} {status} {approveComment} {time}</p>
          </div>
        </el-alert>

        <el-table :data="templates" border stripe>
          <el-table-column prop="bizType" label="业务" width="80" align="center"></el-table-column>
          <el-table-column prop="eventName" label="事件" width="140"></el-table-column>
          <el-table-column label="启用" width="90" align="center">
            <template slot-scope="scope">
              <el-switch v-model="scope.row.enabled" @change="toggleTemplate(scope.row)"></el-switch>
            </template>
          </el-table-column>
          <el-table-column prop="title" label="消息标题" min-width="180" show-overflow-tooltip></el-table-column>
          <el-table-column prop="content" label="消息正文" min-width="320">
            <template slot-scope="scope">
              <span style="white-space: pre-wrap">{{ scope.row.content }}</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="90" align="center" fixed="right">
            <template slot-scope="scope">
              <el-button size="mini" type="primary" plain @click="editTemplate(scope.row)">编辑</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <!-- ============ 通知记录 ============ -->
      <el-tab-pane label="通知记录" name="log">
        <div class="search">
          <el-select placeholder="业务类型" style="width: 130px" v-model="query.bizType" clearable @change="load(1)">
            <el-option v-for="b in bizTypes" :key="b" :value="b" :label="b"></el-option>
          </el-select>
          <el-select placeholder="推送结果" style="width: 120px; margin-left: 10px" v-model="query.status" clearable @change="load(1)">
            <el-option value="成功" label="成功"></el-option>
            <el-option value="失败" label="失败"></el-option>
          </el-select>
          <el-input placeholder="标题/内容关键字" style="width: 180px; margin-left: 10px" v-model="query.title" clearable @keyup.enter.native="load(1)"></el-input>
          <el-date-picker style="margin-left: 10px" v-model="query.createTime" type="date" value-format="yyyy-MM-dd"
                          placeholder="推送日期" @change="load(1)"></el-date-picker>
          <el-button type="info" plain style="margin-left: 10px" @click="load(1)">查询</el-button>
          <el-button type="warning" plain style="margin-left: 10px" @click="reset">重置</el-button>
          <el-button type="danger" plain style="margin-left: 10px" :disabled="!ids.length" @click="delBatch">批量删除</el-button>
          <el-button type="info" plain style="margin-left: 10px" @click="clean">清理30天前</el-button>
        </div>

        <el-table :data="logs" border stripe @selection-change="rows => ids = rows.map(v => v.id)">
          <el-table-column type="selection" width="50" align="center"></el-table-column>
          <el-table-column prop="createTime" label="推送时间" width="160"></el-table-column>
          <el-table-column prop="bizType" label="业务" width="80" align="center"></el-table-column>
          <el-table-column prop="eventKey" label="事件" width="150"></el-table-column>
          <el-table-column prop="title" label="标题" min-width="150" show-overflow-tooltip></el-table-column>
          <el-table-column label="内容" min-width="240">
            <template slot-scope="scope">
              <div style="white-space: pre-wrap">{{ scope.row.content }}</div>
            </template>
          </el-table-column>
          <el-table-column prop="robotName" label="机器人" width="130" show-overflow-tooltip></el-table-column>
          <el-table-column label="结果" width="90" align="center">
            <template slot-scope="scope">
              <el-tag v-if="scope.row.status === '成功'" type="success" size="small">成功</el-tag>
              <el-tag v-else type="danger" size="small">{{ scope.row.status }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="response" label="返回" width="180" show-overflow-tooltip></el-table-column>
          <el-table-column label="操作" width="150" align="center" fixed="right">
            <template slot-scope="scope">
              <el-button size="mini" type="success" plain @click="resend(scope.row)">重发</el-button>
              <el-button size="mini" type="danger" plain @click="del(scope.row.id)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>

        <el-pagination class="pager" background layout="total, sizes, prev, pager, next"
          :total="total" :page-size="pageSize" :current-page="pageNum" :page-sizes="[10, 20, 50]"
          style="margin-top: 12px; text-align: right"
          @current-change="onPageChange" @size-change="onSizeChange">
        </el-pagination>
      </el-tab-pane>
    </el-tabs>

    <!-- 编辑模板 -->
    <el-dialog title="编辑通知模板" :visible.sync="tplVisible" width="52%" :close-on-click-modal="false" destroy-on-close>
      <el-form :model="tplForm" label-width="100px" style="padding-right: 30px">
        <el-form-item label="事件">
          <el-input :value="tplForm.eventName" disabled></el-input>
        </el-form-item>
        <el-form-item label="是否启用">
          <el-switch v-model="tplForm.enabled"></el-switch>
        </el-form-item>
        <el-form-item label="消息标题">
          <el-input v-model="tplForm.title" placeholder="消息标题"></el-input>
        </el-form-item>
        <el-form-item label="消息正文">
          <el-input type="textarea" :rows="10" v-model="tplForm.content" placeholder="支持 {变量} 占位符"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="tplVisible = false">取 消</el-button>
        <el-button type="primary" @click="saveTemplate">确 定</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'NotifyConfig',
  data() {
    return {
      activeTab: 'template',
      templates: [],
      tplVisible: false,
      tplForm: {},
      bizTypes: ['入库', '借用', '调拨', '维修', '报废'],
      query: { bizType: null, status: null, title: null, createTime: null },
      logs: [],
      ids: [],
      total: 0,
      pageNum: 1,
      pageSize: 10
    }
  },
  created() {
    this.loadTemplates()
    this.load(1)
  },
  methods: {
    /* ---------- 模板 ---------- */
    loadTemplates() {
      this.$request.get('/notify/templates').then(res => {
        if (res.code === '200') this.templates = res.data || []
        else this.$message.error(res.msg)
      })
    },
    editTemplate(row) {
      this.tplForm = JSON.parse(JSON.stringify(row))
      this.tplVisible = true
    },
    saveTemplate() {
      this.$request.put('/notify/template', this.tplForm).then(res => {
        if (res.code === '200') {
          this.$message.success('保存成功')
          this.tplVisible = false
          this.loadTemplates()
        } else {
          this.$message.error(res.msg)
        }
      })
    },
    toggleTemplate(row) {
      this.$request.put('/notify/template', row).then(res => {
        if (res.code === '200') this.$message.success(row.enabled ? '已启用' : '已停用')
        else {
          this.$message.error(res.msg)
          this.loadTemplates()
        }
      })
    },

    /* ---------- 记录 ---------- */
    load(pageNum) {
      if (pageNum) this.pageNum = pageNum
      this.$request.get('/notify/selectPage', {
        params: {
          pageNum: this.pageNum,
          pageSize: this.pageSize,
          bizType: this.query.bizType,
          status: this.query.status,
          title: this.query.title,
          createTime: this.query.createTime
        }
      }).then(res => {
        if (res.code === '200') {
          this.logs = res.data.list || []
          this.total = res.data.total
        } else {
          this.$message.error(res.msg)
        }
      })
    },
    reset() {
      this.query = { bizType: null, status: null, title: null, createTime: null }
      this.load(1)
    },
    onPageChange(p) {
      this.load(p)
    },
    onSizeChange(s) {
      this.pageSize = s
      this.load(1)
    },
    resend(row) {
      this.$request.post('/notify/resend/' + row.id).then(res => {
        if (res.code === '200' && res.data && res.data.status === '成功') {
          this.$message.success('重发成功')
        } else {
          const r = res.data && res.data.response ? res.data.response : res.msg
          this.$message.error('重发失败：' + r)
        }
        this.load()
      })
    },
    del(id) {
      this.$confirm('确定删除该通知记录吗？', '确认删除', { type: 'warning' }).then(() => {
        this.$request.delete('/notify/delete/' + id).then(res => {
          if (res.code === '200') {
            this.$message.success('删除成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {})
    },
    delBatch() {
      this.$confirm('确定批量删除选中的通知记录吗？', '确认删除', { type: 'warning' }).then(() => {
        this.$request.delete('/notify/delete/batch', { data: this.ids }).then(res => {
          if (res.code === '200') {
            this.$message.success('删除成功')
            this.ids = []
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {})
    },
    clean() {
      this.$confirm('确定清理 30 天前的通知记录吗？', '确认清理', { type: 'warning' }).then(() => {
        this.$request.delete('/notify/clean/30').then(res => {
          if (res.code === '200') {
            this.$message.success('清理完成')
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
</style>
