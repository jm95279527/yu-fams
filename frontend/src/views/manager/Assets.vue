<template>
  <div>
    <!-- 高级筛选 -->
    <div class="search">
      <el-input :placeholder="$field('name')" style="width: 160px" v-model="name" clearable @keyup.enter.native="load(1)"></el-input>
      <el-input :placeholder="$field('no')" style="width: 160px; margin-left: 10px" v-model="no" clearable @keyup.enter.native="load(1)"></el-input>
      <el-select :placeholder="$field('category') + '（一级）'" style="width: 150px; margin-left: 10px" v-model="categoryParentId" clearable @change="handleSearchCategoryParentChange">
        <el-option v-for="item in topCategories" :key="item.id" :value="item.id" :label="item.name"></el-option>
      </el-select>
      <el-select :placeholder="$field('category') + '（二级）'" style="width: 150px; margin-left: 10px" v-model="category" clearable :disabled="!categoryParentId" @change="load(1)">
        <el-option v-for="item in searchChildCategories" :key="item.id" :value="item.name" :label="item.label"></el-option>
      </el-select>
      <el-select :placeholder="$field('status')" style="width: 110px; margin-left: 10px" v-model="status" clearable @change="load(1)">
        <el-option value="正常" label="正常"></el-option>
        <el-option value="停用" label="停用"></el-option>
        <el-option value="维修中" label="维修中"></el-option>
        <el-option value="报废" label="报废"></el-option>
      </el-select>
      <el-select :placeholder="$field('companyName')" style="width: 150px; margin-left: 10px" v-model="companyId" clearable @change="handleCompanyChange">
        <el-option v-for="item in companyList" :key="item.id" :value="item.id" :label="item.name"></el-option>
      </el-select>
      <el-select :placeholder="$field('departmentName')" style="width: 150px; margin-left: 10px" v-model="departmentId" clearable @change="handleSearchDeptChange">
        <el-option v-for="item in searchDepartmentList" :key="item.id" :value="item.id" :label="item.label || item.name"></el-option>
      </el-select>
      <el-select :placeholder="$field('staffName')" style="width: 130px; margin-left: 10px" v-model="staffId" clearable @change="load(1)">
        <el-option v-for="item in searchStaffList" :key="item.id" :value="item.id" :label="item.name"></el-option>
      </el-select>
      <el-input :placeholder="$field('location')" style="width: 140px; margin-left: 10px" v-model="location" clearable @keyup.enter.native="load(1)"></el-input>
      <el-date-picker
        v-if="showMore"
        v-model="dateRange"
        type="daterange"
        range-separator="至"
        start-placeholder="购置起"
        end-placeholder="购置止"
        value-format="yyyy-MM-dd"
        style="margin-left: 10px"
        @change="load(1)">
      </el-date-picker>
      <el-button type="info" plain style="margin-left: 10px" @click="load(1)">查询</el-button>
      <el-button type="warning" plain style="margin-left: 10px" @click="reset">重置</el-button>
      <el-button type="text" style="margin-left: 10px" @click="showMore = !showMore">{{ showMore ? '收起' : '更多筛选' }}</el-button>
    </div>

    <div class="operation" v-if="user.role=='ADMIN'">
      <el-button type="primary" plain @click="handleAdd">新增</el-button>
      <el-button type="danger" plain :disabled="!ids.length" @click="delBatch">批量删除</el-button>
      <el-button type="info" plain @click="exportData">批量导出</el-button>
      <el-button type="success" plain @click="handleImport">批量导入</el-button>
      <el-button type="warning" plain :disabled="!ids.length" @click="batchQrcode">批量二维码</el-button>
    </div>

    <div class="table">
      <el-table :data="tableData" class="asset-table" strip @selection-change="handleSelectionChange">
        <el-table-column type="selection" width="55" align="center" v-if="user.role=='ADMIN'"></el-table-column>
        <el-table-column prop="no" :label="$field('no')" min-width="132" show-overflow-tooltip></el-table-column>
        <el-table-column prop="name" :label="$field('name')" min-width="150" show-overflow-tooltip></el-table-column>
        <el-table-column prop="category" :label="$field('category')" min-width="108" show-overflow-tooltip></el-table-column>
        <el-table-column prop="img" :label="$field('img')" width="76" align="center">
          <template v-slot="scope">
            <el-image v-if="scope.row.img" style="width: 40px; height: 40px" :src="scope.row.img" :preview-src-list="[scope.row.img]" fit="cover"></el-image>
          </template>
        </el-table-column>
        <el-table-column prop="model" :label="$field('model')" min-width="132" show-overflow-tooltip></el-table-column>
        <el-table-column prop="num" :label="$field('num')" width="76" align="center"></el-table-column>
        <el-table-column prop="date" :label="$field('date')" width="116"></el-table-column>
        <el-table-column prop="money" :label="$field('money')" width="120" align="right">
          <template v-slot="scope">
            <span v-if="scope.row.money">{{ Number(scope.row.money).toLocaleString() }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="depreciate" :label="$field('depreciate')" min-width="108" show-overflow-tooltip></el-table-column>
        <el-table-column prop="companyName" :label="$field('companyName')" min-width="140" show-overflow-tooltip></el-table-column>
        <el-table-column prop="departmentName" :label="$field('departmentName')" min-width="140" show-overflow-tooltip></el-table-column>
        <el-table-column prop="staffName" :label="$field('staffName')" width="96" show-overflow-tooltip></el-table-column>
        <el-table-column prop="location" :label="$field('location')" min-width="130" show-overflow-tooltip></el-table-column>
        <el-table-column prop="status" :label="$field('status')" width="92" align="center">
          <template v-slot="scope">
            <el-tag :type="statusType(scope.row.status)" size="small">{{ scope.row.status || '-' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="comment" :label="$field('comment')" min-width="160" show-overflow-tooltip></el-table-column>
        <el-table-column v-for="f in customFields" :key="f.fieldKey" :prop="f.fieldKey"
                         :label="f.label" min-width="140" show-overflow-tooltip></el-table-column>
        <el-table-column label="操作" align="center" width="320" fixed="right" v-if="user.role=='ADMIN'">
          <template v-slot="scope">
            <el-button size="mini" type="text" @click="handleDetail(scope.row)">详情</el-button>
            <el-button size="mini" type="text" @click="handleEdit(scope.row)">编辑</el-button>
            <el-button size="mini" type="text" @click="showQr(scope.row)">二维码</el-button>
            <el-button size="mini" type="text" style="color:#409eff" @click="handleReceive(scope.row.id)">申请借用</el-button>
            <el-button size="mini" type="text" style="color:#f56c6c" @click="del(scope.row.id)">删除</el-button>
          </template>
        </el-table-column>
        <el-table-column label="操作" align="center" width="100" fixed="right" v-if="user.role=='STAFF'">
          <template v-slot="scope">
            <el-button size="mini" type="primary" plain @click="handleReceive(scope.row.id)">申请借用</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
        <el-pagination
            background
            @current-change="handleCurrentChange"
            :current-page="pageNum"
            :page-sizes="[10, 20, 50, 100]"
            :page-size="pageSize"
            @size-change="handleSizeChange"
            layout="total, sizes, prev, pager, next"
            :total="total">
        </el-pagination>
      </div>
    </div>

    <!-- 申请借用 -->
    <el-dialog title="申请借用" :visible.sync="fromVisible1" width="40%" :close-on-click-modal="false" destroy-on-close>
      <el-form :model="assetsReceive" label-width="100px" style="padding-right: 50px" :rules="assetsReceiveRules" ref="assetsReceiveFormRef">
        <el-form-item label="借用人" prop="borrowerName">
          <el-input v-model="assetsReceive.borrowerName" placeholder="请填写借用人姓名"></el-input>
        </el-form-item>
        <el-form-item label="联系方式" prop="borrowerPhone">
          <el-input v-model="assetsReceive.borrowerPhone" placeholder="请填写 11 位手机号" maxlength="11"></el-input>
        </el-form-item>
        <el-form-item label="归还日期" prop="returnDate">
          <el-date-picker format="yyyy-MM-dd" value-format="yyyy-MM-dd" placeholder="请选择归还日期"
                          v-model="assetsReceive.returnDate" style="width: 100%"></el-date-picker>
        </el-form-item>
        <el-form-item :label="$field('comment')" prop="comment">
          <el-input type="textarea" :rows="5" v-model="assetsReceive.comment" placeholder="备注"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="fromVisible1 = false">取 消</el-button>
        <el-button type="primary" @click="saveAssetsReceive">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 新增/编辑 -->
    <el-dialog title="资产信息" :visible.sync="fromVisible" width="50%" :close-on-click-modal="false" destroy-on-close>
      <el-form :model="form" label-width="100px" style="padding-right: 50px" :rules="rules" ref="formRef">
        <el-form-item :label="$field('name')" prop="name">
          <el-input v-model="form.name" :placeholder="$field('name')"></el-input>
        </el-form-item>
        <el-form-item :label="$field('category') + '（一级）'">
          <el-select style="width: 100%;" v-model="form.categoryParentId" clearable
                     placeholder="请选择一级分类" @change="handleFormCategoryParentChange">
            <el-option v-for="item in topCategories" :key="item.id" :value="item.id" :label="item.name"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item :label="$field('category') + '（二级）'" prop="category">
          <el-select style="width: 100%;" v-model="form.category" :disabled="!form.categoryParentId"
                     :placeholder="form.categoryParentId ? '请选择二级分类' : '请先选择一级分类'">
            <el-option v-for="item in formChildCategories" :key="item.id" :value="item.name" :label="item.label"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item :label="$field('no')" prop="no">
          <div style="display: flex">
            <el-input v-model="form.no" placeholder="留空则按编码规则自动生成"></el-input>
            <el-button type="success" plain style="margin-left: 8px" :disabled="!form.category" @click="genNo">生成编号</el-button>
          </div>
        </el-form-item>
        <el-form-item :label="$field('img')" prop="img">
          <el-upload
              :action="$baseUrl + '/files/upload'"
              :headers="{ token: user.token }"
              list-type="picture"
              :on-success="handleImgSuccess"
          >
            <el-button type="primary">上传</el-button>
          </el-upload>
        </el-form-item>
        <el-form-item :label="$field('model')" prop="model">
          <el-input v-model="form.model" :placeholder="$field('model')"></el-input>
        </el-form-item>
        <el-form-item :label="$field('num')" prop="num">
          <el-input-number :min="1" v-model="form.num" placeholder="数量"></el-input-number>
        </el-form-item>
        <el-form-item :label="$field('date')" prop="date">
          <el-date-picker format="yyyy-MM-dd" value-format="yyyy-MM-dd"
                          v-model="form.date" style="width: 100%"></el-date-picker>
        </el-form-item>
        <el-form-item :label="$field('money')" prop="money">
          <el-input v-model="form.money" :placeholder="$field('money')"></el-input>
        </el-form-item>
        <el-form-item :label="$field('depreciate')" prop="depreciate">
          <el-select style="width: 100%" v-model="form.depreciate">
            <el-option value="直线法"></el-option>
            <el-option value="工作量法"></el-option>
            <el-option value="双倍余额递减法"></el-option>
            <el-option value="年度总和法"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item :label="$field('companyName')" prop="companyId">
          <el-select style="width: 100%" v-model="form.companyId" clearable placeholder="请选择公司" @change="handleFormCompanyChange">
            <el-option v-for="item in companyList" :key="item.id" :value="item.id" :label="item.name"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item :label="$field('departmentName')" prop="departmentId">
          <el-select ref="selectTree" v-model="form.departmentId" clearable style="width: 100%;" :placeholder="form.companyId ? '请选择部门' : '请先选择公司'">
            <el-option
                v-for="item in formDepartmentList"
                :key="item.id"
                :value="item.id"
                :label="item.label || item.name"
                style="display: none;"/>
            <el-tree
                :data="formDepartmentTree"
                :props="{children: 'children', label: 'label'}"
                highlight-current
                @node-click="handleNodeClick"
                default-expand-all />
          </el-select>
        </el-form-item>
        <el-form-item :label="$field('staffName')" prop="staffId">
            <el-select style="width: 100%" v-model="form.staffId" clearable :placeholder="'请选择' + $field('staffName')" @change="handleFormStaffChange">
              <el-option v-for="item in formStaffList" :key="item.id" :value="item.id" :label="item.name"></el-option>
            </el-select>
        </el-form-item>
        <el-form-item :label="$field('location')" prop="location">
          <el-input v-model="form.location" :placeholder="$field('location')"></el-input>
        </el-form-item>
        <el-form-item :label="$field('status')" prop="status">
          <el-select style="width: 100%" v-model="form.status">
            <el-option value="正常"></el-option>
            <el-option value="停用"></el-option>
            <el-option value="维修中"></el-option>
            <el-option value="报废"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item v-for="f in customFields" :key="f.fieldKey" :label="f.label" :prop="f.fieldKey">
          <el-select v-if="f.fieldType === 'select'" v-model="form[f.fieldKey]" clearable style="width: 100%"
                     :placeholder="'请选择' + f.label">
            <el-option v-for="opt in fieldOptionList(f)" :key="opt" :label="opt" :value="opt"></el-option>
          </el-select>
          <el-date-picker v-else-if="f.fieldType === 'date'" v-model="form[f.fieldKey]"
                          format="yyyy-MM-dd" value-format="yyyy-MM-dd" style="width: 100%"
                          :placeholder="'请选择' + f.label"></el-date-picker>
          <el-input v-else v-model="form[f.fieldKey]" :type="f.fieldType === 'number' ? 'number' : 'text'"
                    :placeholder="'请输入' + f.label"></el-input>
        </el-form-item>
        <el-form-item :label="$field('comment')" prop="comment">
          <el-input v-model="form.comment" placeholder="备注"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="fromVisible = false">取 消</el-button>
        <el-button type="primary" @click="save">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 资产详情 -->
    <el-dialog title="资产详情" :visible.sync="detailVisible" width="50%" :close-on-click-modal="false" destroy-on-close>
      <div v-if="detail" class="detail-wrap">
        <div class="detail-img" v-if="detail.img">
          <el-image :src="detail.img" :preview-src-list="[detail.img]" fit="contain" style="width: 100%; max-height: 260px"></el-image>
        </div>
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item :label="$field('no')">{{ detail.no || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('name')">{{ detail.name || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('category')">{{ detail.category || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('model')">{{ detail.model || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('num')">{{ detail.num || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('date')">{{ detail.date || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('money')">{{ detail.money ? Number(detail.money).toLocaleString() : '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('depreciate')">{{ detail.depreciate || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('companyName')">{{ detail.companyName || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('departmentName')">{{ detail.departmentName || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('staffName')">{{ detail.staffName || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('location')">{{ detail.location || '-' }}</el-descriptions-item>
          <el-descriptions-item :label="$field('status')"><el-tag :type="statusType(detail.status)" size="small">{{ detail.status || '-' }}</el-tag></el-descriptions-item>
          <el-descriptions-item v-for="f in customFields" :key="f.fieldKey" :label="f.label">
            {{ detail[f.fieldKey] || '-' }}
          </el-descriptions-item>
          <el-descriptions-item :label="$field('comment')" :span="2">{{ detail.comment || '-' }}</el-descriptions-item>
        </el-descriptions>
        <div style="text-align: center; margin-top: 20px">
          <img :src="qrSrc" style="width: 160px; height: 160px" alt="资产二维码">
          <div style="color: #999; font-size: 12px; margin-top: 6px">扫码查看资产信息</div>
        </div>
      </div>
      <div slot="footer" class="dialog-footer">
        <el-button @click="detailVisible = false">关 闭</el-button>
      </div>
    </el-dialog>

    <!-- 批量导入 -->
    <el-dialog title="批量导入资产" :visible.sync="importVisible" width="40%" :close-on-click-modal="false" destroy-on-close>
      <div style="margin-bottom: 20px;">
        <el-alert title="导入说明" type="info" :closable="false" show-icon>
          <div slot="default">
            <p>1. 请下载模板文件，按照模板格式填写数据</p>
            <p>2. 支持Excel格式(.xlsx)文件</p>
            <p>3. 必填：{{ $field('name') }}、{{ $field('category') }}；{{ $field('no') }}留空将按编码规则自动生成</p>
            <p>4. 可选：{{ $field('model') }}、{{ $field('num') }}、{{ $field('date') }}、{{ $field('money') }}、{{ $field('depreciate') }}、{{ $field('companyName') }}、{{ $field('departmentName') }}、{{ $field('staffName') }}、{{ $field('location') }}、{{ $field('status') }}、{{ $field('comment') }}</p>
            <p>5. {{ $field('companyName') }}、{{ $field('departmentName') }}、{{ $field('staffName') }} 按名称填写，需与系统基础资料一致；填写{{ $field('companyName') }}时必须填写{{ $field('departmentName') }}</p>
          </div>
        </el-alert>
      </div>
      <div style="margin-bottom: 20px;">
        <el-button type="primary" @click="downloadTemplate">下载模板</el-button>
      </div>
      <el-upload
        class="upload-demo"
        :action="$baseUrl + '/assets/import'"
        :headers="{ token: user.token }"
        :on-success="handleImportSuccess"
        :on-error="handleImportError"
        :before-upload="beforeImport"
        accept=".xlsx,.xls"
        :show-file-list="true"
        :limit="1">
        <el-button type="success">选择文件</el-button>
        <div slot="tip" class="el-upload__tip">只能上传xlsx/xls文件</div>
      </el-upload>
      <div slot="footer" class="dialog-footer">
        <el-button @click="importVisible = false">取 消</el-button>
      </div>
    </el-dialog>

    <!-- 二维码 -->
    <el-dialog title="资产二维码" :visible.sync="qrVisible" width="320px" :close-on-click-modal="false" destroy-on-close>
      <div style="text-align: center">
        <img v-if="qrSrc" :src="qrSrc" style="width: 240px; height: 240px" alt="资产二维码">
        <div style="margin-top: 10px; color: #666; font-size: 12px; word-break: break-all">{{ qrUrl }}</div>
        <div style="margin-top: 6px; color: #999; font-size: 12px">手机扫码查看资产信息</div>
      </div>
      <div slot="footer" class="dialog-footer">
        <el-button @click="qrVisible = false">关 闭</el-button>
        <el-button type="primary" @click="downloadQr">下载二维码</el-button>
      </div>
    </el-dialog>
  </div>
</template>
<script>
export default {
  name: "Assets",
  data() {
    return {
      tableData: [],
      pageNum: 1,
      pageSize: 10,
      total: 0,
      name: null,
      categoryParentId: null,
      category: null,
      no: null,
      status: null,
      companyId: null,
      departmentId: null,
      staffId: null,
      location: null,
      dateRange: [],
      showMore: false,
      fromVisible: false,
      form: {},
      user: JSON.parse(localStorage.getItem('xm-user') || '{}'),
      rules: {
        name: [{ required: true, message: '请输入名称', trigger: 'blur' }],
        category: [{ required: true, message: '请选择分类', trigger: 'change' }]
      },
      ids: [],
      companyList: [],
      staffList: [],
      departmentList: [],
      departmentTree: [],
      categoryList: [],
      assetsReceive: {},
      fromVisible1: false,
      assetsReceiveRules: {
        borrowerName: [{ required: true, message: '请填写借用人', trigger: 'blur' }],
        borrowerPhone: [
          { required: true, message: '请填写联系方式', trigger: 'blur' },
          { pattern: /^1[3-9]\d{9}$/, message: '请填写正确的 11 位手机号', trigger: 'blur' }
        ],
        returnDate: [{ required: true, message: '请选择归还日期', trigger: 'blur' }],
      },
      importVisible: false,
      qrVisible: false,
      qrSrc: '',
      qrUrl: '',
      qrName: '资产二维码',
      detailVisible: false,
      detail: null
    }
  },
  computed: {
    // 已启用的自定义字段（表单/列表/详情动态渲染）
    customFields() {
      return (this.$fieldStore.fields || []).filter(f => !f.isSystem && f.enabled !== 0)
    },
    // 一级分类
    topCategories() {
      return this.categoryList.filter(c => !c.pid)
    },
    // 筛选：二级分类（含“一级分类本身”选项，兼容未细分的资产）
    searchChildCategories() {
      return this.categoryChildOptions(this.categoryParentId)
    },
    // 表单：二级分类
    formChildCategories() {
      return this.categoryChildOptions(this.form.categoryParentId)
    },
    // 筛选：部门按公司过滤
    searchDepartmentList() {
      if (!this.companyId) return this.departmentList
      return this.departmentList.filter(d => d.companyId === this.companyId)
    },
    // 筛选：责任人按公司/部门过滤
    searchStaffList() {
      return this.staffList.filter(s => this.staffInScope(s, this.companyId, this.departmentId))
    },
    // 表单：部门按公司过滤（扁平列表用于回显 label）
    formDepartmentList() {
      if (!this.form.companyId) return this.departmentList
      return this.departmentList.filter(d => d.companyId === this.form.companyId)
    },
    // 表单：部门树按公司过滤（保留上下级层级）
    formDepartmentTree() {
      if (!this.form.companyId) return this.departmentTree
      return this.filterDeptTree(this.departmentTree, this.form.companyId)
    },
    // 表单：责任人按公司/部门过滤
    formStaffList() {
      return this.staffList.filter(s => this.staffInScope(s, this.form.companyId, this.form.departmentId))
    }
  },
  created() {
    this.load(1)
    this.loadCompany()
    this.loadStaff()
    this.loadDepartment()
    this.loadCategory()
  },
  methods: {
    // 员工是否在所选公司/部门范围内
    staffInScope(staff, companyId, departmentId) {
      if (departmentId) return staff.departmentId === departmentId
      if (!companyId) return true
      const dept = this.departmentList.find(d => d.id === staff.departmentId)
      return !!dept && dept.companyId === companyId
    },
    // 只保留指定公司下的部门节点，父节点因含子节点而保留
    filterDeptTree(nodes, companyId) {
      const result = []
      ;(nodes || []).forEach(node => {
        const children = this.filterDeptTree(node.children, companyId)
        if (node.companyId === companyId || children.length) {
          result.push(Object.assign({}, node, { children }))
        }
      })
      return result
    },
    loadCompany() {
      this.$request.get('/company/selectAll').then(res => {
        this.companyList = res.data || []
      })
    },
    handleCompanyChange() {   // 筛选：换公司后清空部门/责任人
      this.departmentId = null
      this.staffId = null
      this.load(1)
    },
    handleSearchDeptChange() {   // 筛选：换部门后责任人不在范围内则清空
      const staff = this.staffList.find(s => s.id === this.staffId)
      if (staff && !this.staffInScope(staff, this.companyId, this.departmentId)) {
        this.staffId = null
      }
      this.load(1)
    },
    handleFormCompanyChange() {   // 表单：换公司后清空部门/责任人
      this.$set(this.form, 'departmentId', null)
      this.$set(this.form, 'staffId', null)
    },
    handleFormStaffChange(id) {   // 表单：选责任人后自动带出所属部门/公司
      if (!id) return
      const staff = this.staffList.find(s => s.id === id)
      if (!staff || !staff.departmentId) return
      const dept = this.departmentList.find(d => d.id === staff.departmentId)
      if (!dept) return
      this.$set(this.form, 'departmentId', dept.id)
      this.$set(this.form, 'companyId', dept.companyId)
    },
    statusType(s) {
      const map = { '正常': 'success', '停用': 'info', '维修中': 'warning', '报废': 'danger' }
      return map[s] || 'info'
    },
    saveAssetsReceive() {
      this.$refs.assetsReceiveFormRef.validate((valid) => {
        if (valid) {
          this.$request.post('/assetsReceive/add', this.assetsReceive).then(res => {
            if (res.code === '200') {
              this.$message.success('申请成功')
              this.load(1)
              this.fromVisible1 = false
            } else {
              this.$message.error(res.msg)
            }
          })
        }
      })
    },
    handleReceive(assetsId){
      this.fromVisible1 = true
      // 借用人默认填当前登录人姓名，可手工修改
      this.assetsReceive = { assetsId: assetsId, borrowerName: this.user.name || '' }
    },
    exportData(){
      const params = new URLSearchParams()
      if (this.name) params.append('name', this.name)
      if (this.category) params.append('category', this.category)
      if (this.no) params.append('no', this.no)
      if (this.status) params.append('status', this.status)
      if (this.companyId) params.append('companyId', this.companyId)
      if (this.departmentId) params.append('departmentId', this.departmentId)
      if (this.staffId) params.append('staffId', this.staffId)
      if (this.location) params.append('location', this.location)
      if (this.dateRange && this.dateRange.length === 2) {
        params.append('dateStart', this.dateRange[0])
        params.append('dateEnd', this.dateRange[1])
      }
      params.append('token', this.user.token)
      window.open(this.$baseUrl + '/assets/export?' + params.toString())
    },
    batchQrcode() {
      if (!this.ids.length) {
        this.$message.warning('请选择资产')
        return
      }
      const params = this.ids.map(id => 'ids=' + id).join('&')
      window.open(this.$baseUrl + '/assets/qrcode/batch?' + params + '&token=' + this.user.token)
    },
    handleImport() {
      this.importVisible = true
    },
    handleDetail(row) {
      this.detail = row
      this.qrUrl = location.origin + '/scan/' + encodeURIComponent(row.no || row.id)
      this.qrSrc = this.$baseUrl + '/qr/png?size=300&text=' + encodeURIComponent(this.qrUrl)
      this.detailVisible = true
    },
    showQr(row) {
      this.qrUrl = location.origin + '/scan/' + encodeURIComponent(row.no || row.id)
      this.qrSrc = this.$baseUrl + '/qr/png?size=300&text=' + encodeURIComponent(this.qrUrl)
      this.qrName = ((row.no || row.name || '资产') + '-二维码').replace(/[\\/:*?"<>|]/g, '-')
      this.qrVisible = true
    },
    downloadQr() {
      fetch(this.qrSrc).then(res => res.blob()).then(blob => {
        const a = document.createElement('a')
        a.href = URL.createObjectURL(blob)
        a.download = this.qrName + '.png'
        a.click()
        URL.revokeObjectURL(a.href)
      }).catch(() => {
        this.$message.error('下载失败，请右键图片另存为')
      })
    },
    downloadTemplate() {
      window.open(this.$baseUrl+'/assets/template?token=' + this.user.token)
    },
    beforeImport(file) {
      const isExcel = file.type === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ||
                      file.type === 'application/vnd.ms-excel'
      if (!isExcel) {
        this.$message.error('只能上传Excel文件!')
        return false
      }
      return true
    },
    handleImportSuccess(response) {
      const errors = (response.data && response.data.errors) || []
      if (response.code === '200') {
        this.$message.success(response.msg || '导入成功')
        this.importVisible = false
        this.load(1)
      } else {
        this.$message.error(response.msg || '导入失败')
      }
      if (errors.length) {
        const html = errors
            .map(e => '第 ' + e.row + ' 行：' + this.escapeHtml(e.msg))
            .join('<br/>')
        this.$alert(html, '失败明细（共 ' + errors.length + ' 条）', {
          dangerouslyUseHTMLString: true,
          confirmButtonText: '知道了'
        })
      }
    },
    escapeHtml(text) {
      return String(text == null ? '' : text)
          .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
          .replace(/"/g, '&quot;').replace(/'/g, '&#39;')
    },
    handleImportError() {
      this.$message.error('导入失败，请检查文件格式是否正确')
    },
    loadDepartment(){
      this.$request.get('/department/selectAll').then(res => {
        this.departmentList = res.data
      })
      this.$request.get('/department/selectTree').then(res => {
        this.departmentTree = res.data
      })
    },
    loadCategory(){
      this.$request.get('/category/selectAll').then(res=>{
        this.categoryList=res.data||[]
      })
    },
    loadStaff(){
      this.$request.get('/staff/selectAll', { params: { status: '在职' } }).then(res=>{
        this.staffList=res.data||[]
      })
    },
    handleImgSuccess(response) {
      this.form.img = response.data
    },
    handleNodeClick(node) {
      this.$set(this.form, 'departmentId', node.id)
      // 未选公司时由所选部门反推公司
      if (!this.form.companyId) this.$set(this.form, 'companyId', node.companyId)
      // 责任人不在新部门时不保留
      const staff = this.staffList.find(s => s.id === this.form.staffId)
      if (staff && staff.departmentId !== node.id) this.$set(this.form, 'staffId', null)
      this.$refs.selectTree.blur()
    },
    fieldOptionList(field) {
      if (!field || !field.options) return []
      return String(field.options).split(',').map(s => s.trim()).filter(Boolean)
    },
    // 某个一级分类下的可选二级分类；“一级分类本身”始终保留，兼容未细分资产
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
    handleSearchCategoryParentChange() {
      this.category = null
      this.load(1)
    },
    handleFormCategoryParentChange() {
      this.$set(this.form, 'category', null)
    },
    handleAdd() {
      const form = { categoryParentId: null }
      // 预置自定义字段，保证 v-model 写入是响应式的
      this.customFields.forEach(f => { form[f.fieldKey] = null })
      this.form = form
      this.fromVisible = true
    },
    handleEdit(row) {
      this.form = JSON.parse(JSON.stringify(row))
      // 根据资产分类名称反查所属一级分类
      const cat = this.categoryList.find(c => c.name === row.category)
      this.$set(this.form, 'categoryParentId', cat ? (cat.pid || cat.id) : null)
      this.fromVisible = true
    },
    genNo() {
      if (!this.form.category) {
        this.$message.warning('请先选择二级分类')
        return
      }
      this.$request.get('/numberRule/next', {
        params: { category: this.form.category }
      }).then(res => {
        if (res.code === '200') {
          this.$set(this.form, 'no', res.data)
        } else {
          this.$message.error(res.msg)
        }
      })
    },
    save() {
      // 公司与部门联动：选了公司必须选部门，否则公司无法落库（公司由部门关联得出）
      if (this.form.companyId && !this.form.departmentId) {
        this.$message.warning('已选择所属公司，请继续选择' + this.$field('departmentName'))
        return
      }
      this.$refs.formRef.validate((valid) => {
        if (valid) {
          const payload = JSON.parse(JSON.stringify(this.form))
          delete payload.categoryParentId
          this.$request({
            url: payload.id ? '/assets/update' : '/assets/add',
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
        }
      })
    },
    del(id) {
      this.$confirm('您确定删除吗？', '确认删除', {type: "warning"}).then(() => {
        this.$request.delete('/assets/delete/' + id).then(res => {
          if (res.code === '200') {
            this.$message.success('操作成功')
            this.load(1)
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
      this.$confirm('您确定批量删除这些数据吗？', '确认删除', {type: "warning"}).then(() => {
        this.$request.delete('/assets/delete/batch', {data: this.ids}).then(res => {
          if (res.code === '200') {
            this.$message.success('操作成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {})
    },
    buildParams() {
      const params = {
        pageNum: this.pageNum,
        pageSize: this.pageSize,
        name: this.name,
        category: this.category,
        no: this.no,
        status: this.status,
        companyId: this.companyId,
        departmentId: this.departmentId,
        staffId: this.staffId,
        location: this.location
      }
      if (this.dateRange && this.dateRange.length === 2) {
        params.dateStart = this.dateRange[0]
        params.dateEnd = this.dateRange[1]
      }
      return params
    },
    load(pageNum) {
      if (pageNum) this.pageNum = pageNum
      this.$request.get('/assets/selectPage', { params: this.buildParams() }).then(res => {
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
      this.categoryParentId = null
      this.category = null
      this.no = null
      this.status = null
      this.companyId = null
      this.departmentId = null
      this.staffId = null
      this.location = null
      this.dateRange = []
      this.load(1)
    },
    handleCurrentChange(pageNum) {
      this.load(pageNum)
    },
    handleSizeChange(size) {
      this.pageSize = size
      this.load(1)
    }
  }
}
</script>

<style scoped>
.detail-wrap { padding: 0 10px; }
.detail-img { margin-bottom: 16px; text-align: center; }

.asset-table {
  font-size: 14px;
}

.asset-table >>> .cell {
  line-height: 22px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.asset-table >>> .el-table__header-wrapper th .cell {
  font-size: 13px;
  font-weight: 600;
}

.asset-table >>> td.el-table__cell {
  padding: 11px 0;
}

.asset-table >>> .el-button--text {
  font-size: 13px;
}
</style>
