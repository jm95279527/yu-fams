<template>
  <div>
    <!-- 任务列表 -->
    <div class="btn-div">
      <el-input v-model="query.name" placeholder="任务名称" class="searchInput" clearable></el-input>
      <el-select v-model="query.status" placeholder="状态" class="searchInput" clearable style="margin-left: 8px; width: 120px">
        <el-option label="盘点中" value="盘点中"></el-option>
        <el-option label="已完成" value="已完成"></el-option>
      </el-select>
      <el-button type="primary" icon="el-icon-search" style="margin-left: 8px" @click="load(1)">查询</el-button>
      <el-button type="success" icon="el-icon-plus" @click="openCreate">新建盘点</el-button>
    </div>

    <el-table :data="tableData" border stripe>
      <el-table-column prop="name" label="任务名称" min-width="160" show-overflow-tooltip></el-table-column>
      <el-table-column prop="scopeName" label="盘点范围" min-width="130"></el-table-column>
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="scope">
          <el-tag :type="scope.row.status === '已完成' ? 'success' : 'warning'" size="small">{{ scope.row.status }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="应盘/已盘" width="100" align="center">
        <template slot-scope="scope">
          {{ scope.row.totalCount }} / {{ scannedOf(scope.row) }}
        </template>
      </el-table-column>
      <el-table-column label="正常" width="70" align="center">
        <template slot-scope="scope"><span style="color:#67c23a">{{ scope.row.normalCount }}</span></template>
      </el-table-column>
      <el-table-column label="盘盈" width="70" align="center">
        <template slot-scope="scope"><span style="color:#409eff">{{ scope.row.profitCount }}</span></template>
      </el-table-column>
      <el-table-column label="盘亏" width="70" align="center">
        <template slot-scope="scope"><span style="color:#f56c6c">{{ scope.row.lossCount }}</span></template>
      </el-table-column>
      <el-table-column label="异常" width="70" align="center">
        <template slot-scope="scope"><span style="color:#e6a23c">{{ scope.row.abnormalCount }}</span></template>
      </el-table-column>
      <el-table-column label="待处理差异" width="90" align="center">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.pendingDiffCount > 0" type="danger" size="small">{{ scope.row.pendingDiffCount }}</el-tag>
          <span v-else style="color:#c0c4cc">0</span>
        </template>
      </el-table-column>
      <el-table-column prop="creatorName" label="创建人" width="100"></el-table-column>
      <el-table-column prop="createTime" label="创建时间" width="160"></el-table-column>
      <el-table-column prop="finishTime" label="完成时间" width="160">
        <template slot-scope="scope">{{ scope.row.finishTime || '-' }}</template>
      </el-table-column>
      <el-table-column label="操作" width="330" fixed="right" align="center">
        <template slot-scope="scope">
          <el-button :type="scope.row.status === '已完成' ? 'info' : 'primary'" icon="el-icon-full-screen" size="mini" @click="openBoard(scope.row)">
            {{ scope.row.status === '已完成' ? '查看报告' : '去盘点' }}
          </el-button>
          <el-button type="success" icon="el-icon-picture-outline" size="mini" @click="openQr(scope.row)">二维码</el-button>
          <el-button type="warning" icon="el-icon-download" size="mini" @click="exportReport(scope.row)">报告</el-button>
          <el-button v-if="scope.row.status === '盘点中'" type="danger" icon="el-icon-delete" size="mini" @click="remove(scope.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next"
      :total="total" :page-size="query.pageSize" :current-page="query.pageNum"
      :page-sizes="[10, 20, 50]"
      @current-change="onPageChange" @size-change="onSizeChange">
    </el-pagination>

    <!-- 新建盘点任务 -->
    <el-dialog title="新建盘点任务" :visible.sync="createVisible" width="560px" @closed="resetCreate">
      <el-form :model="form" :rules="rules" ref="createForm" label-width="90px">
        <el-form-item label="任务名称" prop="name">
          <el-input v-model="form.name" maxlength="100" show-word-limit></el-input>
        </el-form-item>
        <el-form-item label="盘点范围" prop="scopeType">
          <el-radio-group v-model="form.scopeType" @change="form.scopeId = null">
            <el-radio label="ALL">全部资产</el-radio>
            <el-radio label="DEPT">按部门</el-radio>
            <el-radio label="COMPANY">按公司</el-radio>
            <el-radio label="CATEGORY">按分类</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="选择公司" v-if="form.scopeType === 'COMPANY'">
          <el-select v-model="form.scopeId" filterable placeholder="选择公司" style="width: 100%">
            <el-option v-for="c in companyList" :key="c.id" :label="c.name" :value="c.id"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="选择部门" v-if="form.scopeType === 'DEPT'">
          <el-select v-model="form.scopeId" filterable placeholder="选择部门" style="width: 100%">
            <el-option v-for="d in departmentList" :key="d.id" :label="d.label || d.name" :value="d.id"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="选择分类" v-if="form.scopeType === 'CATEGORY'">
          <el-select v-model="form.scopeId" filterable placeholder="选择分类" style="width: 100%">
            <el-option v-for="c in selectableCategories" :key="c.id" :label="c.label" :value="c.id"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="200"></el-input>
        </el-form-item>
        <div style="color:#909399; font-size:12px; padding-left:90px">
          创建后将按当前台账快照生成盘点清单，报废资产不纳入盘点；扫码盘到范围外资产自动登记盘盈。
        </div>
      </el-form>
      <div slot="footer">
        <el-button @click="createVisible = false">取消</el-button>
        <el-button type="primary" @click="submitCreate">创建并开始盘点</el-button>
      </div>
    </el-dialog>

    <!-- 盘点工作台 -->
    <el-dialog :title="boardTitle" :visible.sync="boardVisible" width="90%" top="5vh"
               :close-on-click-modal="false" @closed="onBoardClosed">
      <!-- 统计卡片 -->
      <el-row :gutter="10" class="stat-row">
        <el-col :span="3"><div class="stat-card"><div class="stat-num">{{ task.totalCount || 0 }}</div><div class="stat-label">应盘</div></div></el-col>
        <el-col :span="3"><div class="stat-card"><div class="stat-num" style="color:#409eff">{{ unscanned }}</div><div class="stat-label">未盘</div></div></el-col>
        <el-col :span="3"><div class="stat-card"><div class="stat-num" style="color:#67c23a">{{ task.normalCount || 0 }}</div><div class="stat-label">正常</div></div></el-col>
        <el-col :span="3"><div class="stat-card"><div class="stat-num" style="color:#e6a23c">{{ task.abnormalCount || 0 }}</div><div class="stat-label">异常</div></div></el-col>
        <el-col :span="3"><div class="stat-card"><div class="stat-num" style="color:#409eff">{{ task.profitCount || 0 }}</div><div class="stat-label">盘盈</div></div></el-col>
        <el-col :span="3"><div class="stat-card"><div class="stat-num" style="color:#f56c6c">{{ task.lossCount || 0 }}</div><div class="stat-label">盘亏</div></div></el-col>
        <el-col :span="3">
          <div class="stat-card">
            <div class="stat-num" :style="(task.pendingDiffCount || 0) > 0 ? 'color:#f56c6c' : 'color:#c0c4cc'">{{ task.pendingDiffCount || 0 }}</div>
            <div class="stat-label">待处理差异</div>
          </div>
        </el-col>
        <el-col :span="24">
          <div class="stat-card" style="height:44px">
            <el-progress :percentage="progress" :status="progress === 100 ? 'success' : ''" :stroke-width="12"></el-progress>
            <div class="stat-label">盘点进度（{{ scannedOf(task) }}/{{ task.totalCount || 0 }}）</div>
          </div>
        </el-col>
      </el-row>

      <!-- 扫码区 -->
      <div class="scan-box" v-if="task.status === '盘点中'">
        <el-input v-model="scanCode" :placeholder="'扫描/输入资产二维码、' + $field('no') + '或ID后回车'"
                  class="scan-input" clearable @keyup.enter.native="doScan" autofocus>
          <i slot="prefix" class="el-icon-full-screen"></i>
        </el-input>
        <el-input v-model="scanLocation" placeholder="实盘地点（与台账不符自动标异常）" class="scan-loc"></el-input>
        <el-checkbox v-model="scanAbnormal" border>标记异常</el-checkbox>
        <el-input v-model="scanComment" placeholder="备注（选填）" class="scan-cmt"></el-input>
        <el-button type="primary" icon="el-icon-camera" @click="doScan">确认盘点</el-button>
        <el-divider></el-divider>
        <el-select v-model="profitAssetId" filterable clearable placeholder="范围外资产盘盈登记：搜索资产" class="profit-select">
          <el-option v-for="a in assetOptions" :key="a.id"
                     :label="a.no + ' ' + a.name" :value="a.id"></el-option>
        </el-select>
        <el-button type="success" plain icon="el-icon-plus" @click="registerProfit">登记盘盈</el-button>
      </div>
      <el-alert v-else title="该盘点任务已完成，以下为盘点报告；盘盈/盘亏/异常差异仍可继续登记处理结果" type="success" :closable="false" show-icon style="margin-bottom:10px"></el-alert>

      <!-- 明细筛选 -->
      <div class="item-filter">
        <el-radio-group v-model="itemStatus" size="small" @change="loadItems">
          <el-radio-button label="">全部({{ task.totalCount || 0 }})</el-radio-button>
          <el-radio-button label="未盘">未盘({{ unscanned }})</el-radio-button>
          <el-radio-button label="正常">正常({{ task.normalCount || 0 }})</el-radio-button>
          <el-radio-button label="异常">异常({{ task.abnormalCount || 0 }})</el-radio-button>
          <el-radio-button label="盘盈">盘盈({{ task.profitCount || 0 }})</el-radio-button>
          <el-radio-button label="盘亏">盘亏({{ task.lossCount || 0 }})</el-radio-button>
        </el-radio-group>
        <el-input v-model="itemKeyword" placeholder="编号/名称" size="small" style="width:200px; margin-left:10px" clearable @keyup.enter.native="loadItems">
          <el-button slot="append" icon="el-icon-search" @click="loadItems"></el-button>
        </el-input>
        <el-button v-if="task.status === '盘点中'" type="danger" plain size="small" icon="el-icon-circle-check" style="float:right" @click="finishTask">
          完成盘点
        </el-button>
      </div>

      <el-table :data="items" border size="small" height="380" style="margin-top:10px">
        <el-table-column prop="assetsNo" :label="$field('no')" width="140"></el-table-column>
        <el-table-column prop="assetsName" :label="$field('name')" min-width="120" show-overflow-tooltip></el-table-column>
        <el-table-column prop="model" :label="$field('model')" width="120" show-overflow-tooltip></el-table-column>
        <el-table-column label="范围" width="70" align="center">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.isExtra === 1" type="danger" size="mini">范围外</el-tag>
            <span v-else style="color:#c0c4cc">-</span>
          </template>
        </el-table-column>
        <el-table-column prop="category" :label="$field('category')" width="100"></el-table-column>
        <el-table-column prop="departmentName" :label="'台账' + $field('departmentName')" width="120">
          <template slot-scope="scope">{{ scope.row.departmentName || '-' }}</template>
        </el-table-column>
        <el-table-column prop="staffName" :label="$field('staffName')" width="90">
          <template slot-scope="scope">{{ scope.row.staffName || '-' }}</template>
        </el-table-column>
        <el-table-column :label="'台账' + $field('location')" width="120">
          <template slot-scope="scope">{{ scope.row.location || '-' }}</template>
        </el-table-column>
        <el-table-column :label="'实盘' + $field('location')" width="120">
          <template slot-scope="scope">
            <span :style="locMismatch(scope.row) ? 'color:#e6a23c;font-weight:bold' : ''">{{ scope.row.actualLocation || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="结果" width="80" align="center">
          <template slot-scope="scope">
            <el-tag :type="itemTagType(scope.row.itemStatus)" size="mini">{{ scope.row.itemStatus }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="差异处理" width="150" align="center">
          <template slot-scope="scope">
            <template v-if="['盘盈', '盘亏', '异常'].indexOf(scope.row.itemStatus) >= 0">
              <el-tag v-if="scope.row.dealStatus === '待处理'" type="danger" size="mini">待处理</el-tag>
              <el-tooltip v-else-if="scope.row.dealStatus === '已处理'" placement="top">
                <div slot="content">
                  <div>方式：{{ scope.row.dealType }}</div>
                  <div>处理人：{{ scope.row.dealUser }}</div>
                  <div>时间：{{ scope.row.dealTime }}</div>
                  <div v-if="scope.row.dealRemark">说明：{{ scope.row.dealRemark }}</div>
                </div>
                <el-tag type="success" size="mini">已处理·{{ scope.row.dealType }}</el-tag>
              </el-tooltip>
              <span v-else style="color:#c0c4cc">-</span>
            </template>
            <span v-else style="color:#c0c4cc">-</span>
          </template>
        </el-table-column>
        <el-table-column prop="scannerName" label="盘点人" width="90">
          <template slot-scope="scope">{{ scope.row.scannerName || '-' }}</template>
        </el-table-column>
        <el-table-column prop="scanTime" label="盘点时间" width="150">
          <template slot-scope="scope">{{ scope.row.scanTime || '-' }}</template>
        </el-table-column>
        <el-table-column prop="comment" label="备注" min-width="120" show-overflow-tooltip>
          <template slot-scope="scope">{{ scope.row.comment || '-' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="210" align="center" fixed="right">
          <template slot-scope="scope">
            <template v-if="['盘盈', '盘亏', '异常'].indexOf(scope.row.itemStatus) >= 0">
              <el-button v-if="scope.row.dealStatus === '待处理'" type="text" size="mini" style="color:#e6a23c" @click="openDeal(scope.row)">处理差异</el-button>
              <template v-else-if="scope.row.dealStatus === '已处理'">
                <el-button v-if="scope.row.itemStatus === '盘亏' && scope.row.dealType === '报损'" type="text" size="mini" @click="gotoBiz('/assetsScrap')">去报损</el-button>
                <el-button v-if="scope.row.itemStatus === '异常' && scope.row.dealType === '调拨修正'" type="text" size="mini" @click="gotoBiz('/assetsTransfer')">去调拨</el-button>
                <el-button v-if="scope.row.itemStatus === '盘盈' && scope.row.dealType === '补录入账'" type="text" size="mini" @click="gotoBiz('/assetsIn')">去入库</el-button>
              </template>
            </template>
            <template v-if="task.status === '盘点中' && (scope.row.itemStatus === '正常' || scope.row.itemStatus === '异常')">
              <el-button type="text" size="mini" @click="toggleMark(scope.row)">
                {{ scope.row.itemStatus === '正常' ? '标为异常' : '恢复正常' }}
              </el-button>
              <el-button type="text" size="mini" @click="editComment(scope.row)">备注</el-button>
            </template>
          </template>
        </el-table-column>
      </el-table>

      <!-- 盘点人工作量 -->
      <el-collapse v-model="workloadActive" style="margin-top:8px">
        <el-collapse-item name="1">
          <template slot="title">
            <span style="font-weight:bold">盘点人工作量统计（{{ workloadData.length }} 人）</span>
          </template>
          <el-table :data="workloadData" border size="mini">
            <el-table-column prop="scannerName" label="盘点人" min-width="100"></el-table-column>
            <el-table-column prop="total" label="盘点数" width="90" align="center"></el-table-column>
            <el-table-column prop="normalCnt" label="正常" width="90" align="center">
              <template slot-scope="scope"><span style="color:#67c23a">{{ scope.row.normalCnt }}</span></template>
            </el-table-column>
            <el-table-column prop="abnormalCnt" label="异常" width="90" align="center">
              <template slot-scope="scope"><span style="color:#e6a23c">{{ scope.row.abnormalCnt }}</span></template>
            </el-table-column>
            <el-table-column prop="profitCnt" label="盘盈" width="90" align="center">
              <template slot-scope="scope"><span style="color:#409eff">{{ scope.row.profitCnt }}</span></template>
            </el-table-column>
            <el-table-column prop="lossCnt" label="盘亏" width="90" align="center">
              <template slot-scope="scope"><span style="color:#f56c6c">{{ scope.row.lossCnt }}</span></template>
            </el-table-column>
          </el-table>
        </el-collapse-item>
      </el-collapse>
    </el-dialog>

    <!-- 盘点单二维码 -->
    <el-dialog title="盘点单二维码" :visible.sync="qrVisible" width="420px" @closed="qrRow = {}">
      <div class="qr-box" v-if="qrRow.accessCode">
        <div class="qr-title">{{ qrRow.name }}</div>
        <div class="qr-scope">{{ qrRow.scopeName }} · {{ qrRow.status }}</div>
        <img :src="qrImg" class="qr-img" alt="盘点单二维码" />
        <div class="qr-link" @click="copyQrLink">{{ qrLink }}</div>
        <div class="qr-tip">
          手机扫码进入盘点页面，扫码资产二维码即可盘点；盘点单只能在后台完结或删除。
        </div>
      </div>
      <div slot="footer" class="qr-footer">
        <el-button @click="copyQrLink">复制链接</el-button>
        <el-button type="primary" icon="el-icon-printer" @click="printQr">打印二维码</el-button>
        <el-button v-if="qrRow.status === '盘点中'" type="success" @click="goBoardFromQr">进入工作台</el-button>
      </div>
    </el-dialog>

    <!-- 处理盘点差异 -->
    <el-dialog :title="'处理盘点差异 - ' + (dealRow.assetsNo || '')" :visible.sync="dealVisible" width="480px" append-to-body>
      <el-form :model="dealForm" label-width="90px">
        <el-form-item label="资产">
          <span>{{ dealRow.assetsName }}（{{ dealRow.itemStatus }}）</span>
        </el-form-item>
        <el-form-item label="处理方式" required>
          <el-select v-model="dealForm.dealType" placeholder="请选择处理方式" style="width:100%">
            <el-option v-for="t in dealOptions" :key="t" :label="t" :value="t"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="处理说明">
          <el-input v-model="dealForm.dealRemark" type="textarea" :rows="3" maxlength="300" show-word-limit
                    :placeholder="dealRemarkTip"></el-input>
        </el-form-item>
        <div style="color:#909399;font-size:12px;padding-left:90px">
          台账变更不自动执行，提交后可通过“去报损/去调拨/去入库”入口走原有审批流程。
        </div>
      </el-form>
      <div slot="footer">
        <el-button @click="dealVisible = false">取消</el-button>
        <el-button type="primary" @click="submitDeal">确认处理</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'AssetsInventory',
  data() {
    return {
      user: JSON.parse(localStorage.getItem('xm-user') || '{}'),
      tableData: [],
      total: 0,
      query: { name: '', status: '', pageNum: 1, pageSize: 10 },
      departmentList: [],
      companyList: [],
      categoryList: [],
      assetOptions: [],
      // 新建
      createVisible: false,
      form: this.defaultForm(),
      rules: { name: [{ required: true, message: '请填写任务名称', trigger: 'blur' }] },
      // 工作台
      boardVisible: false,
      task: {},
      items: [],
      itemStatus: '',
      itemKeyword: '',
      scanCode: '',
      scanLocation: '',
      scanAbnormal: false,
      scanComment: '',
      profitAssetId: null,
      // 工作量统计
      workloadActive: [],
      workloadData: [],
      // 盘点单二维码
      qrVisible: false,
      qrRow: {},
      // 差异处理
      dealVisible: false,
      dealRow: {},
      dealForm: { dealType: '', dealRemark: '' }
    }
  },
  computed: {
    // 盘点按分类精确匹配：只列二级分类 + 没有二级分类的一级分类
    selectableCategories() {
      return this.categoryList
        .filter(c => c.pid || !this.categoryList.some(x => x.pid === c.id))
        .map(c => ({
          ...c,
          label: c.pid ? ((c.parentName ? c.parentName + ' / ' : '') + c.name) : c.name
        }))
    },
    boardTitle() {
      return (this.task.status === '已完成' ? '盘点报告：' : '盘点工作台：') + (this.task.name || '')
    },
    unscanned() {
      const t = this.task
      return Math.max((t.totalCount || 0) - (t.normalCount || 0) - (t.abnormalCount || 0) - (t.profitCount || 0) - (t.lossCount || 0), 0)
    },
    progress() {
      if (!this.task.totalCount) return 0
      const done = this.scannedOf(this.task)
      return Math.min(Math.round(done * 100 / this.task.totalCount), 100)
    },
    dealOptions() {
      return {
        盘亏: ['报损', '赔偿', '挂账待查', '误盘'],
        盘盈: ['补录入账', '寄存待查', '误盘'],
        异常: ['调拨修正', '信息更正', '误盘']
      }[this.dealRow.itemStatus] || []
    },
    dealRemarkTip() {
      const map = {
        报损: '说明盘亏原因及报损去向，随后请前往资产报废发起单据',
        赔偿: '记录责任人与赔偿金额',
        补录入账: '说明资产来源，随后请前往资产入库补录',
        调拨修正: '记录实际使用部门/人，随后请前往资产调拨发起单据',
        误盘: '说明误盘情况'
      }
      return map[this.dealForm.dealType] || '可填写处理情况说明'
    },
    qrLink() {
      if (!this.qrRow.accessCode) return ''
      return window.location.origin + '/inventory/' + this.qrRow.accessCode
    },
    qrImg() {
      if (!this.qrLink) return ''
      return process.env.VUE_APP_BASEURL + '/qr/png?size=320&text=' + encodeURIComponent(this.qrLink)
    }
  },
  created() {
    this.loadBase()
    this.load()
  },
  methods: {
    defaultForm() {
      const d = new Date()
      return {
        name: d.getFullYear() + '年' + (d.getMonth() + 1) + '月资产盘点',
        scopeType: 'ALL',
        scopeId: null,
        remark: ''
      }
    },
    scannedOf(row) {
      return (row.normalCount || 0) + (row.abnormalCount || 0) + (row.profitCount || 0) + (row.lossCount || 0)
    },
    loadBase() {
      this.$request.get('/department/selectAll').then(res => { this.departmentList = res.data || [] })
      this.$request.get('/assetsInventory/companies').then(res => { this.companyList = res.data || [] })
      this.$request.get('/category/selectAll').then(res => { this.categoryList = res.data || [] })
      this.$request.get('/assets/selectAll').then(res => {
        const data = res.data
        this.assetOptions = Array.isArray(data) ? data : (data.list || [])
      })
    },
    load(pageNum) {
      if (pageNum) this.query.pageNum = pageNum
      this.$request.get('/assetsInventory/selectPage', { params: this.query }).then(res => {
        this.tableData = res.data.list || []
        this.total = res.data.total || 0
      })
    },
    onPageChange(p) { this.load(p) },
    onSizeChange(size) { this.query.pageSize = size; this.load(1) },
    itemTagType(s) {
      return { 正常: 'success', 异常: 'warning', 盘盈: '', 盘亏: 'danger', 未盘: 'info' }[s] || 'info'
    },
    locMismatch(row) {
      return row.actualLocation && row.location && row.actualLocation !== row.location
    },

    // ---------- 新建任务 ----------
    openCreate() {
      this.form = this.defaultForm()
      this.createVisible = true
      this.$nextTick(() => this.$refs.createForm && this.$refs.createForm.clearValidate())
    },
    resetCreate() {
      this.form = this.defaultForm()
      if (this.$refs.createForm) this.$refs.createForm.clearValidate()
    },
    submitCreate() {
      this.$refs.createForm.validate(valid => {
        if (!valid) return
        if (this.form.scopeType !== 'ALL' && !this.form.scopeId) {
          const tips = { DEPT: '请选择部门', COMPANY: '请选择公司', CATEGORY: '请选择分类' }
          this.$message.warning(tips[this.form.scopeType] || '请选择盘点范围')
          return
        }
        this.$request.post('/assetsInventory/add', this.form).then(res => {
          this.$message.success('盘点任务已创建，共 ' + (res.data.totalCount || 0) + ' 项资产')
          this.createVisible = false
          this.load(1)
          this.$nextTick(() => this.openQr(res.data))
        })
      })
    },

    // ---------- 盘点单二维码 ----------
    openQr(row) {
      this.qrRow = row || {}
      this.qrVisible = true
    },
    goBoardFromQr() {
      const row = this.qrRow
      this.qrVisible = false
      this.$nextTick(() => this.openBoard(row))
    },
    copyQrLink() {
      if (!this.qrLink) return
      const done = () => this.$message.success('盘点链接已复制')
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(this.qrLink).then(done).catch(() => this.fallbackCopy(done))
      } else {
        this.fallbackCopy(done)
      }
    },
    fallbackCopy(done) {
      const input = document.createElement('input')
      input.value = this.qrLink
      document.body.appendChild(input)
      input.select()
      try {
        document.execCommand('copy')
        done()
      } catch (e) {
        this.$message.warning('复制失败，请手动选择链接复制')
      }
      document.body.removeChild(input)
    },
    printQr() {
      if (!this.qrRow.accessCode) return
      const win = window.open('', '_blank', 'width=520,height=720')
      if (!win) {
        this.$message.warning('浏览器阻止了弹窗，请允许弹窗后重试')
        return
      }
      const esc = s => String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      win.document.write('<!DOCTYPE html><html><head><meta charset="utf-8"><title>盘点单二维码</title>'
        + '<style>body{font-family:"Microsoft YaHei",sans-serif;text-align:center;padding:20px;color:#303133}'
        + 'h2{font-size:20px;margin:6px 0}h3{font-size:14px;font-weight:normal;color:#666;margin:4px 0 16px}'
        + 'img{width:300px;height:300px}'
        + '.link{font-size:12px;color:#666;word-break:break-all;margin-top:12px}'
        + '.tip{font-size:12px;color:#999;margin-top:10px}</style></head><body>'
        + '<h2>' + esc(this.qrRow.name) + '</h2>'
        + '<h3>' + esc(this.qrRow.scopeName) + '</h3>'
        + '<img src="' + this.qrImg + '" onload="setTimeout(function(){window.print()},300)">'
        + '<div class="link">' + esc(this.qrLink) + '</div>'
        + '<div class="tip">手机扫码进入盘点页面，扫描资产二维码进行盘点</div>'
        + '</body></html>')
      win.document.close()
    },

    // ---------- 工作台 ----------
    openBoard(row) {
      this.task = row
      this.itemStatus = ''
      this.itemKeyword = ''
      this.workloadData = []
      this.workloadActive = []
      this.boardVisible = true
      this.loadTask()
      this.loadItems()
      this.loadWorkload()
    },
    onBoardClosed() {
      this.task = {}
      this.items = []
      this.scanCode = this.scanLocation = this.scanComment = ''
      this.scanAbnormal = false
      this.profitAssetId = null
      this.load()
    },
    loadTask() {
      this.$request.get('/assetsInventory/selectById/' + this.task.id).then(res => {
        this.task = res.data
      })
    },
    loadItems() {
      this.$request.get('/assetsInventory/items/' + this.task.id, {
        params: { itemStatus: this.itemStatus, keyword: this.itemKeyword }
      }).then(res => { this.items = res.data || [] })
    },
    doScan() {
      const code = (this.scanCode || '').trim()
      if (!code) {
        this.$message.warning('请扫描或输入资产二维码/编号')
        return
      }
      this.$request.post('/assetsInventory/scan/' + this.task.id, {
        code: code,
        actualLocation: this.scanLocation,
        abnormal: this.scanAbnormal,
        comment: this.scanComment
      }).then(res => {
        const it = res.data
        if (it.itemStatus === '正常') {
          this.$message.success('盘点正常：' + it.assetsNo + ' ' + it.assetsName)
        } else if (it.itemStatus === '异常') {
          this.$message.warning('已标记异常：' + it.assetsNo + '（实盘地点与台账不符）')
        } else if (it.itemStatus === '盘盈') {
          this.$message({ type: 'success', message: '范围外资产，已登记盘盈：' + it.assetsNo })
        }
        this.scanCode = ''
        this.scanLocation = ''
        this.scanComment = ''
        this.scanAbnormal = false
        this.loadTask()
        this.loadItems()
      })
    },
    registerProfit() {
      if (!this.profitAssetId) {
        this.$message.warning('请先搜索选择资产')
        return
      }
      this.$request.post('/assetsInventory/scan/' + this.task.id, { code: String(this.profitAssetId) }).then(res => {
        this.$message.success('已登记盘盈：' + res.data.assetsNo)
        this.profitAssetId = null
        this.loadTask()
        this.loadItems()
      })
    },
    toggleMark(row) {
      const target = row.itemStatus === '正常' ? '异常' : '正常'
      this.$confirm('确认将 ' + row.assetsNo + ' 标记为「' + target + '」？', '标记盘点结果', { type: 'warning' }).then(() => {
        this.$request.post('/assetsInventory/markItem/' + row.id, { itemStatus: target }).then(() => {
          this.$message.success('已标记为' + target)
          this.loadTask()
          this.loadItems()
        })
      }).catch(() => {})
    },
    editComment(row) {
      this.$prompt('请输入备注', '盘点备注 - ' + row.assetsNo, {
        inputType: 'textarea',
        inputValue: row.comment || '',
        confirmButtonText: '保存'
      }).then(({ value }) => {
        this.$request.post('/assetsInventory/markItem/' + row.id, { itemStatus: row.itemStatus, comment: value }).then(() => {
          this.$message.success('备注已保存')
          this.loadTask()
          this.loadItems()
        })
      }).catch(() => {})
    },
    // ---------- 差异处理 ----------
    openDeal(row) {
      this.dealRow = row
      this.dealForm = { dealType: '', dealRemark: '' }
      this.dealVisible = true
    },
    submitDeal() {
      if (!this.dealForm.dealType) {
        this.$message.warning('请选择处理方式')
        return
      }
      this.$request.post('/assetsInventory/dealItem/' + this.dealRow.id, {
        dealType: this.dealForm.dealType,
        dealRemark: this.dealForm.dealRemark
      }).then(() => {
        this.$message.success('差异已处理：' + this.dealForm.dealType)
        this.dealVisible = false
        this.loadTask()
        this.loadItems()
        this.loadWorkload()
      })
    },
    gotoBiz(path) {
      this.$router.push(path)
    },
    loadWorkload() {
      this.$request.get('/assetsInventory/workload/' + this.task.id).then(res => {
        this.workloadData = res.data || []
      })
    },
    finishTask() {
      this.$confirm('确认完成本次盘点？所有未盘到的资产将被记为「盘亏」，完成后不可再扫码。',
        '完成盘点', { type: 'warning', confirmButtonText: '确认完成' }).then(() => {
        this.$request.post('/assetsInventory/finish/' + this.task.id).then(res => {
          const d = res.data
          this.$message.success('盘点已完成：盘盈 ' + d.profitCount + '，盘亏 ' + d.lossCount + '，异常 ' + d.abnormalCount
            + '，待处理差异 ' + (d.pendingDiffCount || 0) + ' 项')
          this.task = d
          this.loadTask()
          this.loadItems()
          this.loadWorkload()
        })
      }).catch(() => {})
    },
    remove(row) {
      this.$confirm('确认删除盘点任务「' + row.name + '」及其全部明细？', '提示', { type: 'warning' }).then(() => {
        this.$request.delete('/assetsInventory/delete/' + row.id).then(() => {
          this.$message.success('删除成功')
          this.load()
        })
      }).catch(() => {})
    },
    exportReport(row) {
      const user = JSON.parse(localStorage.getItem('xm-user') || '{}')
      this.$request({
        url: '/assetsInventory/export/' + row.id,
        method: 'get',
        responseType: 'blob',
        headers: { token: user.token }
      }).then(res => {
        const blob = new Blob([res.data], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = '盘点报告-' + row.name + '.xlsx'
        a.click()
        URL.revokeObjectURL(url)
      })
    }
  }
}
</script>

<style scoped>
.btn-div { margin: 10px 0; display: flex; align-items: center; flex-wrap: wrap; }
.searchInput { width: 180px; }
.pager { margin-top: 15px; text-align: right; }
.stat-row { margin-bottom: 12px; }
.stat-card {
  background: #f5f7fa; border-radius: 6px; text-align: center;
  padding: 10px 4px; height: 72px; box-sizing: border-box;
  display: flex; flex-direction: column; justify-content: center;
}
.stat-num { font-size: 22px; font-weight: bold; color: #303133; line-height: 1.2; }
.stat-label { font-size: 12px; color: #909399; margin-top: 4px; }
.scan-box {
  background: #f0f9ff; border: 1px solid #d9ecff; border-radius: 6px;
  padding: 12px; display: flex; align-items: center; flex-wrap: wrap; gap: 8px;
}
.scan-input { width: 320px; }
.scan-loc { width: 240px; }
.scan-cmt { width: 200px; }
.profit-select { width: 360px; }
.item-filter { display: flex; align-items: center; flex-wrap: wrap; }
.qr-box { text-align: center; }
.qr-title { font-size: 17px; font-weight: 600; }
.qr-scope { font-size: 12px; color: #909399; margin-top: 4px; }
.qr-img { width: 260px; height: 260px; margin: 12px auto; display: block; }
.qr-link { font-size: 12px; color: #2f6fed; word-break: break-all; cursor: pointer; }
.qr-tip {
  font-size: 12px; color: #909399; line-height: 1.7; margin-top: 10px;
  text-align: left; background: #f5f7fa; padding: 8px 10px; border-radius: 6px;
}
.qr-footer { display: flex; justify-content: center; }
</style>
