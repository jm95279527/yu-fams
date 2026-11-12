<template>
  <div>
    <div class="btn-div">
      <el-input v-model="assetsName" :placeholder="$field('name')" class="searchInput" clearable></el-input>
      <el-input v-model="assetsNo" :placeholder="$field('no')" class="searchInput" clearable style="margin-left: 8px"></el-input>
      <el-select v-model="scrapType" placeholder="报废类型" class="searchInput" clearable style="margin-left: 8px; width: 130px">
        <el-option v-for="s in scrapTypeOptions" :key="s" :label="s" :value="s"></el-option>
      </el-select>
      <el-select v-model="status" placeholder="状态" class="searchInput" clearable style="margin-left: 8px; width: 120px">
        <el-option v-for="s in statusOptions" :key="s" :label="s" :value="s"></el-option>
      </el-select>
      <el-button type="primary" icon="el-icon-search" style="margin-left: 8px" @click="load(1)">查询</el-button>
      <el-button type="success" icon="el-icon-plus" @click="add">申请报废</el-button>
      <el-button type="danger" plain :disabled="!ids.length" @click="delBatch" v-if="user.role === 'ADMIN'">批量删除</el-button>
      <el-button type="warning" plain icon="el-icon-download" @click="exportData">导出</el-button>
    </div>

    <el-table :data="tableData" border @selection-change="selectChange" stripe>
      <el-table-column type="selection" width="50" align="center" v-if="user.role === 'ADMIN'"></el-table-column>
      <el-table-column prop="assetsNo" :label="$field('no')" width="140"></el-table-column>
      <el-table-column prop="assetsName" :label="$field('name')" width="150" show-overflow-tooltip></el-table-column>
      <el-table-column prop="category" :label="$field('category')" width="100" show-overflow-tooltip></el-table-column>
      <el-table-column :label="$field('money') + '/' + $field('depreciate')" width="130" align="right">
        <template slot-scope="scope">
          <div>￥{{ scope.row.money || 0 }}</div>
          <div style="color: #909399; font-size: 12px">{{ $field('depreciate') }}：￥{{ scope.row.depreciate || 0 }}</div>
        </template>
      </el-table-column>
      <el-table-column :label="$field('departmentName') + '/' + $field('staffName') + '/' + $field('location')" min-width="200">
        <template slot-scope="scope">
          <div>{{ scope.row.departmentName || '-' }} / {{ scope.row.staffName || '-' }}</div>
          <div style="color: #909399; font-size: 12px">{{ scope.row.location || '-' }}</div>
        </template>
      </el-table-column>
      <el-table-column prop="scrapType" label="报废类型" width="100" align="center"></el-table-column>
      <el-table-column prop="reason" label="报废原因" min-width="140" show-overflow-tooltip></el-table-column>
      <el-table-column label="残值" width="90" align="right">
        <template slot-scope="scope">￥{{ scope.row.residualValue || 0 }}</template>
      </el-table-column>
      <el-table-column prop="applicantName" label="申请人" width="90"></el-table-column>
      <el-table-column prop="applyTime" label="申请时间" width="160"></el-table-column>
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="scope">
          <el-tag :type="statusTagType(scope.row.status)" size="small">{{ scope.row.status }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="230" fixed="right" align="center">
        <template slot-scope="scope">
          <el-button type="primary" icon="el-icon-view" size="mini" @click="showDetail(scope.row)">详情</el-button>
          <el-button type="info" icon="el-icon-time" size="mini" @click="showHistory(scope.row)">记录</el-button>
          <template v-if="user.role === 'ADMIN' && scope.row.status === '待审批'">
            <el-button type="success" icon="el-icon-check" size="mini" @click="audit(scope.row, true)">通过</el-button>
            <el-button type="danger" icon="el-icon-close" size="mini" @click="audit(scope.row, false)">驳回</el-button>
          </template>
          <el-button v-if="scope.row.status === '待审批' || scope.row.status === '已拒绝'" type="warning" icon="el-icon-edit" size="mini" @click="edit(scope.row)">编辑</el-button>
          <el-button v-if="user.role === 'ADMIN' || (scope.row.status !== '已报废')" type="text" size="mini" @click="del(scope.row.id)">删除</el-button>
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

    <!-- 申请/编辑 弹窗 -->
    <el-dialog :title="form._wasRejected ? '驳回后重新提交' : (form.id ? '编辑报废申请' : '资产报废申请')" :visible.sync="formVisible" width="720px" @closed="onFormClosed">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-divider content-position="left">选择资产</el-divider>
        <el-form-item label="报废资产" prop="assetsId">
          <el-select v-model="form.assetsId" filterable :placeholder="'输入' + $field('no') + '/' + $field('name') + '搜索'" style="width: 100%"
                     :disabled="!!form.id" @change="onAssetChange">
            <el-option v-for="a in assetOptions" :key="a.id"
                       :label="a.no + ' ' + a.name + '（' + (a.departmentName || '未分配') + '/' + (a.staffName || '无') + '）'"
                       :value="a.id"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="当前信息" v-if="currentAsset">
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item :label="$field('category')">{{ currentAsset.category || '-' }}</el-descriptions-item>
            <el-descriptions-item :label="$field('model')">{{ currentAsset.model || '-' }}</el-descriptions-item>
            <el-descriptions-item :label="$field('money')">￥{{ currentAsset.money || 0 }}</el-descriptions-item>
            <el-descriptions-item :label="$field('depreciate')">￥{{ currentAsset.depreciate || 0 }}</el-descriptions-item>
            <el-descriptions-item :label="$field('departmentName')">{{ currentAsset.departmentName || '-' }}</el-descriptions-item>
            <el-descriptions-item :label="$field('staffName')">{{ currentAsset.staffName || '-' }}</el-descriptions-item>
            <el-descriptions-item :label="$field('location')" :span="2">{{ currentAsset.location || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-form-item>

        <el-divider content-position="left">报废信息</el-divider>
        <el-form-item label="报废类型" prop="scrapType">
          <el-radio-group v-model="form.scrapType">
            <el-radio v-for="s in scrapTypeOptions" :key="s" :label="s">{{ s }}</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="报废原因" prop="reason">
          <el-input v-model="form.reason" type="textarea" :rows="3" maxlength="300" show-word-limit
                    placeholder="请填写报废原因，如：达到使用年限、严重损坏无法维修、丢失等"></el-input>
        </el-form-item>
        <el-form-item label="残值">
          <el-input-number v-model="form.residualValue" :min="0" :precision="2" :step="100" controls-position="right"></el-input-number>
          <span style="color: #909399; margin-left: 8px; font-size: 12px">元（资产处置后的剩余价值，可填0）</span>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.comment" type="textarea" :rows="2" maxlength="200"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="formVisible = false">取消</el-button>
        <el-button type="primary" @click="submit">提交</el-button>
      </div>
    </el-dialog>

    <!-- 详情 弹窗 -->
    <el-dialog title="报废详情" :visible.sync="detailVisible" width="760px">
      <el-descriptions :column="2" border v-if="detail">
        <el-descriptions-item :label="$field('no')">{{ detail.assetsNo }}</el-descriptions-item>
        <el-descriptions-item :label="$field('name')">{{ detail.assetsName }}</el-descriptions-item>
        <el-descriptions-item :label="$field('category')">{{ detail.category || '-' }}</el-descriptions-item>
        <el-descriptions-item :label="$field('model')">{{ detail.model || '-' }}</el-descriptions-item>
        <el-descriptions-item :label="$field('money')">￥{{ detail.money || 0 }}</el-descriptions-item>
        <el-descriptions-item :label="$field('depreciate')">￥{{ detail.depreciate || 0 }}</el-descriptions-item>
        <el-descriptions-item :label="$field('departmentName')">{{ detail.departmentName || '-' }}</el-descriptions-item>
        <el-descriptions-item :label="$field('staffName')">{{ detail.staffName || '-' }}</el-descriptions-item>
        <el-descriptions-item :label="$field('location')" :span="2">{{ detail.location || '-' }}</el-descriptions-item>
        <el-descriptions-item label="报废类型">
          <el-tag size="mini">{{ detail.scrapType }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="残值">￥{{ detail.residualValue || 0 }}</el-descriptions-item>
        <el-descriptions-item label="报废原因" :span="2">{{ detail.reason }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detail.comment || '-' }}</el-descriptions-item>
        <el-descriptions-item label="申请人">{{ detail.applicantName }}</el-descriptions-item>
        <el-descriptions-item label="申请时间">{{ detail.applyTime }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="statusTagType(detail.status)" size="small">{{ detail.status }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="审核人">{{ detail.approverName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核时间" :span="2">{{ detail.approveTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核意见" :span="2">{{ detail.approveComment || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <!-- 资产报废历史 -->
    <el-dialog :title="historyTitle" :visible.sync="historyVisible" width="640px">
      <el-timeline>
        <el-timeline-item v-for="h in historyList" :key="h.id"
                          :type="h.status === '已报废' ? 'success' : (h.status === '已拒绝' ? 'danger' : 'primary')"
                          :timestamp="h.approveTime || h.applyTime">
          <el-card shadow="never">
            <div style="margin-bottom: 6px">
              <el-tag :type="statusTagType(h.status)" size="mini">{{ h.status }}</el-tag>
              <el-tag size="mini" style="margin-left: 8px">{{ h.scrapType }}</el-tag>
              <span style="margin-left: 8px; color: #606266; font-size: 13px">申请人：{{ h.applicantName }}</span>
            </div>
            <div style="font-size: 13px">
              原值￥{{ h.money || 0 }}，残值￥{{ h.residualValue || 0 }}
            </div>
            <div style="font-size: 12px; color: #909399; margin-top: 4px">原因：{{ h.reason || '-' }}</div>
            <div v-if="h.approverName" style="font-size: 12px; color: #909399">
              审核人：{{ h.approverName }}<span v-if="h.approveComment">；意见：{{ h.approveComment }}</span>
            </div>
          </el-card>
        </el-timeline-item>
      </el-timeline>
      <div v-if="!historyList.length" style="text-align: center; color: #909399; padding: 20px">暂无报废记录</div>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'AssetsScrap',
  data() {
    return {
      user: JSON.parse(localStorage.getItem('xm-user') || '{}'),
      tableData: [],
      total: 0,
      pageNum: 1,
      pageSize: 10,
      ids: [],
      assetsName: '',
      assetsNo: '',
      scrapType: '',
      status: '',
      scrapTypeOptions: ['正常报废', '毁损', '丢失', '其他'],
      statusOptions: ['待审批', '已报废', '已拒绝'],
      assetOptions: [],
      // 表单
      formVisible: false,
      form: {},
      currentAsset: null,
      rules: {
        assetsId: [{ required: true, message: '请选择报废资产', trigger: 'change' }],
        scrapType: [{ required: true, message: '请选择报废类型', trigger: 'change' }],
        reason: [{ required: true, message: '请填写报废原因', trigger: 'blur' }]
      },
      // 详情
      detailVisible: false,
      detail: null,
      // 历史
      historyVisible: false,
      historyList: [],
      historyTitle: '资产报废记录'
    }
  },
  created() {
    this.loadAssetOptions()
    this.load()
  },
  methods: {
    loadAssetOptions() {
      this.$request.get('/assets/selectAll', { params: { pageSize: 1000 } }).then(res => {
        const data = res.data
        this.assetOptions = Array.isArray(data) ? data : (data.list || [])
      })
    },
    load(pageNum) {
      if (pageNum) this.pageNum = pageNum
      this.$request.get('/assetsScrap/selectPage', {
        params: {
          pageNum: this.pageNum,
          pageSize: this.pageSize,
          assetsName: this.assetsName,
          assetsNo: this.assetsNo,
          scrapType: this.scrapType,
          status: this.status
        }
      }).then(res => {
        this.tableData = res.data.list || []
        this.total = res.data.total || 0
      })
    },
    onPageChange(p) { this.load(p) },
    selectChange(rows) { this.ids = rows.map(r => r.id) },
    statusTagType(s) {
      if (s === '已报废') return 'danger'
      if (s === '已拒绝') return 'info'
      return 'warning'
    },
    // ---------- 申请 / 编辑 ----------
    add() {
      this.form = { assetsId: null, scrapType: '正常报废', reason: '', residualValue: 0, comment: '' }
      this.currentAsset = null
      this.formVisible = true
      this.$nextTick(() => this.$refs.formRef && this.$refs.formRef.clearValidate())
    },
    edit(row) {
      this.form = {
        id: row.id,
        _wasRejected: row.status === '已拒绝',
        assetsId: row.assetsId,
        scrapType: row.scrapType || '正常报废',
        reason: row.reason,
        residualValue: row.residualValue || 0,
        comment: row.comment
      }
      this.currentAsset = {
        category: row.category,
        model: row.model,
        money: row.money,
        depreciate: row.depreciate,
        departmentName: row.departmentName,
        staffName: row.staffName,
        location: row.location
      }
      this.formVisible = true
    },
    onAssetChange(assetsId) {
      this.currentAsset = this.assetOptions.find(a => a.id === assetsId) || null
    },
    onFormClosed() {
      this.form = {}
      this.currentAsset = null
      if (this.$refs.formRef) this.$refs.formRef.clearValidate()
    },
    submit() {
      this.$refs.formRef.validate(valid => {
        if (!valid) return
        const req = this.form.id
          ? this.$request.put('/assetsScrap/update', this.form)
          : this.$request.post('/assetsScrap/add', this.form)
        req.then(() => {
          if (!this.form.id) {
            this.$message.success('报废申请已提交，等待管理员审核')
          } else if (this.form._wasRejected) {
            this.$message.success('已修改并重新提交，等待管理员审核')
          } else {
            this.$message.success('修改成功')
          }
          this.formVisible = false
          this.load()
        })
      })
    },
    // ---------- 审核 ----------
    audit(row, pass) {
      if (pass) {
        this.$confirm('确认通过该报废申请？通过后资产状态将置为"已报废"。', '审核通过', { type: 'warning' }).then(() => {
          this.$request.post('/assetsScrap/audit/' + row.id, { pass: true }).then(() => {
            this.$message.success('已通过，资产状态已更新为已报废')
            this.load()
          })
        }).catch(() => {})
      } else {
        this.$prompt('请输入驳回原因', '驳回报废申请', {
          confirmButtonText: '确认驳回',
          cancelButtonText: '取消',
          inputType: 'textarea',
          inputValidator: v => (v && v.trim()) ? true : '驳回原因不能为空'
        }).then(({ value }) => {
          this.$request.post('/assetsScrap/audit/' + row.id, { pass: false, rejectReason: value }).then(() => {
            this.$message.success('已驳回')
            this.load()
          })
        }).catch(() => {})
      }
    },
    // ---------- 详情 ----------
    showDetail(row) {
      this.$request.get('/assetsScrap/selectById/' + row.id).then(res => {
        this.detail = res.data
        this.detailVisible = true
      })
    },
    // ---------- 历史 ----------
    showHistory(row) {
      this.historyTitle = '「' + row.assetsName + '」报废记录'
      this.$request.get('/assetsScrap/selectByAssetsId/' + row.assetsId).then(res => {
        this.historyList = res.data || []
        this.historyVisible = true
      })
    },
    // ---------- 删除 ----------
    del(id) {
      this.$confirm('确认删除该报废记录？', '提示', { type: 'warning' }).then(() => {
        this.$request.delete('/assetsScrap/delete/' + id).then(() => {
          this.$message.success('删除成功')
          this.load()
        })
      }).catch(() => {})
    },
    delBatch() {
      this.$confirm('确认删除选中的 ' + this.ids.length + ' 条记录？', '提示', { type: 'warning' }).then(() => {
        this.$request.delete('/assetsScrap/delete/batch', { data: this.ids }).then(() => {
          this.$message.success('批量删除成功')
          this.load()
        })
      }).catch(() => {})
    },
    // ---------- 导出 ----------
    exportData() {
      const user = JSON.parse(localStorage.getItem('xm-user') || '{}')
      this.$request({
        url: '/assetsScrap/export',
        method: 'get',
        params: { assetsName: this.assetsName, assetsNo: this.assetsNo, scrapType: this.scrapType, status: this.status },
        responseType: 'blob',
        headers: { token: user.token }
      }).then(res => {
        const blob = new Blob([res.data], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = '资产报废表.xlsx'
        a.click()
        URL.revokeObjectURL(url)
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
