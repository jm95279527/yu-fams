<template>
  <div>
    <div class="search">
      <el-input :placeholder="'请输入' + $field('name') + '查询'" style="width: 200px" v-model="assetsName"></el-input>
      <el-button type="info" plain style="margin-left: 10px" @click="load(1)">查询</el-button>
      <el-button type="warning" plain style="margin-left: 10px" @click="reset">重置</el-button>
      <el-button type="primary" plain style="margin-left: 10px" @click="handleAdd">新增报修</el-button>
    </div>

    <div class="table">
      <el-table :data="tableData" strip @selection-change="handleSelectionChange">
        <el-table-column prop="id" label="ID" width="70" align="center" sortable></el-table-column>
        <el-table-column prop="assetsName" :label="$field('name')"></el-table-column>
		<el-table-column prop="assetsCode" :label="$field('no')"></el-table-column>
        <el-table-column prop="status" label="维修状态">
          <template v-slot="scope">
            <el-tag type="info" v-if="scope.row.status === '处理中'">处理中</el-tag>
            <el-tag type="primary" v-if="scope.row.status === '维修中'">维修中</el-tag>
            <el-tag type="success" v-if="scope.row.status === '已完成'">已完成</el-tag>
            <el-tag type="danger" v-if="scope.row.status === '拒绝'">拒绝</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="故障描述" show-overflow-tooltip>
          <template v-slot="scope">{{ scope.row.faultDesc || scope.row.reason }}</template>
        </el-table-column>
        <el-table-column label="照片" width="70" align="center">
          <template v-slot="scope">
            <el-image v-if="scope.row.img" style="width: 36px; height: 36px"
                      :src="scope.row.img" :preview-src-list="[scope.row.img]" fit="cover"></el-image>
            <span v-else style="color:#c0c4cc">—</span>
          </template>
        </el-table-column>
        <el-table-column prop="date" label="报修日期"></el-table-column>
        <el-table-column label="报修人">
          <template v-slot="scope">{{ scope.row.reporterName || scope.row.staffName }}</template>
        </el-table-column>
        <el-table-column prop="reporterPhone" label="报修电话"></el-table-column>
        <el-table-column label="审核" align="center" width="180" v-if="user.role === 'ADMIN'">
          <template v-slot="scope">
            <el-button v-if="scope.row.status === '处理中'" size="mini" type="success" plain @click="changeStatus(scope.row, '维修中')">通过</el-button>
            <el-button v-if="scope.row.status === '处理中'" size="mini" type="danger" plain @click="changeStatus(scope.row, '拒绝')">拒绝</el-button>
          </template>
        </el-table-column>
        <el-table-column label="操作" align="center" width="265">
          <template v-slot="scope">
            <el-button size="mini" type="success" plain @click="changeStatus(scope.row, '已完成')" v-if="scope.row.status === '维修中'">完成维修</el-button>
            <el-button size="mini" type="danger" plain @click="del(scope.row)"
                       v-if="user.role === 'ADMIN' || scope.row.status === '处理中'">删除</el-button>
            <el-button size="mini" type="info" plain @click="viewDetail(scope.row)" v-if="scope.row.status !== '处理中'">查看详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
        <el-pagination
            background
            @current-change="handleCurrentChange"
            :current-page="pageNum"
            :page-sizes="[5, 10, 20]"
            :page-size="pageSize"
            layout="total, prev, pager, next"
            :total="total">
        </el-pagination>
      </div>
    </div>

    <!-- 新增报修 -->
    <el-dialog title="新增报修" :visible.sync="fromVisible" width="40%" :close-on-click-modal="false" destroy-on-close>
      <el-form :model="form" label-width="100px" style="padding-right: 50px" :rules="rules" ref="formRef">
        <el-form-item label="报修资产" prop="assetsId">
          <el-select v-model="form.assetsId" filterable placeholder="请选择资产" style="width: 100%" @change="onAssetChange">
            <el-option v-for="a in assetsList" :key="a.id" :value="a.id"
                       :label="(a.no || '') + ' ' + (a.name || '')"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="报修人" prop="reporterName">
          <el-input v-model="form.reporterName" placeholder="请手动输入报修人姓名"></el-input>
        </el-form-item>
        <el-form-item label="报修电话" prop="reporterPhone">
          <el-input v-model="form.reporterPhone" placeholder="请填写 11 位手机号" maxlength="11"></el-input>
        </el-form-item>
        <el-form-item label="故障描述" prop="faultDesc">
          <el-input type="textarea" :rows="3" v-model="form.faultDesc" placeholder="请描述故障情况（报修理由与故障描述填这里即可）"></el-input>
        </el-form-item>
        <el-form-item label="报修照片">
          <el-upload
              :action="$baseUrl + '/files/upload'"
              :headers="{ token: user.token }"
              list-type="picture"
              :limit="1"
              accept="image/*"
              :on-success="handleImgSuccess"
              :on-remove="handleImgRemove">
            <el-button type="primary" plain>上传照片（可选）</el-button>
          </el-upload>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="fromVisible = false">取 消</el-button>
        <el-button type="primary" @click="save">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 维修详情对话框 -->
    <el-dialog title="维修详情" :visible.sync="detailVisible" width="50%" :close-on-click-modal="false">
      <el-descriptions :column="2" border>
        <el-descriptions-item :label="$field('name')">{{ detailForm.assetsName }}</el-descriptions-item>
        <el-descriptions-item :label="$field('no')">{{ detailForm.assetsCode }}</el-descriptions-item>
        <el-descriptions-item label="维修状态">
          <el-tag :type="getStatusTagType(detailForm.status)">{{ detailForm.status }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="报修人">{{ detailForm.reporterName || detailForm.staffName }}</el-descriptions-item>
        <el-descriptions-item label="报修电话">{{ detailForm.reporterPhone }}</el-descriptions-item>
        <el-descriptions-item label="报修日期">{{ detailForm.date }}</el-descriptions-item>
        <el-descriptions-item label="故障描述" :span="2">{{ detailForm.faultDesc || detailForm.reason }}</el-descriptions-item>
        <el-descriptions-item label="报修照片" :span="2" v-if="detailForm.img">
          <el-image :src="detailForm.img" :preview-src-list="[detailForm.img]" fit="contain"
                    style="width: 100%; max-height: 240px"></el-image>
        </el-descriptions-item>
        <el-descriptions-item label="维修结果" :span="2" v-if="detailForm.repairResult">{{ detailForm.repairResult }}</el-descriptions-item>
        <el-descriptions-item label="完成时间" v-if="detailForm.completeTime">{{ detailForm.completeTime }}</el-descriptions-item>
      </el-descriptions>
      
      <div slot="footer" class="dialog-footer">
        <el-button @click="detailVisible = false">关闭</el-button>
        <el-button v-if="detailForm.status === '维修中'" type="primary" @click="completeRepair">完成维修</el-button>
      </div>
    </el-dialog>

  </div>
</template>
<script>
export default {
  name: "AssetsRepair",
  data() {
    return {
      tableData: [],  // 所有的数据
      pageNum: 1,   // 当前的页码
      pageSize: 10,  // 每页显示的个数
      total: 0,
      assetsName: null,
      fromVisible: false,
      form: {},
      user: JSON.parse(localStorage.getItem('xm-user') || '{}'),
      rules: {
        assetsId: [{ required: true, message: '请选择资产', trigger: 'change' }],
        reporterName: [{ required: true, message: '请填写报修人', trigger: 'blur' }],
        reporterPhone: [
          { required: true, message: '请填写报修电话', trigger: 'blur' },
          { pattern: /^1[3-9]\d{9}$/, message: '请填写正确的 11 位手机号', trigger: 'blur' }
        ],
        faultDesc: [{ required: true, message: '请填写故障描述', trigger: 'blur' }]
      },
      assetsList: [],
      ids: [],
      detailVisible: false,
      detailForm: {}
    }
  },
  created() {
    this.load(1)
    this.loadAssets()
  },
  methods: {
    changeStatus(row, status) {
      this.form = JSON.parse(JSON.stringify(row))
      this.form.status = status
      this.$confirm('您确定操作吗？', '确认审核', {type: "warning"}).then(response => {
        this.$request.put('/assetsRepair/update', this.form).then(res => {
          if (res.code === '200') {
            this.$message.success('审核成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)  // 弹出错误的信息
          }
        })
      }).catch(e => {})
    },
    handleAdd() {   // 新增数据
      this.form = {}  // 新增数据的时候清空数据
      this.fromVisible = true   // 打开弹窗
    },
    handleEdit(row) {   // 编辑数据
      this.form = JSON.parse(JSON.stringify(row))  // 给form对象赋值  注意要深拷贝数据
      this.fromVisible = true   // 打开弹窗
    },
    save() {   // 保存按钮触发的逻辑  它会触发新增或者更新
      this.$refs.formRef.validate((valid) => {
        if (valid) {
          this.$request({
            url: this.form.id ? '/assetsRepair/update' : '/assetsRepair/add',
            method: this.form.id ? 'PUT' : 'POST',
            data: this.form
          }).then(res => {
            if (res.code === '200') {  // 表示成功保存
              this.$message.success('保存成功')
              this.load(1)
              this.fromVisible = false
            } else {
              this.$message.error(res.msg)  // 弹出错误的信息
            }
          })
        }
      })
    },
    del(row) {   // 单个删除（管理员可删除任意状态的报修单）
      this.$confirm('您确定删除该报修单吗？', '确认删除', {type: "warning"}).then(response => {
        this.$request.delete('/assetsRepair/delete/' + row.id).then(res => {
          if (res.code === '200') {   // 表示操作成功
            this.$message.success('操作成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)  // 弹出错误的信息
          }
        })
      }).catch(() => {
      })
    },
    handleSelectionChange(rows) {   // 当前选中的所有的行数据
      this.ids = rows.map(v => v.id)
    },
    delBatch() {   // 批量删除
      if (!this.ids.length) {
        this.$message.warning('请选择数据')
        return
      }
      this.$confirm('您确定批量删除这些数据吗？', '确认删除', {type: "warning"}).then(response => {
        this.$request.delete('/assetsRepair/delete/batch', {data: this.ids}).then(res => {
          if (res.code === '200') {   // 表示操作成功
            this.$message.success('操作成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)  // 弹出错误的信息
          }
        })
      }).catch(() => {
      })
    },
    load(pageNum) {  // 分页查询
      if (pageNum) this.pageNum = pageNum
      this.$request.get('/assetsRepair/selectPage', {
        params: {
          pageNum: this.pageNum,
          pageSize: this.pageSize,
          assetsName: this.assetsName,
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
    loadAssets() {
      this.$request.get('/assets/selectAll').then(res => {
        if (res.code === '200') this.assetsList = res.data || []
      })
    },
    onAssetChange(id) {   // 选中资产时带上名称/编号，后端无 receiveId 时用这两个字段落库
      const a = this.assetsList.find(v => v.id === id) || {}
      this.form.assetsName = a.name
      this.form.assetsCode = a.no
    },
    handleImgSuccess(response) {   // 报修照片上传成功（非必填）
      if (response && response.code === '200') {
        this.form.img = response.data
      } else {
        this.$message.error((response && response.msg) || '照片上传失败')
      }
    },
    handleImgRemove() {
      this.form.img = null
    },
    reset() {
      this.assetsName = null
      this.load(1)
    },
    handleCurrentChange(pageNum) {
      this.load(pageNum)
    },
    
    viewDetail(row) {
      this.detailForm = JSON.parse(JSON.stringify(row))
      this.detailVisible = true
    },
    
    completeRepair() {
      this.$confirm('确认完成维修？', '确认操作', {type: "warning"}).then(response => {
        this.detailForm.status = '已完成'
        this.detailForm.repairResult = '维修完成'
        delete this.detailForm.completeTime  // 完成时间由后端在置为"已完成"时写入，避免前端字符串格式无法反序列化到 Date
        
        this.$request.put('/assetsRepair/update', this.detailForm).then(res => {
          if (res.code === '200') {
            this.$message.success('维修完成')
            this.detailVisible = false
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(e => {})
    },
    
    getStatusTagType(status) {
      switch(status) {
        case '处理中': return 'info';
        case '维修中': return 'primary';
        case '已完成': return 'success';
        case '拒绝': return 'danger';
        default: return '';
      }
    }
  }
}
</script>

<style scoped>

</style>