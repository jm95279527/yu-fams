<template>
  <div>
    <el-card>
      <div slot="header" class="card-head">
        <span>数据备份</span>
        <div class="head-actions">
          <el-button type="primary" icon="el-icon-folder-add" :loading="creating" @click="createBackup">手动备份</el-button>
          <el-upload
            ref="upload"
            :action="$baseUrl + '/dataBackup/upload'"
            :headers="{ token: user.token }"
            :show-file-list="false"
            :on-success="handleUploadSuccess"
            :on-error="handleUploadError"
            :before-upload="beforeUpload"
            accept=".zip"
            :limit="1">
            <el-button type="success" plain icon="el-icon-upload2" :loading="uploading">导入备份</el-button>
          </el-upload>
          <el-button icon="el-icon-refresh" @click="load">刷新</el-button>
        </div>
      </div>

      <el-alert type="info" :closable="false" show-icon>
        <div slot="default">
          <p>备份内容：数据库全部数据 + 上传的图片/附件，打包为 zip，保存在服务器 <b>{{ config.dir }}</b></p>
          <p>「下载」导出备份到本地保存；「导入备份」把本地 zip 上传到服务器；「恢复」会用该备份覆盖当前数据，恢复前会自动备份当前数据</p>
        </div>
      </el-alert>

      <el-table :data="list" border stripe v-loading="loading" style="margin-top: 12px">
        <el-table-column prop="name" label="备份文件" min-width="280" show-overflow-tooltip></el-table-column>
        <el-table-column label="类型" width="120" align="center">
          <template slot-scope="scope">
            <el-tag size="small" :type="tagType(scope.row.type)">{{ scope.row.typeText }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="sizeText" label="大小" width="100" align="center"></el-table-column>
        <el-table-column prop="time" label="备份时间" width="170"></el-table-column>
        <el-table-column label="操作" width="250" align="center">
          <template slot-scope="scope">
            <el-button type="primary" size="mini" icon="el-icon-download" @click="download(scope.row)">下载</el-button>
            <el-button type="warning" size="mini" icon="el-icon-refresh-left" @click="restore(scope.row)">恢复</el-button>
            <el-button type="danger" size="mini" icon="el-icon-delete" @click="remove(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div v-if="!list.length && !loading" class="empty">暂无备份，点击「手动备份」创建第一份备份</div>
    </el-card>

    <el-card style="margin-top: 20px">
      <div slot="header"><span>定时备份</span></div>
      <el-form :model="config" label-width="120px" style="max-width: 620px">
        <el-form-item label="启用定时备份">
          <el-switch v-model="config.enabled"></el-switch>
          <span class="tip">每天到点自动备份全部数据，并按保留份数清理旧的定时备份</span>
        </el-form-item>
        <el-form-item label="备份时间">
          <el-time-picker v-model="config.time" value-format="HH:mm" format="HH:mm"
                          placeholder="选择时间" style="width: 180px"></el-time-picker>
        </el-form-item>
        <el-form-item label="保留份数">
          <el-input-number v-model="config.keepCount" :min="1" :max="60" style="width: 180px"></el-input-number>
          <span class="tip">仅作用于定时备份，手动/导入的备份不会被自动清理</span>
        </el-form-item>
        <el-form-item label="上次定时备份">
          <span>{{ config.lastRunTime || '暂无' }}</span>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="saveConfig">保存设置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'DataBackup',
  data() {
    return {
      user: JSON.parse(localStorage.getItem('xm-user') || '{}'),
      list: [],
      loading: false,
      creating: false,
      uploading: false,
      config: {
        enabled: false,
        time: '02:00',
        keepCount: 7,
        lastRunTime: '',
        dir: ''
      }
    }
  },
  created() {
    this.load()
    this.loadConfig()
  },
  methods: {
    load() {
      this.loading = true
      this.$request.get('/dataBackup/list').then(res => {
        this.loading = false
        if (res.code === '200') {
          this.list = res.data || []
        } else {
          this.$message.error(res.msg)
        }
      }).catch(() => {
        this.loading = false
      })
    },
    loadConfig() {
      this.$request.get('/dataBackup/config').then(res => {
        if (res.code === '200' && res.data) {
          this.config = res.data
        }
      })
    },
    createBackup() {
      this.creating = true
      this.$request.post('/dataBackup/create').then(res => {
        this.creating = false
        if (res.code === '200') {
          this.$message.success('备份完成：' + res.data.sizeText)
          this.load()
        } else {
          this.$message.error(res.msg)
        }
      }).catch(() => {
        this.creating = false
      })
    },
    beforeUpload() {
      this.uploading = true
      return true
    },
    handleUploadSuccess(response) {
      this.uploading = false
      if (this.$refs.upload) this.$refs.upload.clearFiles()
      if (!response || response.code !== '200') {
        this.$message.error((response && response.msg) || '导入失败')
        return
      }
      this.$message.success('备份文件已导入')
      this.load()
    },
    handleUploadError() {
      this.uploading = false
      if (this.$refs.upload) this.$refs.upload.clearFiles()
      this.$message.error('导入失败，请检查文件是否为有效的备份 zip（不超过 50MB）')
    },
    download(row) {
      window.open(this.$baseUrl + '/dataBackup/download?name=' + encodeURIComponent(row.name)
        + '&token=' + encodeURIComponent(this.user.token))
    },
    restore(row) {
      this.$confirm(
        '<div>恢复将用备份「' + row.name + '」<b>覆盖当前全部数据库数据和上传文件</b>。</div>'
        + '<div style="margin-top:8px">恢复前系统会自动备份当前数据；恢复后如果登录失效，请重新登录。</div>'
        + '<div style="margin-top:8px;color:#f56c6c">确认恢复？</div>',
        '数据恢复', {
          dangerouslyUseHTMLString: true,
          type: 'warning',
          confirmButtonText: '确认恢复',
          cancelButtonText: '取消'
        }).then(() => {
        const loading = this.$loading({ lock: true, text: '正在恢复数据，请勿刷新页面...' })
        this.$request.post('/dataBackup/restore?name=' + encodeURIComponent(row.name)).then(res => {
          loading.close()
          if (res.code === '200') {
            this.$alert('恢复完成。恢复前已自动备份当前数据：' + (res.data.safetyBackup || '-')
              + '。如登录失效请重新登录。', '恢复成功', { type: 'success' })
            this.load()
            this.loadConfig()
          } else {
            this.$message.error(res.msg)
          }
        }).catch(() => {
          loading.close()
          this.$message.error('恢复失败，请查看服务器 backup/backup.log')
        })
      }).catch(() => {})
    },
    remove(row) {
      this.$confirm('确认删除备份「' + row.name + '」？删除后不可恢复。', '提示', { type: 'warning' }).then(() => {
        this.$request.delete('/dataBackup/delete?name=' + encodeURIComponent(row.name)).then(res => {
          if (res.code === '200') {
            this.$message.success('已删除')
            this.load()
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {})
    },
    saveConfig() {
      if (!this.config.time) {
        this.$message.warning('请选择备份时间')
        return
      }
      this.$request.post('/dataBackup/config', {
        enabled: this.config.enabled,
        time: this.config.time,
        keepCount: this.config.keepCount
      }).then(res => {
        if (res.code === '200') {
          this.$message.success('定时备份设置已保存')
          this.loadConfig()
        } else {
          this.$message.error(res.msg)
        }
      })
    },
    tagType(type) {
      return { manual: '', auto: 'warning', 'before-restore': 'info', import: 'success' }[type] || 'info'
    }
  }
}
</script>

<style scoped>
.card-head { display: flex; align-items: center; justify-content: space-between; }
.head-actions { display: flex; align-items: center; gap: 8px; }
.head-actions .el-upload { display: inline-block; }
.tip { margin-left: 10px; color: #909399; font-size: 12px; }
.empty { text-align: center; color: #909399; padding: 30px; }
</style>
