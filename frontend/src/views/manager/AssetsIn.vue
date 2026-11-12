<template>
  <div>
    <!-- 筛选 -->
    <div class="search">
      <el-input :placeholder="$field('name')" style="width: 170px" v-model="name" clearable @keyup.enter.native="load(1)"></el-input>
      <el-input placeholder="采购单号" style="width: 170px; margin-left: 10px" v-model="purchaseNo" clearable @keyup.enter.native="load(1)"></el-input>
      <el-select :placeholder="$field('category')" style="width: 190px; margin-left: 10px" v-model="category" clearable @change="load(1)">
        <el-option v-for="item in categoryOptions" :key="item.id" :value="item.name" :label="item.label"></el-option>
      </el-select>
      <el-select :placeholder="$field('companyName')" style="width: 140px; margin-left: 10px" v-model="companyId" clearable @change="load(1)">
        <el-option v-for="item in companyList" :key="item.id" :value="item.id" :label="item.name"></el-option>
      </el-select>
      <el-select placeholder="审核状态" style="width: 130px; margin-left: 10px" v-model="status" clearable @change="load(1)">
        <el-option value="待审核" label="待审核"></el-option>
        <el-option value="通过" label="通过"></el-option>
        <el-option value="拒绝" label="拒绝"></el-option>
      </el-select>
      <el-button type="info" plain style="margin-left: 10px" @click="load(1)">查询</el-button>
      <el-button type="warning" plain style="margin-left: 10px" @click="reset">重置</el-button>
    </div>

    <div class="operation">
      <el-button type="primary" plain @click="handleAdd">新增入库</el-button>
      <el-button type="success" plain @click="importVisible = true">Excel批量导入</el-button>
      <el-button type="info" plain @click="exportData">导出</el-button>
      <el-button type="danger" plain :disabled="!ids.length" @click="delBatch" v-if="user.role === 'ADMIN'">批量删除</el-button>
    </div>

    <div class="table">
      <el-table :data="tableData" stripe @selection-change="handleSelectionChange">
        <el-table-column type="selection" width="50" align="center" v-if="user.role === 'ADMIN'"></el-table-column>
        <el-table-column prop="purchaseNo" label="采购单号" width="140"></el-table-column>
        <el-table-column prop="name" :label="$field('name')" width="140"></el-table-column>
        <el-table-column prop="category" :label="$field('category')" width="100"></el-table-column>
        <el-table-column prop="model" :label="$field('model')" width="120"></el-table-column>
        <el-table-column prop="num" :label="$field('num')" width="60" align="center"></el-table-column>
        <el-table-column prop="money" :label="$field('money')" width="100" align="right">
          <template v-slot="scope">
            <span v-if="scope.row.money">{{ Number(scope.row.money).toLocaleString() }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="supplier" label="供应商" width="120"></el-table-column>
        <el-table-column prop="date" :label="$field('date')" width="105"></el-table-column>
        <el-table-column label="验收" width="120">
          <template v-slot="scope">
            <span v-if="scope.row.acceptDate">{{ scope.row.acceptDate }} / {{ scope.row.acceptUser }}</span>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="companyName" :label="$field('companyName')" width="140"></el-table-column>
        <el-table-column prop="departmentName" :label="$field('departmentName')" width="140"></el-table-column>
        <el-table-column prop="managerName" :label="$field('staffName')" width="80"></el-table-column>
        <el-table-column prop="location" :label="$field('location')" width="110"></el-table-column>
        <el-table-column label="审核状态" width="90" align="center">
          <template v-slot="scope">
            <el-tag :type="statusType(scope.row.status)" size="small">{{ scope.row.status }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" align="center" width="230" fixed="right">
          <template v-slot="scope">
            <el-button size="mini" type="text" @click="handleDetail(scope.row)">详情</el-button>
            <template v-if="scope.row.status === '待审核'">
              <el-button size="mini" type="text" @click="handleEdit(scope.row)">编辑</el-button>
              <template v-if="user.role === 'ADMIN'">
                <el-button size="mini" type="text" style="color:#67c23a" @click="audit(scope.row, true)">通过</el-button>
                <el-button size="mini" type="text" style="color:#f56c6c" @click="audit(scope.row, false)">驳回</el-button>
              </template>
            </template>
            <el-button size="mini" type="text" v-if="scope.row.status === '通过' && scope.row.assetsId" @click="printLabel(scope.row)">标签</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
        <el-pagination
            background
            @current-change="handleCurrentChange"
            :current-page="pageNum"
            :page-sizes="[10, 20, 50]"
            :page-size="pageSize"
            @size-change="handleSizeChange"
            layout="total, sizes, prev, pager, next"
            :total="total">
        </el-pagination>
      </div>
    </div>

    <!-- 新增/编辑入库单 -->
    <el-dialog :title="form.id ? '编辑入库单' : '资产入库登记'" :visible.sync="fromVisible" width="60%" :close-on-click-modal="false" destroy-on-close>
      <el-form :model="form" label-width="100px" :rules="rules" ref="formRef">
        <el-divider content-position="left">采购信息</el-divider>
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item :label="$field('name')" prop="name">
              <el-input v-model="form.name" :placeholder="$field('name')"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item :label="$field('category') + '（一级）'">
              <el-select style="width: 100%" v-model="form.categoryParentId" clearable
                         placeholder="请选择一级分类" @change="handleFormCategoryParentChange">
                <el-option v-for="item in topCategories" :key="item.id" :value="item.id" :label="item.name"></el-option>
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item :label="$field('category') + '（二级）'" prop="category">
              <el-select style="width: 100%" v-model="form.category" :disabled="!form.categoryParentId"
                         :placeholder="form.categoryParentId ? '请选择二级分类' : '请先选择一级分类'">
                <el-option v-for="item in formChildCategories" :key="item.id" :value="item.name" :label="item.label"></el-option>
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item :label="$field('model')">
              <el-input v-model="form.model" :placeholder="$field('model')"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item :label="$field('num')" prop="num">
              <el-input-number :min="1" v-model="form.num" style="width:100%"></el-input-number>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item :label="$field('money')">
              <el-input v-model="form.money" placeholder="初始价值（单价）"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item :label="$field('depreciate')">
              <el-select style="width: 100%" v-model="form.depreciate" clearable>
                <el-option value="直线法"></el-option>
                <el-option value="工作量法"></el-option>
                <el-option value="双倍余额递减法"></el-option>
                <el-option value="年度总和法"></el-option>
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="采购单号">
              <el-input v-model="form.purchaseNo" placeholder="采购单号"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="供应商">
              <el-input v-model="form.supplier" placeholder="供应商"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item :label="$field('date')">
              <el-date-picker format="yyyy-MM-dd" value-format="yyyy-MM-dd" v-model="form.date" style="width:100%"></el-date-picker>
            </el-form-item>
          </el-col>
        </el-row>

        <el-divider content-position="left">验收信息</el-divider>
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item label="验收日期">
              <el-date-picker format="yyyy-MM-dd" value-format="yyyy-MM-dd" v-model="form.acceptDate" style="width:100%"></el-date-picker>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="验收人">
              <el-input v-model="form.acceptUser" placeholder="验收人"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="验收意见">
              <el-input v-model="form.acceptResult" placeholder="如：验收合格，附件齐全"></el-input>
            </el-form-item>
          </el-col>
        </el-row>

        <el-divider content-position="left">分配信息（审核通过后生效）</el-divider>
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item :label="$field('companyName')">
              <el-select v-model="form.companyId" clearable style="width:100%" placeholder="选择公司" @change="handleFormCompanyChange">
                <el-option v-for="item in companyList" :key="item.id" :value="item.id" :label="item.name"></el-option>
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item :label="$field('departmentName')">
              <el-select v-model="form.departmentId" clearable style="width:100%" :placeholder="form.companyId ? '选择部门' : '请先选择公司'" @change="handleFormDeptChange">
                <el-option v-for="item in formDepartmentList" :key="item.id" :value="item.id" :label="item.label || item.name"></el-option>
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item :label="$field('staffName')">
              <el-select v-model="form.managerId" clearable style="width:100%" :placeholder="'选择' + $field('staffName')" @change="handleFormStaffChange">
                <el-option v-for="item in formStaffList" :key="item.id" :value="item.id" :label="item.name"></el-option>
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item :label="$field('location')">
              <el-input v-model="form.location" :placeholder="$field('location')"></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="备注">
              <el-input type="textarea" :rows="3" v-model="form.comment" placeholder="备注"></el-input>
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <div slot="footer">
        <el-button @click="fromVisible = false">取 消</el-button>
        <el-button type="primary" @click="save">提交审核</el-button>
      </div>
    </el-dialog>

    <!-- 详情 -->
    <el-dialog title="入库单详情" :visible.sync="detailVisible" width="55%" destroy-on-close>
      <div v-if="detail">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="采购单号">{{ detail.purchaseNo || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审核状态"><el-tag :type="statusType(detail.status)" size="small">{{ detail.status }}</el-tag></el-descriptions-item>
          <el-descriptions-item :label="$field('name')">{{ detail.name || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('category')">{{ detail.category || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('model')">{{ detail.model || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('num')">{{ detail.num || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('money')">{{ detail.money ? Number(detail.money).toLocaleString() : '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('depreciate')">{{ detail.depreciate || '-' }}</el-descriptions-item>
          <el-descriptions-item label="供应商">{{ detail.supplier || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('date')">{{ detail.date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="验收日期">{{ detail.acceptDate || '-' }}</el-descriptions-item>
          <el-descriptions-item label="验收人">{{ detail.acceptUser || '-' }}</el-descriptions-item>
          <el-descriptions-item label="验收意见" :span="2">{{ detail.acceptResult || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('companyName')">{{ detail.companyName || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('departmentName')">{{ detail.departmentName || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('staffName')">{{ detail.managerName || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('location')">{{ detail.location || '-' }}</el-descriptions-item>
          <el-descriptions-item label="提交人">{{ detail.staffName || '-' }}</el-descriptions-item>
          <el-descriptions-item label="生成资产编号">{{ detail.assetsNo || '审核通过后生成' }}</el-descriptions-item>
          <el-descriptions-item label="审核人">{{ detail.auditUser || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审核日期">{{ detail.auditDate || '-' }}</el-descriptions-item>
          <el-descriptions-item label="驳回原因" :span="2"><span style="color:#f56c6c">{{ detail.rejectReason || '-' }}</span></el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ detail.comment || '-' }}</el-descriptions-item>
        </el-descriptions>
        <div style="text-align:center; margin-top: 16px" v-if="detail.status === '通过' && detail.assetsId">
          <img :src="qrSrc(detail.assetsNo || detail.assetsId)" style="width:150px;height:150px">
          <div style="font-size:12px;color:#999;margin-top:4px">资产二维码标签</div>
        </div>
      </div>
      <div slot="footer">
        <el-button v-if="detail && detail.status === '通过' && detail.assetsId" type="primary" @click="printLabel(detail)">打印标签</el-button>
        <el-button @click="detailVisible = false">关 闭</el-button>
      </div>
    </el-dialog>

    <!-- 导入 -->
    <el-dialog title="批量导入入库单" :visible.sync="importVisible" width="40%" :close-on-click-modal="false" destroy-on-close>
      <el-alert type="info" :closable="false" show-icon style="margin-bottom: 15px">
        <div slot="default">
          <p>1. 下载模板按格式填写，必填：{{ $field('name') }}、{{ $field('category') }}</p>
          <p>2. 导入的入库单为「待审核」状态，审核通过后自动生成资产和编号</p>
        </div>
      </el-alert>
      <el-button type="primary" @click="downloadTemplate" style="margin-bottom: 15px">下载模板</el-button>
      <el-upload
        :action="$baseUrl + '/assetsIn/import'"
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
  name: "AssetsIn",
  data() {
    return {
      tableData: [],
      pageNum: 1,
      pageSize: 10,
      total: 0,
      name: null,
      purchaseNo: null,
      category: null,
      companyId: null,
      status: null,
      fromVisible: false,
      detailVisible: false,
      detail: null,
      form: {},
      user: JSON.parse(localStorage.getItem('xm-user') || '{}'),
      rules: {
        name: [{ required: true, message: '请输入' + this.$field('name'), trigger: 'blur' }],
        category: [{ required: true, message: '请选择资产分类', trigger: 'change' }],
        num: [{ required: true, message: '请输入数量', trigger: 'blur' }]
      },
      ids: [],
      categoryList: [],
      companyList: [],
      departmentList: [],
      staffList: [],
      importVisible: false
    }
  },
  computed: {
    // 筛选下拉：一级分类 + “一级 / 二级”层级展示
    categoryOptions() {
      const result = []
      this.categoryList.forEach(parent => {
        if (parent.pid) return
        result.push({ id: 'p-' + parent.id, name: parent.name, label: parent.name + '（一级）' })
        this.categoryList.filter(c => c.pid === parent.id).forEach(child => {
          result.push({ id: child.id, name: child.name, label: parent.name + ' / ' + child.name })
        })
      })
      return result
    },
    topCategories() {
      return this.categoryList.filter(c => !c.pid)
    },
    formChildCategories() {
      return this.categoryChildOptions(this.form.categoryParentId)
    },
    // 表单：部门按公司过滤
    formDepartmentList() {
      if (!this.form.companyId) return this.departmentList
      return this.departmentList.filter(d => d.companyId === this.form.companyId)
    },
    // 表单：责任人按公司/部门过滤
    formStaffList() {
      return this.staffList.filter(s => this.staffInScope(s, this.form.companyId, this.form.departmentId))
    }
  },
  created() {
    this.load(1)
    this.$request.get('/category/selectAll').then(res => { this.categoryList = res.data || [] })
    this.$request.get('/company/selectAll').then(res => { this.companyList = res.data || [] })
    this.$request.get('/department/selectAll').then(res => { this.departmentList = res.data || [] })
    this.$request.get('/staff/selectAll', { params: { status: '在职' } }).then(res => { this.staffList = res.data || [] })
  },
  methods: {
    // 员工是否在所选公司/部门范围内
    staffInScope(staff, companyId, departmentId) {
      if (departmentId) return staff.departmentId === departmentId
      if (!companyId) return true
      const dept = this.departmentList.find(d => d.id === staff.departmentId)
      return !!dept && dept.companyId === companyId
    },
    handleFormCompanyChange() {   // 换公司后清空部门/责任人
      this.$set(this.form, 'departmentId', null)
      this.$set(this.form, 'managerId', null)
    },
    handleFormDeptChange(id) {   // 选部门后未选公司则反推公司；责任人不在该部门则清空
      if (id) {
        const dept = this.departmentList.find(d => d.id === id)
        if (dept && !this.form.companyId) this.$set(this.form, 'companyId', dept.companyId)
      }
      const staff = this.staffList.find(s => s.id === this.form.managerId)
      if (staff && !this.staffInScope(staff, this.form.companyId, this.form.departmentId)) {
        this.$set(this.form, 'managerId', null)
      }
    },
    handleFormStaffChange(id) {   // 选责任人后自动带出所属部门/公司
      if (!id) return
      const staff = this.staffList.find(s => s.id === id)
      if (!staff || !staff.departmentId) return
      const dept = this.departmentList.find(d => d.id === staff.departmentId)
      if (!dept) return
      this.$set(this.form, 'departmentId', dept.id)
      this.$set(this.form, 'companyId', dept.companyId)
    },
    statusType(s) {
      return { '待审核': 'warning', '通过': 'success', '拒绝': 'danger' }[s] || 'info'
    },
    qrSrc(code) {
      return this.$baseUrl + '/qr/png?size=300&text=' + encodeURIComponent(location.origin + '/scan/' + encodeURIComponent(code))
    },
    audit(row, pass) {
      const doAudit = (reason) => {
        this.$request.post('/assetsIn/audit/' + row.id, { pass: pass, rejectReason: reason }).then(res => {
          if (res.code === '200') {
            this.$message.success(res.msg || '操作成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }
      if (pass) {
        this.$confirm('审核通过后将自动生成资产档案并按编码规则生成编号，确认通过？', '审核确认', { type: 'warning' })
          .then(() => doAudit(null)).catch(() => {})
      } else {
        this.$prompt('请输入驳回原因', '驳回入库单', {
          confirmButtonText: '确认驳回',
          cancelButtonText: '取消',
          inputType: 'textarea',
          inputValidator: (v) => (v && v.trim() ? true : '驳回原因不能为空')
        }).then(({ value }) => doAudit(value)).catch(() => {})
      }
    },
    printLabel(row) {
      const url = this.qrSrc(row.assetsNo || row.assetsId)
      const w = window.open('', '_blank', 'width=420,height=560')
      w.document.write(`
        <html><head><title>资产标签 - ${row.assetsNo || ''}</title>
        <style>
          body{font-family:'Microsoft YaHei',sans-serif;text-align:center;padding:20px;margin:0}
          .label{display:inline-block;border:1px solid #333;padding:16px 20px;border-radius:6px}
          .no{font-size:15px;font-weight:bold;margin:8px 0 4px}
          .name{font-size:14px;margin-bottom:4px}
          .meta{font-size:12px;color:#555}
          img{width:220px;height:220px}
          .btns{margin-top:16px}
          .btns button{padding:6px 18px;margin:0 6px}
          @media print { .btns{display:none} body{padding:0} }
        </style></head><body>
        <div class="label">
          <img src="${url}">
          <div class="no">${row.assetsNo || ''}</div>
          <div class="name">${row.name || ''}</div>
          <div class="meta">${row.category || ''} ${row.model ? '| ' + row.model : ''}</div>
        </div>
        <div class="btns">
          <button onclick="window.print()">打印</button>
          <button onclick="window.close()">关闭</button>
        </div>
        </body></html>`)
      w.document.close()
    },
    categoryChildOptions(parentId) {
      if (!parentId) return []
      const parent = this.categoryList.find(c => c.id === parentId)
      if (!parent) return []
      const children = this.categoryList.filter(c => c.pid === parentId)
      return [{
        id: 'parent-' + parent.id,
        name: parent.name,
        label: parent.name + '（一级）'
      }].concat(children.map(c => ({ id: c.id, name: c.name, label: c.name })))
    },
    handleFormCategoryParentChange() {
      this.$set(this.form, 'category', null)
    },
    handleAdd() {
      this.form = { num: 1, date: this.today(), acceptDate: this.today(), categoryParentId: null }
      this.fromVisible = true
    },
    handleEdit(row) {
      this.form = JSON.parse(JSON.stringify(row))
      const cat = this.categoryList.find(c => c.name === row.category)
      this.$set(this.form, 'categoryParentId', cat ? (cat.pid || cat.id) : null)
      this.fromVisible = true
    },
    handleDetail(row) {
      this.detail = row
      this.detailVisible = true
    },
    today() {
      const d = new Date()
      return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0')
    },
    save() {
      // 公司由使用部门关联得出，选了公司就必须选部门才能落库
      if (this.form.companyId && !this.form.departmentId) {
        this.$message.warning('已选择所属公司，请继续选择' + this.$field('departmentName'))
        return
      }
      this.$refs.formRef.validate((valid) => {
        if (!valid) return
        const payload = JSON.parse(JSON.stringify(this.form))
        delete payload.categoryParentId
        this.$request({
          url: payload.id ? '/assetsIn/update' : '/assetsIn/add',
          method: payload.id ? 'PUT' : 'POST',
          data: payload
        }).then(res => {
          if (res.code === '200') {
            this.$message.success('提交成功，等待审核')
            this.load(1)
            this.fromVisible = false
          } else {
            this.$message.error(res.msg)
          }
        })
      })
    },
    del(id) {
      this.$confirm('确定删除该入库单吗？', '确认删除', { type: 'warning' }).then(() => {
        this.$request.delete('/assetsIn/delete/' + id).then(res => {
          if (res.code === '200') {
            this.$message.success('操作成功')
            this.load(1)
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
      this.$confirm('确定批量删除选中的入库单吗？', '确认删除', { type: 'warning' }).then(() => {
        this.$request.delete('/assetsIn/delete/batch', { data: this.ids }).then(res => {
          if (res.code === '200') {
            this.$message.success('操作成功')
            this.load(1)
          }
        })
      }).catch(() => {})
    },
    exportData() {
      const p = new URLSearchParams()
      if (this.name) p.append('name', this.name)
      if (this.purchaseNo) p.append('purchaseNo', this.purchaseNo)
      if (this.category) p.append('category', this.category)
      if (this.companyId) p.append('companyId', this.companyId)
      if (this.status) p.append('status', this.status)
      p.append('token', this.user.token)
      window.open(this.$baseUrl + '/assetsIn/export?' + p.toString())
    },
    downloadTemplate() {
      window.open(this.$baseUrl + '/assetsIn/template?token=' + this.user.token)
    },
    handleImportSuccess(response) {
      if (response.code === '200') {
        this.$message.success(response.msg || '导入成功')
        this.importVisible = false
        this.load(1)
      } else {
        this.$message.error(response.msg || '导入失败')
      }
    },
    handleImportError() {
      this.$message.error('导入失败，请检查文件格式')
    },
    load(pageNum) {
      if (pageNum) this.pageNum = pageNum
      this.$request.get('/assetsIn/selectPage', {
        params: {
          pageNum: this.pageNum,
          pageSize: this.pageSize,
          name: this.name,
          purchaseNo: this.purchaseNo,
          category: this.category,
          companyId: this.companyId,
          status: this.status
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
    reset() {
      this.name = null
      this.purchaseNo = null
      this.category = null
      this.companyId = null
      this.status = null
      this.load(1)
    },
    handleCurrentChange(p) { this.load(p) },
    handleSizeChange(s) { this.pageSize = s; this.load(1) }
  }
}
</script>

<style scoped>
</style>
