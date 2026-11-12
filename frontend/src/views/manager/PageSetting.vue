<template>
  <div>
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <span class="card-title">页面设置</span>
        <span class="card-tip">修改后点「保存」即对所有用户生效（已登录用户刷新页面后生效）</span>
      </div>

      <el-form :model="form" label-width="130px" style="max-width: 820px">
        <!-- 登录壁纸 -->
        <el-form-item label="登录壁纸">
          <el-upload
              :action="$baseUrl + '/files/upload'"
              :headers="{ token: user.token }"
              :show-file-list="false"
              accept="image/*"
              :before-upload="beforeImage"
              :on-success="res => handleUpload(res, 'loginBg')"
              :on-error="handleUploadError">
            <el-button type="primary" plain>上传壁纸</el-button>
          </el-upload>
          <el-button v-if="form.loginBg" type="text" style="margin-left: 10px" @click="form.loginBg = ''">恢复默认壁纸</el-button>
          <span v-else class="hint">未设置时使用系统内置背景图</span>
          <div v-if="form.loginBg" class="preview-wrap">
            <el-image :src="form.loginBg" :preview-src-list="[form.loginBg]" fit="cover"
                      style="width: 260px; height: 146px; border-radius: 4px; border: 1px solid #ebeef5"></el-image>
            <div class="preview-tip">登录页效果预览</div>
          </div>
        </el-form-item>

        <!-- Logo -->
        <el-form-item label="Logo">
          <el-upload
              :action="$baseUrl + '/files/upload'"
              :headers="{ token: user.token }"
              :show-file-list="false"
              accept="image/*"
              :before-upload="beforeImage"
              :on-success="res => handleUpload(res, 'logo')"
              :on-error="handleUploadError">
            <el-button type="primary" plain>上传 Logo</el-button>
          </el-upload>
          <el-button v-if="form.logo" type="text" style="margin-left: 10px" @click="form.logo = ''">恢复默认 Logo</el-button>
          <span v-else class="hint">未设置时使用系统内置 Logo</span>
          <div v-if="form.logo" class="preview-wrap">
            <el-image :src="form.logo" :preview-src-list="[form.logo]" fit="contain"
                      style="width: 56px; height: 56px; border-radius: 4px; border: 1px solid #ebeef5; background: #f5f7fa"></el-image>
          </div>
        </el-form-item>

        <el-divider content-position="left">页面固定字段</el-divider>

        <el-form-item label="系统名称">
          <el-input v-model="form.systemName" maxlength="50" show-word-limit
                    placeholder="如：固定资产管理系统（后台顶栏 + 登录页标题）"></el-input>
        </el-form-item>
        <el-form-item label="浏览器标签标题">
          <el-input v-model="form.browserTitle" maxlength="50" show-word-limit
                    placeholder="留空则跟随系统名称"></el-input>
        </el-form-item>
        <el-form-item label="登录页副标题">
          <el-input v-model="form.loginSubtitle" maxlength="50" show-word-limit
                    placeholder="如：欢迎使用"></el-input>
        </el-form-item>
        <el-form-item label="驾驶舱欢迎词">
          <el-input v-model="form.dashboardWelcome" maxlength="100" show-word-limit
                    placeholder="显示为「您好，XXX！＋欢迎词」"></el-input>
        </el-form-item>
        <el-form-item label="页脚版权信息">
          <el-input v-model="form.footerText" maxlength="100" show-word-limit
                    placeholder="留空则不显示页脚，如：© 2026 赫玛科技 版权所有"></el-input>
        </el-form-item>

        <el-divider content-position="left">扫码页显示字段</el-divider>

        <el-form-item label="显示字段">
          <div style="width: 100%">
            <el-checkbox :indeterminate="scanAllIndeterminate" v-model="scanAll" style="margin-bottom: 10px">全选</el-checkbox>
            <el-checkbox-group v-model="form.scanFields">
              <el-checkbox v-for="f in scanFieldOptions" :key="f.key" :label="f.key" border
                           style="margin: 0 8px 8px 0">{{ f.label }}</el-checkbox>
            </el-checkbox-group>
            <div class="scan-tip">{{ $field('name') }}作为标题始终显示；其余字段勾选后，扫码页只显示勾选项</div>
          </div>
        </el-form-item>

        <el-divider content-position="left">扫码页固定文字</el-divider>

        <el-form-item label="卡片标题">
          <el-input v-model="form.scanTitle" maxlength="20" show-word-limit placeholder="默认：资产信息"></el-input>
        </el-form-item>
        <el-form-item label="底部文字">
          <el-input v-model="form.scanFooter" maxlength="50" show-word-limit placeholder="默认：固定资产管理系统"></el-input>
        </el-form-item>
        <el-form-item label="借用按钮">
          <el-input v-model="form.scanBorrowText" maxlength="10" show-word-limit placeholder="默认：申请借用"></el-input>
        </el-form-item>
        <el-form-item label="报修按钮">
          <el-input v-model="form.scanRepairText" maxlength="10" show-word-limit placeholder="默认：申请报修"></el-input>
        </el-form-item>
        <el-form-item>
          <div class="scan-tip">留空则使用默认文字；保存后立即在扫码页生效</div>
        </el-form-item>

        <el-form-item>
          <el-button type="primary" :loading="saving" @click="save">保 存</el-button>
          <el-button @click="load">还 原</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { loadSiteConfig } from '@/utils/siteConfig'
import { scanFieldOptions as getScanFieldOptions } from '@/utils/fields'

/** 前端字段名 ↔ 数据库 config_key */
const KEY_MAP = {
  systemName: 'system_name',
  browserTitle: 'browser_title',
  loginSubtitle: 'login_subtitle',
  loginBg: 'login_bg',
  logo: 'logo',
  footerText: 'footer_text',
  dashboardWelcome: 'dashboard_welcome',
  scanFields: 'scan_fields',
  scanTitle: 'scan_title',
  scanFooter: 'scan_footer',
  scanBorrowText: 'scan_borrow_text',
  scanRepairText: 'scan_repair_text'
}

export default {
  name: "PageSetting",
  computed: {
    // 扫码页可选字段：系统字段（名称随自定义字段配置同步）+ 已启用的自定义字段
    scanFieldOptions() {
      return getScanFieldOptions()
    },
    // 「全选」：全部勾选时为 true，部分勾选时为半选
    scanAll: {
      get() {
        return this.scanFieldOptions.length > 0 && this.form.scanFields.length >= this.scanFieldOptions.length
      },
      set(val) {
        this.form.scanFields = val ? this.scanFieldOptions.map(f => f.key) : []
      }
    },
    scanAllIndeterminate() {
      const n = this.form.scanFields.length
      return n > 0 && n < this.scanFieldOptions.length
    }
  },
  data() {
    return {
      user: JSON.parse(localStorage.getItem('xm-user') || '{}'),
      saving: false,
      form: {
        systemName: '',
        browserTitle: '',
        loginSubtitle: '',
        loginBg: '',
        logo: '',
        footerText: '',
        dashboardWelcome: '',
        scanFields: [],
        scanTitle: '',
        scanFooter: '',
        scanBorrowText: '',
        scanRepairText: ''
      }
    }
  },
  created() {
    this.load()
  },
  methods: {
    load() {
      this.$request.get('/sysConfig/selectAll').then(res => {
        if (res.code !== '200') {
          this.$message.error(res.msg || '读取配置失败')
          return
        }
        const map = {}
        ;(res.data || []).forEach(item => { map[item.configKey] = item.configValue || '' })
        Object.keys(KEY_MAP).forEach(k => {
          if (k !== 'scanFields') {
            this.form[k] = map[KEY_MAP[k]] || ''
          }
        })
        // 扫码页显示字段：逗号分隔 → 数组；配置项不存在时默认全选（主动全部取消则保持为空）
        const raw = map['scan_fields']
        this.form.scanFields = raw === undefined
          ? this.scanFieldOptions.map(f => f.key)
          : raw.split(',').map(s => s.trim()).filter(Boolean)
      })
    },
    save() {
      if (!this.form.systemName || !this.form.systemName.trim()) {
        this.$message.warning('系统名称不能为空')
        return
      }
      const payload = Object.keys(KEY_MAP).map(k => {
        const val = this.form[k]
        return {
          configKey: KEY_MAP[k],
          configValue: Array.isArray(val) ? val.join(',') : String(val == null ? '' : val).trim()
        }
      })
      this.saving = true
      this.$request.put('/sysConfig/save', payload).then(res => {
        this.saving = false
        if (res.code === '200') {
          this.$message.success('保存成功')
          // 立即刷新全局配置：登录页壁纸/顶栏名称/扫码页字段等马上生效
          loadSiteConfig()
          this.load()
        } else {
          this.$message.error(res.msg || '保存失败')
        }
      }).catch(() => {
        this.saving = false
      })
    },
    beforeImage(file) {
      if (!file.type || file.type.indexOf('image/') !== 0) {
        this.$message.warning('只能上传图片文件')
        return false
      }
      if (file.size > 5 * 1024 * 1024) {
        this.$message.warning('图片不能超过 5MB')
        return false
      }
      return true
    },
    handleUpload(res, field) {
      if (res && res.code === '200' && res.data) {
        this.form[field] = res.data
        this.$message.success('上传成功，记得点「保存」')
      } else {
        this.$message.error((res && res.msg) || '上传失败')
      }
    },
    handleUploadError() {
      this.$message.error('上传失败，请重试')
    }
  }
}
</script>

<style scoped>
.card-header {
  display: flex;
  align-items: center;
}

.card-title {
  font-weight: 600;
  font-size: 15px;
}

.card-tip {
  margin-left: 12px;
  color: #909399;
  font-size: 12px;
}

.hint {
  margin-left: 10px;
  color: #c0c4cc;
  font-size: 12px;
}

.preview-wrap {
  margin-top: 10px;
}

.preview-tip {
  color: #909399;
  font-size: 12px;
  margin-top: 4px;
}

.scan-tip {
  color: #c0c4cc;
  font-size: 12px;
  line-height: 1.6;
}
</style>
