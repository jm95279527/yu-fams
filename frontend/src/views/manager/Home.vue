<template>
  <div class="dashboard">
    <!-- 顶部问候 -->
    <div class="hero">
      <div class="hero-left">
        <div class="hero-title">您好，{{ user.name }}，欢迎回到资产驾驶舱</div>
        <div class="hero-sub">{{ currentDate }} · 数据实时统计</div>
      </div>
      <div class="hero-actions">
        <el-button size="small" plain icon="el-icon-plus" @click="$router.push('/assets')">新增资产</el-button>
        <el-button size="small" plain icon="el-icon-s-data" @click="$router.push('/assetsInventory')">发起盘点</el-button>
        <el-button size="small" type="primary" icon="el-icon-sort" @click="$router.push('/assetsTransfer')">资产调拨</el-button>
      </div>
    </div>

    <!-- 核心指标 -->
    <div class="grid row-kpi">
      <div class="kpi-card">
        <div class="kpi-icon" style="background:#eef2ff;color:#4f6ef7"><i class="el-icon-box"></i></div>
        <div class="kpi-body">
          <div class="kpi-label">资产总数</div>
          <div class="kpi-value">{{ kpi.totalCount | num }} <span>件</span></div>
          <div class="kpi-sub">本月新增 {{ kpi.monthNewCount | num }} 件</div>
        </div>
      </div>
      <div class="kpi-card">
        <div class="kpi-icon" style="background:#ecfdf5;color:#10b981"><i class="el-icon-money"></i></div>
        <div class="kpi-body">
          <div class="kpi-label">资产原值</div>
          <div class="kpi-value">{{ kpi.totalMoney | wan }} <span>元</span></div>
          <div class="kpi-sub">本月新增 {{ kpi.monthNewValue | wan }} 元 · {{ kpi.missingMoneyCount || 0 }} 件未填原值</div>
        </div>
      </div>
      <div class="kpi-card">
        <div class="kpi-icon" style="background:#f5f3ff;color:#7c5cff"><i class="el-icon-office-building"></i></div>
        <div class="kpi-body">
          <div class="kpi-label">使用部门</div>
          <div class="kpi-value">{{ kpi.deptCount || 0 }} <span>个</span></div>
          <div class="kpi-sub">覆盖使用人 {{ kpi.staffCount || 0 }} 人</div>
        </div>
      </div>
      <div class="kpi-card">
        <div class="kpi-icon" style="background:#fff7ed;color:#f59e0b"><i class="el-icon-bell"></i></div>
        <div class="kpi-body">
          <div class="kpi-label">待办事项</div>
          <div class="kpi-value">{{ todoTotal }} <span>项</span></div>
          <div class="kpi-sub">调拨 {{ todo.pendingTransfer || 0 }} · 报修 {{ todo.pendingRepair || 0 }} · 盘点 {{ todo.activeInventory || 0 }}</div>
        </div>
      </div>
    </div>

    <!-- 待办快捷入口 -->
    <div class="grid row-todo">
      <div class="todo-card" @click="$router.push('/assetsTransfer')">
        <div class="todo-dot" style="background:#4f6ef7"></div>
        <div class="todo-text">
          <div class="todo-label">待审批调拨</div>
          <div class="todo-value">{{ todo.pendingTransfer || 0 }}</div>
        </div>
        <i class="el-icon-arrow-right"></i>
      </div>
      <div class="todo-card" @click="$router.push('/assetsRepair')">
        <div class="todo-dot" style="background:#f59e0b"></div>
        <div class="todo-text">
          <div class="todo-label">处理中报修</div>
          <div class="todo-value">{{ todo.pendingRepair || 0 }}</div>
        </div>
        <i class="el-icon-arrow-right"></i>
      </div>
      <div class="todo-card" @click="$router.push('/assetsInventory')">
        <div class="todo-dot" style="background:#10b981"></div>
        <div class="todo-text">
          <div class="todo-label">进行中盘点</div>
          <div class="todo-value">{{ todo.activeInventory || 0 }}</div>
        </div>
        <i class="el-icon-arrow-right"></i>
      </div>
      <div class="todo-card" @click="$router.push('/assetsReceive')">
        <div class="todo-dot" style="background:#ef4444"></div>
        <div class="todo-text">
          <div class="todo-label">逾期未归还</div>
          <div class="todo-value">{{ todo.overdueBorrow || 0 }}</div>
        </div>
        <i class="el-icon-arrow-right"></i>
      </div>
    </div>

    <!-- 公司分布 + 分类占比 -->
    <div class="grid row-2-1">
      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">各公司资产分布</div>
          <div class="panel-tip">数量与原值对比</div>
        </div>
        <div ref="companyChart" class="chart"></div>
      </div>
      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">资产分类占比</div>
          <div class="panel-tip">Top 8</div>
        </div>
        <div ref="categoryChart" class="chart"></div>
      </div>
    </div>

    <!-- 月度新增 + 部门 Top -->
    <div class="grid row-2-1">
      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">近 12 个月资产新增</div>
          <div class="panel-tip">数量与原值</div>
        </div>
        <div ref="monthlyChart" class="chart"></div>
      </div>
      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">部门资产 Top 8</div>
          <div class="panel-tip">按资产数量</div>
        </div>
        <div ref="deptChart" class="chart"></div>
      </div>
    </div>

    <!-- 盘点进度 + 公告 -->
    <div class="grid row-1-1">
      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">盘点进度</div>
          <el-button type="text" size="mini" @click="$router.push('/assetsInventory')">查看全部</el-button>
        </div>
        <div v-if="inventory.length" class="inv-list">
          <div v-for="t in inventory" :key="t.id" class="inv-item">
            <div class="inv-top">
              <div class="inv-name">{{ t.name }}</div>
              <el-tag size="mini" :type="t.status === '盘点中' ? 'warning' : 'success'">{{ t.status }}</el-tag>
            </div>
            <el-progress :percentage="progressOf(t)" :stroke-width="8" :show-text="false"
                         :color="t.status === '盘点中' ? '#4f6ef7' : '#10b981'"></el-progress>
            <div class="inv-meta">
              <span>已盘 {{ t.normalCount || 0 }} / {{ t.totalCount || 0 }}</span>
              <span>盘亏 {{ t.lossCount || 0 }}</span>
              <span>盘盈 {{ t.profitCount || 0 }}</span>
              <span>异常 {{ t.abnormalCount || 0 }}</span>
            </div>
          </div>
        </div>
        <div v-else class="empty-tip">暂无盘点任务</div>
      </div>

      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">最新公告</div>
          <el-button type="text" size="mini" @click="$router.push('/notice')">更多</el-button>
        </div>
        <el-timeline v-if="notices.length" class="notice-list">
          <el-timeline-item v-for="item in notices.slice(0, 4)" :key="item.id" :timestamp="item.time" placement="top">
            <div class="notice-item" @click="showNotice(item)">
              <div class="notice-title">{{ item.title }}</div>
              <div class="notice-content">{{ (item.content || '').slice(0, 46) }}...</div>
            </div>
          </el-timeline-item>
        </el-timeline>
        <div v-else class="empty-tip">暂无公告</div>
      </div>
    </div>

    <!-- 最近资产 -->
    <div class="panel">
      <div class="panel-head">
        <div class="panel-title">最近资产</div>
        <el-button type="text" size="mini" @click="$router.push('/assets')">进入台账</el-button>
      </div>
      <el-table :data="recentAssets" class="recent-table">
        <el-table-column prop="no" :label="$field('no')" min-width="140" show-overflow-tooltip></el-table-column>
        <el-table-column prop="name" :label="$field('name')" min-width="140" show-overflow-tooltip></el-table-column>
        <el-table-column prop="category" :label="$field('category')" min-width="110" show-overflow-tooltip></el-table-column>
        <el-table-column prop="model" :label="$field('model')" min-width="130" show-overflow-tooltip></el-table-column>
        <el-table-column prop="date" :label="$field('date')" width="116"></el-table-column>
        <el-table-column prop="money" :label="$field('money')" width="120" align="right">
          <template v-slot="scope">{{ formatMoney(scope.row.money) }}</template>
        </el-table-column>
        <el-table-column prop="status" :label="$field('status')" width="92" align="center">
          <template v-slot="scope">
            <el-tag size="mini" :type="getStatusTagType(scope.row.status)">{{ scope.row.status || '-' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="location" :label="$field('location')" min-width="130" show-overflow-tooltip></el-table-column>
      </el-table>
    </div>
  </div>
</template>

<script>
import * as echarts from 'echarts'

const CHART_COLORS = ['#4f6ef7', '#7c5cff', '#10b981', '#f59e0b', '#ef4444', '#06b6d4', '#94a3b8', '#ec4899']

export default {
  name: 'Home',
  filters: {
    num(v) {
      return Number(v || 0).toLocaleString('zh-CN')
    },
    wan(v) {
      const n = Number(v || 0)
      if (n >= 100000000) return '¥' + (n / 100000000).toFixed(2) + ' 亿'
      if (n >= 10000) return '¥' + (n / 10000).toFixed(2) + ' 万'
      return '¥' + n.toLocaleString('zh-CN')
    }
  },
  data() {
    return {
      user: JSON.parse(localStorage.getItem('xm-user') || '{}'),
      currentDate: new Date().toLocaleDateString('zh-CN', {
        year: 'numeric', month: 'long', day: 'numeric', weekday: 'long'
      }),
      kpi: {},
      todo: {},
      statusDist: [],
      companyDist: [],
      deptTop: [],
      categoryDist: [],
      monthly: [],
      inventory: [],
      recentAssets: [],
      notices: [],
      charts: [],
      resizeHandler: null
    }
  },
  computed: {
    todoTotal() {
      return ['pendingTransfer', 'pendingRepair', 'activeInventory', 'overdueBorrow']
        .reduce((sum, key) => sum + Number(this.todo[key] || 0), 0)
    }
  },
  created() {
    this.loadOverview()
    this.loadNotices()
  },
  mounted() {
    this.resizeHandler = () => this.charts.forEach(c => c.resize())
    window.addEventListener('resize', this.resizeHandler)
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.resizeHandler)
    this.charts.forEach(c => c.dispose())
  },
  methods: {
    formatMoney(v) {
      if (v === null || v === undefined || v === '') return '-'
      return '¥' + Number(v).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    },
    getStatusTagType(status) {
      switch (status) {
        case '正常': return 'success'
        case '维修中': return 'warning'
        case '报废': return 'danger'
        case '闲置': return 'info'
        default: return ''
      }
    },
    progressOf(task) {
      const total = Number(task.totalCount || 0)
      if (!total) return 0
      return Math.min(100, Math.round((Number(task.normalCount || 0) / total) * 100))
    },
    async loadOverview() {
      try {
        const res = await this.$request.get('/dashboard/overview')
        if (res.code === '200' && res.data) {
          const d = res.data
          this.kpi = d.kpi || {}
          this.todo = d.todo || {}
          this.statusDist = d.statusDist || []
          this.companyDist = d.companyDist || []
          this.deptTop = d.deptTop || []
          this.categoryDist = d.categoryDist || []
          this.monthly = d.monthly || []
          this.inventory = d.inventory || []
          this.recentAssets = d.recentAssets || []
          this.$nextTick(this.renderCharts)
        }
      } catch (e) {
        this.$message.error('驾驶舱数据加载失败')
      }
    },
    async loadNotices() {
      try {
        const res = await this.$request.get('/notice/selectAll')
        if (res.code === '200') this.notices = res.data || []
      } catch (e) { /* 忽略公告加载失败 */ }
    },
    renderCharts() {
      this.charts.forEach(c => c.dispose())
      this.charts = []
      this.renderCompanyChart()
      this.renderCategoryChart()
      this.renderMonthlyChart()
      this.renderDeptChart()
    },
    init(el) {
      const chart = echarts.init(el)
      this.charts.push(chart)
      return chart
    },
    renderCompanyChart() {
      if (!this.$refs.companyChart) return
      const names = this.companyDist.map(i => i.name)
      const counts = this.companyDist.map(i => Number(i.value || 0))
      const amounts = this.companyDist.map(i => Number((Number(i.amount || 0) / 10000).toFixed(2)))
      const chart = this.init(this.$refs.companyChart)
      chart.setOption({
        tooltip: {
          trigger: 'axis',
          axisPointer: { type: 'shadow' },
          formatter: params => {
            const idx = params[0].dataIndex
            return `${names[idx]}<br/>资产数量：${counts[idx]} 件<br/>资产原值：${amounts[idx]} 万元`
          }
        },
        legend: { top: 0, right: 0, icon: 'roundRect', itemWidth: 10, itemHeight: 10 },
        grid: { left: 8, right: 12, top: 40, bottom: 8, containLabel: true },
        xAxis: { type: 'category', data: names, axisTick: { show: false }, axisLine: { lineStyle: { color: '#e8edf5' } }, axisLabel: { color: '#64748b' } },
        yAxis: [
          { type: 'value', name: '数量', nameTextStyle: { color: '#94a3b8' }, splitLine: { lineStyle: { color: '#f1f4f9' } }, axisLabel: { color: '#94a3b8' } },
          { type: 'value', name: '原值(万)', nameTextStyle: { color: '#94a3b8' }, splitLine: { show: false }, axisLabel: { color: '#94a3b8' } }
        ],
        series: [
          {
            name: '资产数量', type: 'bar', data: counts, barMaxWidth: 34,
            itemStyle: { borderRadius: [8, 8, 0, 0], color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#6a86ff' }, { offset: 1, color: '#4f6ef7' }]) }
          },
          {
            name: '原值(万元)', type: 'line', yAxisIndex: 1, data: amounts, smooth: true, symbolSize: 7,
            lineStyle: { width: 2.4, color: '#7c5cff' }, itemStyle: { color: '#7c5cff' }
          }
        ]
      })
    },
    renderCategoryChart() {
      if (!this.$refs.categoryChart) return
      const data = this.categoryDist.map(i => ({ name: i.name, value: Number(i.value || 0) }))
      const chart = this.init(this.$refs.categoryChart)
      chart.setOption({
        color: CHART_COLORS,
        tooltip: { trigger: 'item', formatter: '{b}<br/>{c} 件（{d}%）' },
        legend: { bottom: 0, icon: 'circle', itemWidth: 8, itemHeight: 8, textStyle: { color: '#64748b', fontSize: 12 } },
        series: [{
          type: 'pie', radius: ['46%', '70%'], center: ['50%', '44%'], avoidLabelOverlap: true,
          itemStyle: { borderColor: '#fff', borderWidth: 3, borderRadius: 6 },
          label: { show: false }, emphasis: { label: { show: true, fontSize: 14, fontWeight: 600, formatter: '{b}\n{c} 件' } },
          data
        }]
      })
    },
    renderMonthlyChart() {
      if (!this.$refs.monthlyChart) return
      const names = this.monthly.map(i => i.month)
      const counts = this.monthly.map(i => Number(i.count || 0))
      const amounts = this.monthly.map(i => Number((Number(i.amount || 0) / 10000).toFixed(2)))
      const chart = this.init(this.$refs.monthlyChart)
      chart.setOption({
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
        legend: { top: 0, right: 0, icon: 'roundRect', itemWidth: 10, itemHeight: 10 },
        grid: { left: 8, right: 12, top: 40, bottom: 8, containLabel: true },
        xAxis: { type: 'category', data: names, axisTick: { show: false }, axisLine: { lineStyle: { color: '#e8edf5' } }, axisLabel: { color: '#64748b' } },
        yAxis: [
          { type: 'value', name: '数量', nameTextStyle: { color: '#94a3b8' }, splitLine: { lineStyle: { color: '#f1f4f9' } }, axisLabel: { color: '#94a3b8' } },
          { type: 'value', name: '原值(万)', nameTextStyle: { color: '#94a3b8' }, splitLine: { show: false }, axisLabel: { color: '#94a3b8' } }
        ],
        series: [
          {
            name: '新增数量', type: 'bar', data: counts, barMaxWidth: 22,
            itemStyle: { borderRadius: [6, 6, 0, 0], color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#8aa2ff' }, { offset: 1, color: '#4f6ef7' }]) }
          },
          {
            name: '新增原值(万)', type: 'line', yAxisIndex: 1, data: amounts, smooth: true, symbolSize: 6,
            lineStyle: { width: 2.2, color: '#10b981' }, itemStyle: { color: '#10b981' },
            areaStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: 'rgba(16,185,129,.18)' }, { offset: 1, color: 'rgba(16,185,129,0)' }]) }
          }
        ]
      })
    },
    renderDeptChart() {
      if (!this.$refs.deptChart) return
      const list = [...this.deptTop].reverse()
      const chart = this.init(this.$refs.deptChart)
      chart.setOption({
        tooltip: {
          trigger: 'axis', axisPointer: { type: 'shadow' },
          formatter: params => {
            const item = list[params[0].dataIndex]
            const amount = Number(item.amount || 0) / 10000
            return `${item.name}<br/>资产数量：${item.value} 件<br/>资产原值：${amount.toFixed(2)} 万元`
          }
        },
        grid: { left: 8, right: 24, top: 10, bottom: 8, containLabel: true },
        xAxis: { type: 'value', splitLine: { lineStyle: { color: '#f1f4f9' } }, axisLabel: { color: '#94a3b8' } },
        yAxis: { type: 'category', data: list.map(i => i.name), axisTick: { show: false }, axisLine: { show: false }, axisLabel: { color: '#475569' } },
        series: [{
          type: 'bar', data: list.map(i => Number(i.value || 0)), barMaxWidth: 16,
          itemStyle: { borderRadius: [0, 8, 8, 0], color: new echarts.graphic.LinearGradient(1, 0, 0, 0, [{ offset: 0, color: '#6a86ff' }, { offset: 1, color: '#8aa2ff' }]) },
          label: { show: true, position: 'right', color: '#64748b', fontSize: 12 }
        }]
      })
    },
    showNotice(notice) {
      this.$alert(notice.content, notice.title, {
        confirmButtonText: '确定',
        customClass: 'notice-detail'
      })
    }
  }
}
</script>

<style scoped>
.dashboard {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* 顶部问候 */
.hero {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 22px 26px;
  border-radius: 16px;
  color: #fff;
  background:
    radial-gradient(900px 240px at 100% -30%, rgba(255, 255, 255, .22), transparent 60%),
    linear-gradient(135deg, #4f6ef7 0%, #7b5cff 100%);
  box-shadow: 0 14px 32px rgba(79, 110, 247, .26);
}

.hero-title {
  font-size: 21px;
  font-weight: 700;
  letter-spacing: .2px;
}

.hero-sub {
  margin-top: 6px;
  font-size: 13px;
  opacity: .85;
}

.hero-actions .el-button {
  border: none;
  background: rgba(255, 255, 255, .16);
  color: #fff;
}

.hero-actions .el-button:hover {
  background: rgba(255, 255, 255, .26);
  transform: translateY(-1px);
}

.hero-actions .el-button--primary {
  background: #fff;
  color: #4f6ef7;
  font-weight: 600;
}

/* 栅格 */
.grid {
  display: grid;
  gap: 16px;
}

.row-kpi {
  grid-template-columns: repeat(4, 1fr);
}

.row-todo {
  grid-template-columns: repeat(4, 1fr);
}

.row-2-1 {
  grid-template-columns: 2fr 1fr;
}

.row-1-1 {
  grid-template-columns: 1fr 1fr;
}

/* KPI */
.kpi-card {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 20px;
  background: #fff;
  border-radius: 14px;
  box-shadow: 0 1px 2px rgba(15, 23, 42, .04), 0 8px 24px rgba(15, 23, 42, .05);
}

.kpi-icon {
  width: 46px;
  height: 46px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  flex-shrink: 0;
}

.kpi-label {
  font-size: 13px;
  color: #64748b;
}

.kpi-value {
  margin: 4px 0 2px;
  font-size: 24px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: -.3px;
  font-variant-numeric: tabular-nums;
}

.kpi-value span {
  font-size: 13px;
  font-weight: 500;
  color: #94a3b8;
}

.kpi-sub {
  font-size: 12px;
  color: #94a3b8;
}

/* 待办 */
.todo-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 18px;
  background: #fff;
  border-radius: 14px;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(15, 23, 42, .04), 0 8px 24px rgba(15, 23, 42, .05);
  transition: transform .18s ease, box-shadow .18s ease;
}

.todo-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 14px 30px rgba(15, 23, 42, .1);
}

.todo-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
  box-shadow: 0 0 0 5px rgba(79, 110, 247, .08);
}

.todo-text {
  flex: 1;
}

.todo-label {
  font-size: 13px;
  color: #64748b;
}

.todo-value {
  font-size: 22px;
  font-weight: 700;
  color: #0f172a;
  font-variant-numeric: tabular-nums;
}

.todo-card > i {
  color: #cbd5e1;
}

/* 面板 */
.panel {
  background: #fff;
  border-radius: 14px;
  padding: 18px;
  box-shadow: 0 1px 2px rgba(15, 23, 42, .04), 0 8px 24px rgba(15, 23, 42, .05);
}

.panel-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.panel-title {
  font-size: 15px;
  font-weight: 600;
  color: #0f172a;
}

.panel-tip {
  font-size: 12px;
  color: #94a3b8;
}

.chart {
  height: 280px;
}

/* 盘点进度 */
.inv-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.inv-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}

.inv-name {
  font-size: 13px;
  font-weight: 600;
  color: #334155;
}

.inv-meta {
  display: flex;
  gap: 14px;
  margin-top: 8px;
  font-size: 12px;
  color: #94a3b8;
}

.empty-tip {
  padding: 24px 0;
  text-align: center;
  font-size: 13px;
  color: #94a3b8;
}

/* 公告 */
.notice-list {
  padding-left: 2px;
  max-height: 280px;
  overflow-y: auto;
}

.notice-item {
  cursor: pointer;
}

.notice-title {
  font-size: 13px;
  font-weight: 600;
  color: #334155;
}

.notice-content {
  margin-top: 4px;
  font-size: 12px;
  color: #94a3b8;
}

/* 最近资产表格 */
.recent-table {
  font-size: 13px;
}

.recent-table >>> .cell {
  line-height: 20px;
}

@media (max-width: 1400px) {
  .row-kpi,
  .row-todo {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 1100px) {
  .row-2-1,
  .row-1-1 {
    grid-template-columns: 1fr;
  }

  .hero {
    flex-direction: column;
    align-items: flex-start;
  }
}

@media (max-width: 640px) {
  .row-kpi,
  .row-todo {
    grid-template-columns: 1fr;
  }
}
</style>

<style>
.notice-detail {
  width: 60% !important;
}

.notice-detail .el-message-box__content {
  white-space: pre-wrap;
  line-height: 1.6;
  max-height: 60vh;
  overflow-y: auto;
}
</style>
