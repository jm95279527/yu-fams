<template>
  <div class="scan-page">
    <div class="scan-card" v-if="asset">
      <div class="scan-header">
        <span class="scan-header-bar"></span>
        <span>{{ $cfg.scanTitle }}</span>
      </div>
      <div class="scan-img-wrap" v-if="show('img') && asset.img">
        <el-image :src="asset.img" :preview-src-list="[asset.img]" class="scan-img"></el-image>
      </div>
      <div class="scan-name">{{ asset.name }}</div>
      <div class="scan-row" v-if="show('no') && asset.no">
        <span class="scan-label">{{ $field('no') }}</span><span class="scan-value">{{ asset.no }}</span>
      </div>
      <div class="scan-row" v-if="show('category') && asset.category">
        <span class="scan-label">{{ $field('category') }}</span><span class="scan-value">{{ asset.category }}</span>
      </div>
      <div class="scan-row" v-if="show('company') && asset.companyName">
        <span class="scan-label">{{ $field('companyName') }}</span><span class="scan-value">{{ asset.companyName }}</span>
      </div>
      <div class="scan-row" v-if="show('model') && asset.model">
        <span class="scan-label">{{ $field('model') }}</span><span class="scan-value">{{ asset.model }}</span>
      </div>
      <div class="scan-row" v-if="show('status') && asset.status">
        <span class="scan-label">{{ $field('status') }}</span>
        <span class="scan-value">
          <el-tag :type="asset.status === '正常' ? 'success' : 'warning'" size="mini">{{ asset.status }}</el-tag>
        </span>
      </div>
      <div class="scan-row" v-if="show('date') && asset.date">
        <span class="scan-label">{{ $field('date') }}</span><span class="scan-value">{{ asset.date }}</span>
      </div>
      <div class="scan-row" v-if="show('money') && asset.money">
        <span class="scan-label">{{ $field('money') }}</span><span class="scan-value">￥{{ asset.money }}</span>
      </div>
      <div class="scan-row" v-if="show('num') && asset.num !== null && asset.num !== undefined && asset.num !== ''">
        <span class="scan-label">{{ $field('num') }}</span><span class="scan-value">{{ asset.num }}</span>
      </div>
      <div class="scan-row" v-if="show('depreciate') && asset.depreciate">
        <span class="scan-label">{{ $field('depreciate') }}</span><span class="scan-value">{{ asset.depreciate }}</span>
      </div>
      <div class="scan-row" v-if="show('departmentName') && asset.departmentName">
        <span class="scan-label">{{ $field('departmentName') }}</span><span class="scan-value">{{ asset.departmentName }}</span>
      </div>
      <div class="scan-row" v-if="show('staffName') && asset.staffName">
        <span class="scan-label">{{ $field('staffName') }}</span><span class="scan-value">{{ asset.staffName }}</span>
      </div>
      <div class="scan-row" v-if="show('location') && asset.location">
        <span class="scan-label">{{ $field('location') }}</span><span class="scan-value">{{ asset.location }}</span>
      </div>
      <div class="scan-row" v-if="show('comment') && asset.comment">
        <span class="scan-label">{{ $field('comment') }}</span><span class="scan-value">{{ asset.comment }}</span>
      </div>
      <!-- 自定义字段：启用且勾选后显示 -->
      <div class="scan-row" v-for="f in customRows" :key="f.fieldKey">
        <span class="scan-label">{{ f.label }}</span><span class="scan-value">{{ asset[f.fieldKey] }}</span>
      </div>
      <!-- 任何人扫码均可提交，无需登录 -->
      <div class="scan-actions">
        <el-button type="primary" icon="el-icon-shopping-cart-full" @click="openBorrow">{{ $cfg.scanBorrowText }}</el-button>
        <el-button type="warning" icon="el-icon-tools" @click="openRepair">{{ $cfg.scanRepairText }}</el-button>
      </div>
      <div class="scan-footer">{{ $cfg.scanFooter }}</div>
    </div>
    <div class="scan-empty" v-if="notFound">
      <div class="scan-empty-icon">✕</div>
      <div>未找到该资产信息</div>
    </div>

    <!-- 借用申请 -->
    <el-dialog title="申请借用" :visible.sync="borrowVisible" width="92%" :close-on-click-modal="false" destroy-on-close>
      <el-form :model="borrowForm" label-width="88px" :rules="borrowRules" ref="borrowFormRef">
        <el-form-item label="借用人" prop="borrowerName">
          <el-input v-model="borrowForm.borrowerName" placeholder="请输入借用人姓名"></el-input>
        </el-form-item>
        <el-form-item label="联系方式" prop="borrowerPhone">
          <el-input v-model="borrowForm.borrowerPhone" placeholder="请输入手机号" maxlength="11"></el-input>
        </el-form-item>
        <el-form-item label="归还日期" prop="returnDate">
          <el-date-picker format="yyyy-MM-dd" value-format="yyyy-MM-dd" placeholder="请选择预计归还日期"
                          v-model="borrowForm.returnDate" style="width: 100%"></el-date-picker>
        </el-form-item>
        <el-form-item label="备注" prop="comment">
          <el-input type="textarea" :rows="3" v-model="borrowForm.comment" placeholder="备注（可选）"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="borrowVisible = false">取 消</el-button>
        <el-button type="primary" :loading="submitting" @click="submitBorrow">提 交</el-button>
      </div>
    </el-dialog>

    <!-- 报修申请 -->
    <el-dialog title="申请报修" :visible.sync="repairVisible" width="92%" :close-on-click-modal="false" destroy-on-close>
      <el-form :model="repairForm" label-width="88px" :rules="repairRules" ref="repairFormRef">
        <el-form-item label="报修人" prop="reporterName">
          <el-input v-model="repairForm.reporterName" placeholder="请输入报修人姓名"></el-input>
        </el-form-item>
        <el-form-item label="报修电话" prop="reporterPhone">
          <el-input v-model="repairForm.reporterPhone" placeholder="请输入手机号" maxlength="11"></el-input>
        </el-form-item>
        <el-form-item label="故障描述" prop="faultDesc">
          <el-input type="textarea" :rows="4" v-model="repairForm.faultDesc" placeholder="请描述故障情况（报修理由与故障描述填这里即可）"></el-input>
        </el-form-item>
        <el-form-item label="报修照片">
          <el-upload
              :action="$baseUrl + '/files/upload'"
              list-type="picture"
              :limit="1"
              accept="image/*"
              :on-success="handleImgSuccess"
              :on-remove="handleImgRemove">
            <el-button type="primary" plain>拍照/上传照片（可选）</el-button>
          </el-upload>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="repairVisible = false">取 消</el-button>
        <el-button type="primary" :loading="submitting" @click="submitRepair">提 交</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: "Scan",
  data() {
    return {
      asset: null,
      notFound: false,
      borrowVisible: false,
      repairVisible: false,
      submitting: false,
      borrowForm: {},
      repairForm: {},
      borrowRules: {
        borrowerName: [{ required: true, message: '请输入借用人姓名', trigger: 'blur' }],
        borrowerPhone: [
          { required: true, message: '请输入联系方式', trigger: 'blur' },
          { pattern: /^1[3-9]\d{9}$/, message: '请填写正确的 11 位手机号', trigger: 'blur' }
        ],
        returnDate: [{ required: true, message: '请选择预计归还日期', trigger: 'change' }]
      },
      repairRules: {
        reporterName: [{ required: true, message: '请输入报修人姓名', trigger: 'blur' }],
        reporterPhone: [
          { required: true, message: '请输入报修电话', trigger: 'blur' },
          { pattern: /^1[3-9]\d{9}$/, message: '请填写正确的 11 位手机号', trigger: 'blur' }
        ],
        faultDesc: [{ required: true, message: '请填写故障描述', trigger: 'blur' }]
      }
    }
  },
  computed: {
    // 已启用且在「页面设置」中勾选、且有值的自定义字段
    customRows() {
      if (!this.asset) return []
      return (this.$fieldStore.fields || []).filter(f => {
        if (f.isSystem || f.enabled === 0) return false
        const value = this.asset[f.fieldKey]
        return this.show(f.fieldKey) && value !== null && value !== undefined && value !== ''
      })
    }
  },
  created() {
    this.load()
  },
  methods: {
    // 该字段是否在「页面设置 → 扫码页显示字段」中被勾选
    show(key) {
      const fields = this.$cfg.scanFields
      if (!fields) {
        return true          // 配置未加载时按“全显示”兜底，避免页面空白
      }
      return fields.indexOf(key) >= 0
    },
    load() {
      const code = this.$route.params.code
      // 新二维码：/scan/{资产编号}
      this.$request.get('/qr/assetByNo/' + encodeURIComponent(code)).then(res => {
        if (res.code === '200') {
          this.asset = res.data
        } else if (/^\d+$/.test(code)) {
          this.loadById(code)   // 兼容历史二维码 /scan/{id}
        } else {
          this.notFound = true
        }
      }).catch(() => {
        if (/^\d+$/.test(code)) {
          this.loadById(code)
        } else {
          this.notFound = true
        }
      })
    },
    loadById(id) {
      this.$request.get('/qr/asset/' + id).then(res => {
        if (res.code === '200') {
          this.asset = res.data
        } else {
          this.notFound = true
        }
      }).catch(() => {
        this.notFound = true
      })
    },
    openBorrow() {
      this.borrowForm = { assetsId: this.asset ? this.asset.assetId : null }
      this.borrowVisible = true
    },
    openRepair() {
      this.repairForm = { assetsId: this.asset ? this.asset.assetId : null, img: null }
      this.repairVisible = true
    },
    handleImgSuccess(response) {   // 报修照片上传成功（非必填）
      if (response && response.code === '200') {
        this.repairForm.img = response.data
      } else {
        this.$message.error((response && response.msg) || '照片上传失败')
      }
    },
    handleImgRemove() {
      this.repairForm.img = null
    },
    submitBorrow() {
      this.$refs.borrowFormRef.validate(valid => {
        if (!valid) return
        this.submitting = true
        this.$request.post('/scan/borrow', this.borrowForm).then(res => {
          this.submitting = false
          if (res.code === '200') {
            this.$message.success('借用申请已提交，等待管理员审核')
            this.borrowVisible = false
          } else {
            this.$message.error(res.msg)
          }
        }).catch(() => { this.submitting = false })
      })
    },
    submitRepair() {
      this.$refs.repairFormRef.validate(valid => {
        if (!valid) return
        this.submitting = true
        const data = Object.assign({}, this.repairForm, {
          assetsName: this.asset ? this.asset.name : null,
          assetsCode: this.asset ? this.asset.no : null
        })
        this.$request.post('/scan/repair', data).then(res => {
          this.submitting = false
          if (res.code === '200') {
            this.$message.success('报修申请已提交，等待管理员处理')
            this.repairVisible = false
          } else {
            this.$message.error(res.msg)
          }
        }).catch(() => { this.submitting = false })
      })
    }
  }
}
</script>

<style scoped>
.scan-page {
  min-height: 100vh;
  background: #f0f2f5;
  padding: 16px;
  box-sizing: border-box;
}
.scan-card {
  max-width: 420px;
  margin: 0 auto;
  background: #fff;
  border-radius: 12px;
  padding: 20px 18px 14px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
}
.scan-header {
  display: flex;
  align-items: center;
  font-size: 17px;
  font-weight: bold;
  color: #303133;
  margin-bottom: 14px;
}
.scan-header-bar {
  width: 4px;
  height: 18px;
  background: #409EFF;
  border-radius: 2px;
  margin-right: 8px;
}
.scan-img-wrap {
  text-align: center;
  margin-bottom: 12px;
}
.scan-img {
  width: 120px;
  height: 120px;
  border-radius: 8px;
}
.scan-name {
  font-size: 18px;
  font-weight: bold;
  color: #303133;
  margin-bottom: 14px;
  padding-bottom: 12px;
  border-bottom: 1px solid #ebeef5;
}
.scan-row {
  display: flex;
  padding: 8px 0;
  font-size: 14px;
  line-height: 1.5;
  border-bottom: 1px dashed #f0f0f0;
}
.scan-label {
  width: 80px;
  flex-shrink: 0;
  color: #909399;
}
.scan-value {
  flex: 1;
  color: #303133;
  word-break: break-all;
}
.scan-actions {
  display: flex;
  gap: 10px;
  margin-top: 16px;
  padding-top: 14px;
  border-top: 1px solid #ebeef5;
}
.scan-actions .el-button {
  flex: 1;
}
.scan-footer {
  text-align: center;
  color: #c0c4cc;
  font-size: 12px;
  margin-top: 14px;
}
.scan-empty {
  max-width: 420px;
  margin: 80px auto 0;
  text-align: center;
  color: #909399;
  font-size: 15px;
}
.scan-empty-icon {
  font-size: 42px;
  color: #dcdfe6;
  margin-bottom: 10px;
}
</style>
