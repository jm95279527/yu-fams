<template>
  <div class="inv-page" v-loading.fullscreen.lock="loading" element-loading-text="正在识别二维码...">
    <!-- 盘点单无效 -->
    <div class="inv-empty" v-if="notFound">
      <div class="inv-empty-icon">!</div>
      <div class="inv-empty-title">{{ errorMsg || '盘点单不存在' }}</div>
      <div class="inv-empty-tip">请确认扫描的是资产管理员提供的盘点单二维码</div>
    </div>

    <div class="inv-shell" v-else>
      <!-- 顶部任务信息 -->
      <header class="inv-head">
        <div class="inv-head-top">
          <div class="inv-title">{{ task.name || '资产盘点' }}</div>
          <span class="inv-status" :class="{ done: task.status === '已完成' }">{{ task.status || '-' }}</span>
        </div>
        <div class="inv-sub">{{ task.scopeName || '全部资产' }}</div>
        <div class="inv-stats">
          <div class="inv-stat"><b>{{ task.scannedCount || 0 }}</b><span>已盘</span></div>
          <div class="inv-stat"><b>{{ task.unscannedCount || 0 }}</b><span>未盘</span></div>
          <div class="inv-stat"><b>{{ task.totalCount || 0 }}</b><span>应盘</span></div>
        </div>
        <div class="inv-progress"><i :style="{ width: progress + '%' }"></i></div>
        <div class="inv-progress-text">盘点进度 {{ progress }}%</div>
      </header>

      <div class="inv-done-tip" v-if="task.status === '已完成'">
        本次盘点已完成，不能再扫码盘点，请联系资产管理员完成后续处理。
      </div>

      <!-- 已盘 / 未盘 -->
      <div class="inv-tabs">
        <div class="inv-tab" :class="{ active: tab === '已盘' }" @click="switchTab('已盘')">
          已盘 <em>{{ task.scannedCount || 0 }}</em>
        </div>
        <div class="inv-tab" :class="{ active: tab === '未盘' }" @click="switchTab('未盘')">
          未盘 <em>{{ task.unscannedCount || 0 }}</em>
        </div>
      </div>

      <!-- 资产列表 -->
      <div class="inv-list">
        <div class="inv-list-empty" v-if="!listLoading && !list.length">
          {{ tab === '已盘' ? '还没有盘点记录，点击底部按钮开始扫码盘点' : '未盘资产已全部盘完' }}
        </div>
        <div class="inv-card" v-for="it in list" :key="it.id">
          <div class="inv-card-head">
            <span class="inv-no">{{ it.assetsNo }}</span>
            <span class="inv-tag" :class="tagClass(it.itemStatus)">{{ it.itemStatus }}</span>
          </div>
          <div class="inv-name">
            {{ it.assetsName }}
            <span class="inv-extra" v-if="it.isExtra === 1">范围外</span>
          </div>
          <div class="inv-meta">{{ it.departmentName || '-' }} · {{ it.staffName || '-' }}</div>
          <div class="inv-meta">存放地点：{{ it.location || '-' }}</div>
          <div class="inv-scan-info" v-if="it.itemStatus !== '未盘'">
            <div>{{ it.scannerName || '-' }} · {{ it.scanTime || '-' }}</div>
            <div class="inv-comment" v-if="it.comment">备注：{{ it.comment }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- 底部扫码按钮 -->
    <div class="inv-footer" v-if="!notFound">
      <div class="inv-footer-inner">
        <button class="inv-scan-btn" :disabled="!canScan" @click="pickImage">
          <i class="el-icon-camera"></i> 扫码盘点
        </button>
        <div class="inv-manual" @click="openManual">扫不了？手动输入资产编号</div>
        <div class="inv-tip">拍照时请让二维码占满画面、保持对焦清晰</div>
      </div>
    </div>

    <input ref="fileInput" type="file" accept="image/*" capture="environment" class="inv-file" @change="onFile" />

    <!-- 扫码结果 -->
    <el-dialog :visible.sync="assetVisible" width="92%" custom-class="inv-dialog"
               :show-close="false" :close-on-click-modal="false" append-to-body>
      <div class="inv-dialog-body" v-if="asset">
        <div class="inv-dialog-title">{{ asset.name || '-' }}</div>
        <div class="inv-dialog-no">{{ asset.no || '-' }}</div>

        <div class="inv-alert danger" v-if="asset.scanned">
          <div class="inv-alert-title">该资产已盘点（{{ asset.itemStatus }}）</div>
          <div>盘点人：{{ asset.scannerName || '-' }}</div>
          <div>盘点时间：{{ asset.scanTime || '-' }}</div>
          <div v-if="asset.comment">备注：{{ asset.comment }}</div>
        </div>
        <div class="inv-alert warn" v-else-if="asset.outOfScope">
          该资产不在本次盘点范围内，确认后将登记为「盘盈」。
        </div>

        <div class="inv-info">
          <div class="inv-info-row"><span>资产编号</span><b>{{ asset.no || '-' }}</b></div>
          <div class="inv-info-row"><span>资产分类</span><b>{{ asset.category || '-' }}</b></div>
          <div class="inv-info-row" v-if="asset.model"><span>规格型号</span><b>{{ asset.model }}</b></div>
          <div class="inv-info-row"><span>所属公司</span><b>{{ asset.companyName || '-' }}</b></div>
          <div class="inv-info-row"><span>使用部门</span><b>{{ asset.departmentName || '-' }}</b></div>
          <div class="inv-info-row"><span>责任人</span><b>{{ asset.staffName || '-' }}</b></div>
          <div class="inv-info-row"><span>存放地点</span><b>{{ asset.location || '-' }}</b></div>
          <div class="inv-info-row"><span>资产状态</span><b>{{ asset.status || '-' }}</b></div>
        </div>

        <div class="inv-remark" v-if="!asset.scanned">
          <div class="inv-remark-label">盘点备注（选填）</div>
          <el-input v-model="comment" type="textarea" :rows="2" maxlength="200" show-word-limit
                    placeholder="如：实际存放位置、资产现状等"></el-input>
        </div>

        <div class="inv-dialog-actions" v-if="!asset.scanned">
          <el-button @click="assetVisible = false">取消</el-button>
          <el-button type="primary" :loading="submitting" @click="submitScan">
            {{ asset.outOfScope ? '登记盘盈' : '确认盘点' }}
          </el-button>
        </div>
        <div class="inv-dialog-actions" v-else>
          <el-button type="primary" @click="assetVisible = false">知道了</el-button>
        </div>
      </div>
    </el-dialog>

    <!-- 手动输入 -->
    <el-dialog title="手动输入资产编号" :visible.sync="manualVisible" width="86%"
               custom-class="inv-dialog" append-to-body>
      <el-input v-model="manualCode" placeholder="如 HMDZ0426100001" clearable
                @keyup.enter.native="manualLookup"></el-input>
      <div class="inv-dialog-actions" style="margin-top: 16px">
        <el-button @click="manualVisible = false">取消</el-button>
        <el-button type="primary" @click="manualLookup">查询</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'InventoryScan',
  data() {
    return {
      code: this.$route.params.code,
      task: {},
      tab: '未盘',
      list: [],
      listLoading: false,
      loading: false,
      notFound: false,
      errorMsg: '',
      asset: null,
      assetVisible: false,
      scannedCode: '',
      comment: '',
      submitting: false,
      manualVisible: false,
      manualCode: ''
    }
  },
  computed: {
    progress() {
      const total = this.task.totalCount || 0
      if (!total) return 0
      return Math.min(100, Math.round((this.task.scannedCount || 0) * 100 / total))
    },
    canScan() {
      return this.task.status !== '已完成'
    }
  },
  created() {
    this.loadTask()
    this.loadItems()
  },
  methods: {
    loadTask() {
      this.$request.get('/inventoryPublic/task/' + this.code).then(res => {
        if (res.code === '200') {
          this.task = res.data || {}
        } else {
          this.notFound = true
          this.errorMsg = res.msg || '盘点单不存在'
        }
      }).catch(() => {
        this.notFound = true
        this.errorMsg = '网络异常，请稍后重试'
      })
    },
    loadItems() {
      this.listLoading = true
      this.$request.get('/inventoryPublic/items/' + this.code, {
        params: { tab: this.tab }
      }).then(res => {
        this.listLoading = false
        if (res.code === '200') {
          this.list = res.data || []
        } else {
          this.$message.error(res.msg)
        }
      }).catch(() => {
        this.listLoading = false
      })
    },
    switchTab(tab) {
      if (this.tab === tab) return
      this.tab = tab
      this.loadItems()
    },
    pickImage() {
      if (!this.canScan) {
        this.$message.warning('盘点已完成，不能继续扫码')
        return
      }
      this.$refs.fileInput.click()
    },
    async onFile(e) {
      const file = e.target.files && e.target.files[0]
      e.target.value = ''
      if (!file) return
      this.loading = true
      // 优先用手机浏览器自带识别能力（对模糊、倾斜的照片更准），不支持或失败再上传后端识别
      const local = await this.decodeLocally(file)
      if (local) {
        this.loading = false
        this.lookup(local)
        return
      }
      this.uploadDecode(file)
    },
    async decodeLocally(file) {
      try {
        if (!window.BarcodeDetector) return null
        const detector = new window.BarcodeDetector({ formats: ['qr_code'] })
        const bitmap = await createImageBitmap(file)
        const codes = await detector.detect(bitmap)
        if (bitmap.close) bitmap.close()
        return codes && codes.length ? codes[0].rawValue : null
      } catch (e) {
        return null
      }
    },
    uploadDecode(file) {
      const fd = new FormData()
      fd.append('file', file)
      this.$request.post('/qr/decode', fd).then(res => {
        this.loading = false
        if (res.code === '200') {
          this.lookup(res.data)
        } else {
          this.$message.error(res.msg || '未识别到二维码')
        }
      }).catch(() => {
        this.loading = false
        this.$message.error('二维码识别失败，请重拍或手动输入资产编号')
      })
    },
    lookup(code) {
      this.loading = true
      this.$request.post('/inventoryPublic/lookup/' + this.code, { code: code }).then(res => {
        this.loading = false
        if (res.code !== '200') {
          this.$message.error(res.msg)
          return
        }
        this.asset = res.data
        this.scannedCode = code
        this.comment = ''
        this.assetVisible = true
      }).catch(() => {
        this.loading = false
      })
    },
    submitScan() {
      if (!this.scannedCode) return
      this.submitting = true
      this.$request.post('/inventoryPublic/scan/' + this.code, {
        code: this.scannedCode,
        comment: this.comment
      }).then(res => {
        this.submitting = false
        if (res.code !== '200') {
          this.$message.error(res.msg)
          return
        }
        const it = res.data || {}
        this.assetVisible = false
        this.$message.success((it.itemStatus === '盘盈' ? '已登记盘盈：' : '盘点成功：') + (it.assetsNo || ''))
        this.loadTask()
        this.loadItems()
      }).catch(() => {
        this.submitting = false
      })
    },
    openManual() {
      if (!this.canScan) {
        this.$message.warning('盘点已完成，不能继续扫码')
        return
      }
      this.manualCode = ''
      this.manualVisible = true
    },
    manualLookup() {
      const code = (this.manualCode || '').trim()
      if (!code) {
        this.$message.warning('请输入资产编号')
        return
      }
      this.manualVisible = false
      this.lookup(code)
    },
    tagClass(status) {
      return {
        'inv-tag-normal': status === '正常',
        'inv-tag-warn': status === '异常',
        'inv-tag-profit': status === '盘盈',
        'inv-tag-loss': status === '盘亏',
        'inv-tag-none': status === '未盘'
      }
    }
  }
}
</script>

<style>
.inv-page {
  min-height: 100vh;
  background: #f2f4f8;
  padding-bottom: 110px;
  box-sizing: border-box;
  font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', 'PingFang SC', 'Microsoft YaHei', sans-serif;
  color: #303133;
}
.inv-shell { max-width: 560px; margin: 0 auto; }
.inv-head {
  background: linear-gradient(135deg, #2f6fed 0%, #4a9bff 100%);
  color: #fff;
  padding: 18px 16px 16px;
  border-radius: 0 0 18px 18px;
}
.inv-head-top { display: flex; align-items: center; justify-content: space-between; }
.inv-title { font-size: 18px; font-weight: 700; line-height: 1.4; flex: 1; padding-right: 8px; }
.inv-status {
  flex-shrink: 0; font-size: 12px; padding: 2px 10px; border-radius: 20px;
  background: rgba(255, 255, 255, .22);
}
.inv-status.done { background: rgba(255, 255, 255, .9); color: #2f6fed; }
.inv-sub { font-size: 12px; opacity: .85; margin-top: 6px; }
.inv-stats { display: flex; margin: 16px 0 12px; }
.inv-stat { flex: 1; text-align: center; }
.inv-stat b { display: block; font-size: 24px; line-height: 1.2; }
.inv-stat span { font-size: 12px; opacity: .85; }
.inv-progress { height: 6px; background: rgba(255, 255, 255, .28); border-radius: 6px; overflow: hidden; }
.inv-progress i { display: block; height: 100%; background: #fff; border-radius: 6px; transition: width .3s; }
.inv-progress-text { font-size: 11px; opacity: .85; margin-top: 6px; text-align: right; }
.inv-done-tip {
  margin: 10px 12px 0; padding: 10px 12px; border-radius: 10px;
  background: #fdf6ec; color: #b88230; font-size: 13px; line-height: 1.6;
}
.inv-tabs {
  display: flex; position: sticky; top: 0; z-index: 10;
  background: #f2f4f8; padding: 10px 12px 6px;
}
.inv-tab {
  flex: 1; text-align: center; padding: 9px 0; font-size: 15px; color: #606266;
  background: #fff; border-radius: 10px; margin-right: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, .04);
}
.inv-tab:last-child { margin-right: 0; }
.inv-tab.active { background: #2f6fed; color: #fff; font-weight: 600; }
.inv-tab em { font-style: normal; font-size: 13px; opacity: .9; }
.inv-list { padding: 0 12px 8px; }
.inv-list-empty { text-align: center; color: #909399; font-size: 13px; padding: 60px 20px; line-height: 1.8; }
.inv-card {
  background: #fff; border-radius: 12px; padding: 12px 14px; margin-bottom: 10px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, .05);
}
.inv-card-head { display: flex; align-items: center; justify-content: space-between; }
.inv-no { font-size: 13px; color: #909399; font-family: Consolas, Menlo, monospace; }
.inv-tag { font-size: 12px; padding: 2px 8px; border-radius: 10px; background: #f0f2f5; color: #606266; }
.inv-tag-normal { background: #e8f7ee; color: #34a853; }
.inv-tag-warn { background: #fdf6ec; color: #e6a23c; }
.inv-tag-profit { background: #eef4ff; color: #2f6fed; }
.inv-tag-loss { background: #fef0f0; color: #f56c6c; }
.inv-tag-none { background: #f4f4f5; color: #909399; }
.inv-name { font-size: 16px; font-weight: 600; margin-top: 6px; line-height: 1.4; }
.inv-extra {
  font-size: 11px; font-weight: 400; color: #f56c6c; border: 1px solid #fbc4c4;
  border-radius: 4px; padding: 0 4px; margin-left: 6px; vertical-align: middle;
}
.inv-meta { font-size: 12px; color: #909399; margin-top: 4px; }
.inv-scan-info {
  margin-top: 8px; padding-top: 8px; border-top: 1px dashed #ebeef5;
  font-size: 12px; color: #606266; line-height: 1.7;
}
.inv-comment { color: #909399; word-break: break-all; }
.inv-footer {
  position: fixed; left: 0; right: 0; bottom: 0; z-index: 20;
  background: #fff; box-shadow: 0 -2px 12px rgba(0, 0, 0, .08);
  padding: 10px 16px calc(10px + env(safe-area-inset-bottom));
}
.inv-footer-inner { max-width: 560px; margin: 0 auto; }
.inv-scan-btn {
  width: 100%; height: 50px; border: none; border-radius: 12px;
  background: linear-gradient(135deg, #2f6fed 0%, #4a9bff 100%);
  color: #fff; font-size: 17px; font-weight: 600; letter-spacing: 1px;
}
.inv-scan-btn:active { opacity: .88; }
.inv-scan-btn:disabled { background: #c0c4cc; }
.inv-manual { text-align: center; font-size: 12px; color: #909399; margin-top: 8px; }
.inv-tip { text-align: center; font-size: 11px; color: #c0c4cc; margin-top: 4px; }
.inv-file { display: none; }
.inv-empty { padding: 100px 30px; text-align: center; }
.inv-empty-icon {
  width: 56px; height: 56px; line-height: 56px; border-radius: 50%;
  background: #fef0f0; color: #f56c6c; font-size: 30px; font-weight: 700;
  margin: 0 auto 18px;
}
.inv-empty-title { font-size: 17px; font-weight: 600; }
.inv-empty-tip { font-size: 13px; color: #909399; margin-top: 8px; line-height: 1.6; }
.inv-dialog { border-radius: 16px; }
.inv-dialog-body { padding: 4px 2px; }
.inv-dialog-title { font-size: 18px; font-weight: 700; line-height: 1.4; }
.inv-dialog-no { font-size: 13px; color: #909399; font-family: Consolas, Menlo, monospace; margin-top: 4px; }
.inv-dialog-actions { display: flex; margin-top: 18px; }
.inv-dialog-actions .el-button { flex: 1; height: 42px; }
.inv-alert { border-radius: 10px; padding: 10px 12px; font-size: 13px; line-height: 1.7; margin-top: 12px; }
.inv-alert.danger { background: #fef0f0; color: #f56c6c; }
.inv-alert.warn { background: #fdf6ec; color: #b88230; }
.inv-alert-title { font-weight: 600; }
.inv-info { margin-top: 12px; border-top: 1px solid #f0f2f5; }
.inv-info-row {
  display: flex; justify-content: space-between; align-items: flex-start;
  padding: 9px 0; border-bottom: 1px solid #f5f7fa; font-size: 13px;
}
.inv-info-row span { color: #909399; flex-shrink: 0; margin-right: 12px; }
.inv-info-row b { font-weight: 500; text-align: right; word-break: break-all; }
.inv-remark { margin-top: 14px; }
.inv-remark-label { font-size: 13px; color: #606266; margin-bottom: 6px; }
</style>
