<template>
  <div>
    <div class="btn-div">
      <el-input v-model="assetsName" :placeholder="$field('name')" class="searchInput" clearable></el-input>
      <el-input v-model="assetsNo" :placeholder="$field('no')" class="searchInput" clearable style="margin-left: 8px"></el-input>
      <el-select v-model="status" placeholder="状态" class="searchInput" clearable style="margin-left: 8px; width: 130px">
        <el-option v-for="s in statusOptions" :key="s" :label="s" :value="s"></el-option>
      </el-select>
      <el-button type="primary" icon="el-icon-search" style="margin-left: 8px" @click="load(1)">查询</el-button>
      <el-button type="success" icon="el-icon-plus" @click="add">申请调拨</el-button>
      <el-button v-if="user.role === 'ADMIN'" type="primary" plain icon="el-icon-upload2" @click="openImport">批量导入</el-button>
      <el-button type="danger" plain :disabled="!ids.length" @click="delBatch" v-if="user.role === 'ADMIN'">批量删除</el-button>
      <el-button type="warning" plain icon="el-icon-download" @click="exportData">导出</el-button>
    </div>

    <el-table :data="tableData" border @selection-change="selectChange" stripe>
      <el-table-column type="selection" width="50" align="center" v-if="user.role === 'ADMIN'"></el-table-column>
      <el-table-column prop="assetsNo" :label="$field('no')" width="140"></el-table-column>
      <el-table-column prop="assetsName" :label="$field('name')" width="150" show-overflow-tooltip></el-table-column>
      <el-table-column :label="'调拨前（' + $field('companyName') + '/' + $field('departmentName') + '/' + $field('staffName') + '/' + $field('location') + '）'" min-width="240">
        <template slot-scope="scope">
          <div>{{ scope.row.fromCompanyName || '-' }} / {{ scope.row.fromDepartmentName || '-' }}</div>
          <div>{{ scope.row.fromStaffName || '-' }}</div>
          <div style="color: #909399; font-size: 12px">{{ scope.row.fromLocation || '-' }}</div>
        </template>
      </el-table-column>
      <el-table-column :label="'调拨后（' + $field('companyName') + '/' + $field('departmentName') + '/' + $field('staffName') + '/' + $field('location') + '）'" min-width="240">
        <template slot-scope="scope">
          <div style="color: #409EFF">{{ scope.row.toCompanyName || '-' }} / {{ scope.row.toDepartmentName || '-' }}</div>
          <div style="color: #409EFF">{{ scope.row.toStaffName || '-' }}</div>
          <div style="color: #409EFF; font-size: 12px">{{ scope.row.toLocation || '-' }}</div>
        </template>
      </el-table-column>
      <el-table-column prop="reason" label="调拨原因" min-width="140" show-overflow-tooltip></el-table-column>
      <el-table-column prop="transferStaffName" label="申请人" width="90"></el-table-column>
      <el-table-column prop="transferTime" label="申请时间" width="160"></el-table-column>
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
          <el-button v-if="user.role === 'ADMIN' || (scope.row.status !== '已调拨')" type="text" size="mini" @click="del(scope.row.id)">删除</el-button>
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
    <el-dialog :title="form._wasRejected ? '驳回后重新提交' : (form.id ? '编辑调拨申请' : '资产调拨申请')" :visible.sync="formVisible" width="720px" @closed="onFormClosed">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="110px">
        <el-divider content-position="left">选择资产</el-divider>
        <el-form-item label="调拨资产" prop="assetsId">
          <el-select v-model="form.assetsId" filterable :placeholder="'输入' + $field('no') + '/' + $field('name') + '搜索'" style="width: 100%"
                     :disabled="!!form.id" @change="onAssetChange">
            <el-option v-for="a in assetOptions" :key="a.id"
                       :label="a.no + ' ' + a.name + '（' + (a.departmentName || '未分配') + '/' + (a.staffName || '无') + '）'"
                       :value="a.id"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="当前信息">
          <el-descriptions :column="1" border size="small" v-if="currentAsset">
            <el-descriptions-item :label="$field('companyName')">{{ currentAsset.companyName || '-' }}</el-descriptions-item>
            <el-descriptions-item :label="$field('departmentName')">{{ currentAsset.departmentName || '-' }}</el-descriptions-item>
            <el-descriptions-item :label="$field('staffName')">{{ currentAsset.staffName || '-' }}</el-descriptions-item>
            <el-descriptions-item :label="$field('location')">{{ currentAsset.location || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-form-item>

        <el-divider content-position="left">调拨目标（{{ $field('departmentName') }} / {{ $field('staffName') }} / {{ $field('location') }} 至少变更一项）</el-divider>
        <el-form-item :label="'新' + $field('companyName')">
          <el-select v-model="form.toCompanyId" clearable placeholder="不变更可不选" style="width: 100%" @change="onToCompanyChange">
            <el-option v-for="c in companyList" :key="c.id" :label="c.name" :value="c.id"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item :label="'新' + $field('departmentName')">
          <el-select v-model="form.toDepartmentId" clearable :placeholder="form.toCompanyId ? '不变更可不选' : '请先选择公司'" style="width: 100%" @change="onToDepartmentChange">
            <el-option v-for="d in targetDepartmentList" :key="d.id" :label="d.label || d.name" :value="d.id"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item :label="'新' + $field('staffName')">
          <el-select v-model="form.toStaffId" clearable placeholder="不变更可不选" filterable style="width: 100%" @change="onToStaffChange">
            <el-option v-for="s in targetStaffList" :key="s.id" :label="s.name + (s.phone ? '（' + s.phone + '）' : '')" :value="s.id"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item :label="'新' + $field('location')">
          <el-input v-model="form.toLocation" placeholder="不变更可留空（留空表示保持原地点）"></el-input>
        </el-form-item>
        <el-form-item label="调拨原因" prop="reason">
          <el-input v-model="form.reason" type="textarea" :rows="2" maxlength="200" show-word-limit
                    placeholder="请填写调拨原因，如：部门调整、工位搬迁等"></el-input>
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
    <el-dialog title="调拨详情" :visible.sync="detailVisible" width="760px">
      <el-descriptions :column="2" border v-if="detail">
        <el-descriptions-item :label="$field('no')">{{ detail.assetsNo }}</el-descriptions-item>
        <el-descriptions-item :label="$field('name')">{{ detail.assetsName }}</el-descriptions-item>
        <el-descriptions-item :label="'调拨前' + $field('companyName')">{{ detail.fromCompanyName || '-' }}</el-descriptions-item>
        <el-descriptions-item :label="'调拨后' + $field('companyName')">
          <span style="color: #409EFF">{{ detail.toCompanyName || '-' }}</span>
        </el-descriptions-item>
        <el-descriptions-item :label="'调拨前' + $field('departmentName')">{{ detail.fromDepartmentName || '-' }}</el-descriptions-item>
        <el-descriptions-item :label="'调拨后' + $field('departmentName')">
          <span style="color: #409EFF">{{ detail.toDepartmentName || '-' }}</span>
        </el-descriptions-item>
        <el-descriptions-item :label="'调拨前' + $field('staffName')">{{ detail.fromStaffName || '-' }}</el-descriptions-item>
        <el-descriptions-item :label="'调拨后' + $field('staffName')">
          <span style="color: #409EFF">{{ detail.toStaffName || '-' }}</span>
        </el-descriptions-item>
        <el-descriptions-item :label="'调拨前' + $field('location')">{{ detail.fromLocation || '-' }}</el-descriptions-item>
        <el-descriptions-item :label="'调拨后' + $field('location')">
          <span style="color: #409EFF">{{ detail.toLocation || '-' }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="调拨原因" :span="2">{{ detail.reason }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detail.comment || '-' }}</el-descriptions-item>
        <el-descriptions-item label="申请人">{{ detail.transferStaffName }}</el-descriptions-item>
        <el-descriptions-item label="申请时间">{{ detail.transferTime }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="statusTagType(detail.status)" size="small">{{ detail.status }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="审核人">{{ detail.approverName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核时间" :span="2">{{ detail.approveTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核意见" :span="2">{{ detail.approveComment || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <!-- 批量导入调拨 -->
    <el-dialog title="批量导入调拨" :visible.sync="importVisible" width="600px"
               :close-on-click-modal="false" @closed="importResult = null">
      <el-alert type="info" :closable="false" show-icon style="margin-bottom: 15px">
        <div slot="default">
          <p>1. 下载模板按格式填写；资产编号、调拨原因必填</p>
          <p>2. 新公司/新部门/新使用人/新存放地点至少填写一项且与当前不同；只填新公司时必须同时填写新部门</p>
          <p>3. 导入后为「待审批」状态，审核通过后资产归属才会变更</p>
        </div>
      </el-alert>
      <div style="display: flex; align-items: center; flex-wrap: wrap">
        <el-button type="primary" icon="el-icon-download" @click="downloadImportTemplate">下载模板</el-button>
        <el-upload
          ref="importUpload"
          :action="$baseUrl + '/assetsTransfer/import'"
          :headers="{ token: user.token }"
          :show-file-list="false"
          :on-success="handleImportSuccess"
          :on-error="handleImportError"
          accept=".xlsx,.xls"
          :limit="1"
          style="margin-left: 10px">
          <el-button type="success" icon="el-icon-upload2">选择文件导入</el-button>
        </el-upload>
        <span style="color: #909399; font-size: 12px; margin-left: 10px">支持 xlsx / xls</span>
      </div>

      <div v-if="importResult" style="margin-top: 15px">
        <el-alert :type="importResult.failed > 0 ? 'warning' : 'success'" :closable="false" show-icon
                  :title="'导入完成：成功 ' + importResult.success + ' 条，失败 ' + importResult.failed + ' 条'"></el-alert>
        <el-table v-if="importResult.errors && importResult.errors.length" :data="importResult.errors"
                  size="mini" border max-height="240" style="margin-top: 10px">
          <el-table-column prop="row" label="Excel行号" width="90" align="center"></el-table-column>
          <el-table-column prop="msg" label="失败原因" min-width="340"></el-table-column>
        </el-table>
        <div v-if="importResult.success > 0" style="color: #909399; font-size: 12px; margin-top: 8px">
          成功的数据已进入「待审批」，可在列表中逐条或批量审核。
        </div>
      </div>

      <div slot="footer">
        <el-button @click="importVisible = false">关闭</el-button>
      </div>
    </el-dialog>

    <!-- 资产调拨历史 -->
    <el-dialog :title="historyTitle" :visible.sync="historyVisible" width="640px">
      <el-timeline>
        <el-timeline-item v-for="h in historyList" :key="h.id"
                          :type="h.status === '已调拨' ? 'success' : (h.status === '已拒绝' ? 'danger' : 'primary')"
                          :timestamp="h.approveTime || h.transferTime">
          <el-card shadow="never">
            <div style="margin-bottom: 6px">
              <el-tag :type="statusTagType(h.status)" size="mini">{{ h.status }}</el-tag>
              <span style="margin-left: 8px; color: #606266; font-size: 13px">申请人：{{ h.transferStaffName }}</span>
            </div>
            <div style="font-size: 13px">
              {{ h.fromCompanyName || '-' }}/{{ h.fromDepartmentName || '-' }}/{{ h.fromStaffName || '-' }}/{{ h.fromLocation || '-' }}
              <i class="el-icon-right" style="margin: 0 6px"></i>
              <span style="color: #409EFF">{{ h.toCompanyName || '-' }}/{{ h.toDepartmentName || '-' }}/{{ h.toStaffName || '-' }}/{{ h.toLocation || '-' }}</span>
            </div>
            <div style="font-size: 12px; color: #909399; margin-top: 4px">原因：{{ h.reason || '-' }}</div>
            <div v-if="h.approverName" style="font-size: 12px; color: #909399">
              审核人：{{ h.approverName }}<span v-if="h.approveComment">；意见：{{ h.approveComment }}</span>
            </div>
          </el-card>
        </el-timeline-item>
      </el-timeline>
      <div v-if="!historyList.length" style="text-align: center; color: #909399; padding: 20px">暂无调拨记录</div>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'AssetsTransfer',
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
      status: '',
      statusOptions: ['待审批', '已调拨', '已拒绝', '已审批'],
      companyList: [],
      departmentList: [],
      staffList: [],
      assetOptions: [],
      // 表单
      formVisible: false,
      form: {},
      currentAsset: null,
      rules: {
        assetsId: [{ required: true, message: '请选择调拨资产', trigger: 'change' }],
        reason: [{ required: true, message: '请填写调拨原因', trigger: 'blur' }]
      },
      // 详情
      detailVisible: false,
      detail: null,
      // 历史
      historyVisible: false,
      historyList: [],
      historyTitle: '资产调拨记录',
      // 批量导入
      importVisible: false,
      importResult: null
    }
  },
  computed: {
    // 新部门按新公司过滤
    targetDepartmentList() {
      if (!this.form.toCompanyId) return this.departmentList
      return this.departmentList.filter(d => d.companyId === this.form.toCompanyId)
    },
    // 新责任人按新公司/新部门过滤
    targetStaffList() {
      return this.staffList.filter(s => this.staffInScope(s, this.form.toCompanyId, this.form.toDepartmentId))
    }
  },
  created() {
    this.loadBaseData()
    this.load()
  },
  methods: {
    loadBaseData() {
      this.$request.get('/company/selectAll').then(res => { this.companyList = res.data || [] })
      this.$request.get('/department/selectAll').then(res => { this.departmentList = res.data || [] })
      this.$request.get('/staff/selectAll', { params: { status: '在职' } }).then(res => { this.staffList = res.data || [] })
      this.$request.get('/assets/selectAll', { params: { pageSize: 1000 } }).then(res => {
        const data = res.data
        this.assetOptions = Array.isArray(data) ? data : (data.list || [])
      })
    },
    load(pageNum) {
      if (pageNum) this.pageNum = pageNum
      this.$request.get('/assetsTransfer/selectPage', {
        params: {
          pageNum: this.pageNum,
          pageSize: this.pageSize,
          assetsName: this.assetsName,
          assetsNo: this.assetsNo,
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
      if (s === '已调拨') return 'success'
      if (s === '已拒绝') return 'danger'
      if (s === '已审批') return ''
      return 'warning'
    },
    // ---------- 批量导入 ----------
    openImport() {
      this.importResult = null
      this.importVisible = true
    },
    downloadImportTemplate() {
      window.open(this.$baseUrl + '/assetsTransfer/template?token=' + this.user.token)
    },
    handleImportSuccess(response) {
      if (this.$refs.importUpload) this.$refs.importUpload.clearFiles()
      if (!response || response.code !== '200') {
        this.$message.error((response && response.msg) || '导入失败')
        return
      }
      this.importResult = response.data || {}
      if (this.importResult.failed > 0) {
        this.$message.warning('导入完成：成功 ' + this.importResult.success + ' 条，失败 ' + this.importResult.failed + ' 条')
      } else {
        this.$message.success('导入成功 ' + this.importResult.success + ' 条，已进入待审批')
      }
      this.load(1)
    },
    handleImportError() {
      if (this.$refs.importUpload) this.$refs.importUpload.clearFiles()
      this.$message.error('导入失败，请检查文件格式或网络')
    },
    // ---------- 申请 / 编辑 ----------
    add() {
      this.form = { assetsId: null, toCompanyId: null, toDepartmentId: null, toStaffId: null, toLocation: '', reason: '', comment: '' }
      this.currentAsset = null
      this.formVisible = true
      this.$nextTick(() => this.$refs.formRef && this.$refs.formRef.clearValidate())
    },
    edit(row) {
      const fromDept = this.departmentList.find(d => d.id === row.fromDepartmentId)
      const toDept = this.departmentList.find(d => d.id === row.toDepartmentId)
      const fromCompanyId = fromDept ? fromDept.companyId : null
      this.form = {
        id: row.id,
        _wasRejected: row.status === '已拒绝',
        assetsId: row.assetsId,
        toCompanyId: toDept ? toDept.companyId : fromCompanyId,
        toDepartmentId: row.toDepartmentId,
        toStaffId: row.toStaffId,
        toLocation: row.toLocation || '',
        reason: row.reason,
        comment: row.comment
      }
      this.currentAsset = {
        companyId: fromCompanyId,
        companyName: row.fromCompanyName,
        departmentName: row.fromDepartmentName,
        staffName: row.fromStaffName,
        location: row.fromLocation
      }
      this.formVisible = true
    },
    onAssetChange(assetsId) {
      this.currentAsset = this.assetOptions.find(a => a.id === assetsId) || null
      if (this.currentAsset) {
        // 默认目标与当前一致，提示用户修改其中至少一项
        this.form.toCompanyId = this.currentAsset.companyId || null
        this.form.toDepartmentId = this.currentAsset.departmentId || null
        this.form.toStaffId = this.currentAsset.staffId || null
        this.form.toLocation = this.currentAsset.location || ''
      }
    },
    // 员工是否在所选公司/部门范围内
    staffInScope(staff, companyId, departmentId) {
      if (departmentId) return staff.departmentId === departmentId
      if (!companyId) return true
      const dept = this.departmentList.find(d => d.id === staff.departmentId)
      return !!dept && dept.companyId === companyId
    },
    onToCompanyChange() {   // 换新公司后清空新部门/新责任人
      this.$set(this.form, 'toDepartmentId', null)
      this.$set(this.form, 'toStaffId', null)
    },
    onToDepartmentChange(id) {   // 选新部门后未选公司则反推公司；责任人不在范围内则清空
      if (id) {
        const dept = this.departmentList.find(d => d.id === id)
        if (dept && !this.form.toCompanyId) this.$set(this.form, 'toCompanyId', dept.companyId)
      }
      const staff = this.staffList.find(s => s.id === this.form.toStaffId)
      if (staff && !this.staffInScope(staff, this.form.toCompanyId, this.form.toDepartmentId)) {
        this.$set(this.form, 'toStaffId', null)
      }
    },
    onToStaffChange(id) {   // 选新责任人后自动带出其部门/公司
      if (!id) return
      const staff = this.staffList.find(s => s.id === id)
      if (!staff || !staff.departmentId) return
      const dept = this.departmentList.find(d => d.id === staff.departmentId)
      if (!dept) return
      this.$set(this.form, 'toDepartmentId', dept.id)
      this.$set(this.form, 'toCompanyId', dept.companyId)
    },
    onFormClosed() {
      this.form = {}
      this.currentAsset = null
      if (this.$refs.formRef) this.$refs.formRef.clearValidate()
    },
    submit() {
      // 公司由部门关联得出：跨公司调拨必须选新部门，否则公司变更无法落库
      const originCompanyId = this.currentAsset ? this.currentAsset.companyId : null
      if (this.form.toCompanyId && this.form.toCompanyId !== originCompanyId && !this.form.toDepartmentId) {
        this.$message.warning('已选择新公司，请继续选择新' + this.$field('departmentName'))
        return
      }
      this.$refs.formRef.validate(valid => {
        if (!valid) return
        const req = this.form.id
          ? this.$request.put('/assetsTransfer/update', this.form)
          : this.$request.post('/assetsTransfer/add', this.form)
        req.then(() => {
          if (!this.form.id) {
            this.$message.success('调拨申请已提交，等待管理员审核')
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
        this.$confirm('确认通过该调拨申请？通过后资产归属将立即变更。', '审核通过', { type: 'warning' }).then(() => {
          this.$request.post('/assetsTransfer/audit/' + row.id, { pass: true }).then(() => {
            this.$message.success('已通过，资产信息已更新')
            this.load()
          })
        }).catch(() => {})
      } else {
        this.$prompt('请输入驳回原因', '驳回调拨申请', {
          confirmButtonText: '确认驳回',
          cancelButtonText: '取消',
          inputType: 'textarea',
          inputValidator: v => (v && v.trim()) ? true : '驳回原因不能为空'
        }).then(({ value }) => {
          this.$request.post('/assetsTransfer/audit/' + row.id, { pass: false, rejectReason: value }).then(() => {
            this.$message.success('已驳回')
            this.load()
          })
        }).catch(() => {})
      }
    },
    // ---------- 详情 ----------
    showDetail(row) {
      this.$request.get('/assetsTransfer/selectById/' + row.id).then(res => {
        this.detail = res.data
        this.detailVisible = true
      })
    },
    // ---------- 历史 ----------
    showHistory(row) {
      this.historyTitle = '「' + row.assetsName + '」调拨记录'
      this.$request.get('/assetsTransfer/selectByAssetsId/' + row.assetsId).then(res => {
        this.historyList = res.data || []
        this.historyVisible = true
      })
    },
    // ---------- 删除 ----------
    del(id) {
      this.$confirm('确认删除该调拨记录？', '提示', { type: 'warning' }).then(() => {
        this.$request.delete('/assetsTransfer/delete/' + id).then(() => {
          this.$message.success('删除成功')
          this.load()
        })
      }).catch(() => {})
    },
    delBatch() {
      this.$confirm('确认删除选中的 ' + this.ids.length + ' 条记录？', '提示', { type: 'warning' }).then(() => {
        this.$request.delete('/assetsTransfer/delete/batch', { data: this.ids }).then(() => {
          this.$message.success('批量删除成功')
          this.load()
        })
      }).catch(() => {})
    },
    // ---------- 导出 ----------
    exportData() {
      const user = JSON.parse(localStorage.getItem('xm-user') || '{}')
      this.$request({
        url: '/assetsTransfer/export',
        method: 'get',
        responseType: 'blob',
        headers: { token: user.token }
      }).then(res => {
        const blob = new Blob([res.data], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = '资产调拨表.xlsx'
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
