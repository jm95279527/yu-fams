<template>
  <div class="todo-page">
    <el-card>
      <div class="todo-body">
        <i class="el-icon-tools"></i>
        <div class="todo-title">{{ $route.meta.name }} · 功能建设中</div>
        <div class="todo-desc">该模块正在按规划开发中，敬请期待</div>
      </div>
    </el-card>
  </div>
</template>

<script>
export default {
  name: "Todo"
}
</script>

<style scoped>
.todo-page { padding: 10px; }
.todo-body { text-align: center; padding: 80px 0; color: #909399; }
.todo-body i { font-size: 64px; color: #c0c4cc; }
.todo-title { font-size: 20px; color: #606266; margin-top: 20px; }
.todo-desc { font-size: 14px; margin-top: 10px; }
</style>
