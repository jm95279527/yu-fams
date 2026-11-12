<template>
  <div>
    <div class="search">
      <el-input placeholder="操作人" style="width: 140px" v-model="query.username" clearable></el-input>
      <el-input placeholder="请求接口" style="width: 180px; margin-left: 10px" v-model="query.uri" clearable></el-input>
      <el-select placeholder="请求方式" style="width: 120px; margin-left: 10px" v-model="query.method" clearable>
        <el-option label="POST" value="POST"></el-option>
        <el-option label="PUT" value="PUT"></el-option>
        <el-option label="DELETE" value="DELETE"></el-option>
      </el-select>
      <el-button type="info" plain style="margin-left: 10px" @click="load(1)">查询</el-button>
      <el-button type="warning" plain style="margin-left: 10px" @click="reset">重置</el-button>
    </div>

    <div class="operation">
      <el-button type="danger" plain @click="delBatch">批量删除</el-button>
      <el-button type="warning" plain icon="el-icon-delete" @click="clean">清理30天前日志</el-button>
    </div>

    <div class="table">
      <el-table :data="tableData" stripe @selection-change="handleSelectionChange">
        <el-table-column type="selection" width="55" align="center"></el-table-column>
        
        <el-table-column prop="createTime" label="操作时间" width="160"></el-table-column>
        <el-table-column prop="username" label="操作人" width="120"></el-table-column>
        <el-table-column prop="role" label="角色" width="80"></el-table-column>
        <el-table-column prop="ip" label="来源IP" width="130"></el-table-column>
        <el-table-column label="方式" width="90" align="center">
          <template v-slot="scope">
            <el-tag size="small" :type="methodTag(scope.row.method)">{{ scope.row.method }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="uri" label="请求接口" min-width="180" show-overflow-tooltip></el-table-column>
        <el-table-column prop="params" label="参数" min-width="200" show-overflow-tooltip></el-table-column>
        <el-table-column label="业务码" width="80" align="center">
          <template v-slot="scope">
            <el-tag size="small" :type="scope.row.resultCode === '200' ? 'success' : 'danger'">{{ scope.row.resultCode }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="costMs" label="耗时(ms)" width="85" align="center"></el-table-column>
        <el-table-column label="操作" align="center" width="80" fixed="right">
          <template v-slot="scope">
            <el-button size="mini" type="danger" plain @click="del(scope.row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
        <el-pagination
            background
            @current-change="handleCurrentChange"
            @size-change="handleSizeChange"
            :current-page="pageNum"
            :page-sizes="[10, 20, 50, 100]"
            :page-size="pageSize"
            layout="total, sizes, prev, pager, next"
            :total="total">
        </el-pagination>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "AuditLog",
  data() {
    return {
      tableData: [],
      pageNum: 1,
      pageSize: 10,
      total: 0,
      query: {
        username: null,
        uri: null,
        method: null
      },
      ids: []
    }
  },
  created() {
    this.load(1)
  },
  methods: {
    load(pageNum) {
      if (pageNum) this.pageNum = pageNum
      this.$request.get('/auditLog/selectPage', {
        params: {
          pageNum: this.pageNum,
          pageSize: this.pageSize,
          username: this.query.username,
          uri: this.query.uri,
          method: this.query.method
        }
      }).then(res => {
        this.tableData = res.data?.list
        this.total = res.data?.total
      })
    },
    reset() {
      this.query = {username: null, uri: null, method: null}
      this.load(1)
    },
    methodTag(method) {
      if (method === 'POST') return 'primary'
      if (method === 'PUT') return 'warning'
      if (method === 'DELETE') return 'danger'
      return 'info'
    },
    del(id) {
      this.$confirm('确定删除这条日志吗？', '确认删除', {type: "warning"}).then(() => {
        this.$request.delete('/auditLog/delete/batch', {data: [id]}).then(res => {
          if (res.code === '200') {
            this.$message.success('操作成功')
            this.load(this.tableData.length === 1 && this.pageNum > 1 ? this.pageNum - 1 : this.pageNum)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {
      })
    },
    handleSelectionChange(rows) {
      this.ids = rows.map(v => v.id)
    },
    delBatch() {
      if (!this.ids.length) {
        this.$message.warning('请选择数据')
        return
      }
      this.$confirm('确定删除选中的 ' + this.ids.length + ' 条日志吗？', '确认删除', {type: "warning"}).then(() => {
        this.$request.delete('/auditLog/delete/batch', {data: this.ids}).then(res => {
          if (res.code === '200') {
            this.$message.success('操作成功')
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {
      })
    },
    clean() {
      this.$confirm('将永久删除 30 天前的所有审计日志，确定继续吗？', '清理历史日志', {type: "warning"}).then(() => {
        this.$request.delete('/auditLog/clean/30').then(res => {
          if (res.code === '200') {
            this.$message.success('清理完成')
            this.load(1)
          } else {
            this.$message.error(res.msg)
          }
        })
      }).catch(() => {
      })
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

</style>
