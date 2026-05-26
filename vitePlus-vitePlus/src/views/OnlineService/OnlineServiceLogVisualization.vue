<template>
  <div class="visualization-container">
    <!-- 头部区域 -->
    <div class="header-area">
      <div class="tech-title">
        <el-icon><DataAnalysis /></el-icon>
        <el-breadcrumb :separator-icon="ArrowRight" class="nav-breadcrumb">
          <el-breadcrumb-item :to="{ path: '/onlineServiceList' }" class="tech-breadcrumb">
            在线服务
          </el-breadcrumb-item>
          <el-breadcrumb-item class="tech-breadcrumb">
            访问统计
          </el-breadcrumb-item>
        </el-breadcrumb>
      </div>
    </div>

    <div class="main-content-wrapper">
      <!-- 统计类型导航 -->
      <div class="stats-nav-section">
        <el-menu class="stats-menu" mode="horizontal" :default-active="pageIndex.toString()">
          <el-menu-item index="1" @click="changePageIndex(1)">
            <el-icon><TrendCharts /></el-icon>
            <span>请求数量时间趋势图</span>
          </el-menu-item>
          <el-menu-item index="2" @click="changePageIndex(2)">
            <el-icon><Histogram /></el-icon>
            <span>请求情况时段分布图</span>
          </el-menu-item>
          <el-menu-item index="3" @click="changePageIndex(3)">
            <el-icon><PieChart /></el-icon>
            <span>请求响应状态分布图</span>
          </el-menu-item>
        </el-menu>
      </div>

      <!-- 图表展示区域 -->
      <div class="chart-section">
        <!-- 请求数量时间趋势图 -->
        <div v-if="pageIndex === 1" class="chart-container" v-loading="loading">
          <div class="chart-controls">
            <div class="control-section">
              <div class="control-item">
                <span class="control-label">请选择时间范围</span>
                <el-date-picker
                  v-model="timeValue1"
                  type="datetimerange"
                  :disabled-date="disabledDate"
                  :shortcuts="shortcuts"
                  range-separator="至"
                  start-placeholder="起始时间"
                  end-placeholder="结束时间"
                  format="YYYY/MM/DD HH:mm:ss"
                  value-format="YYYY-M-D HH:mm:ss"
                  class="date-picker"
                />
              </div>
              <div class="control-item">
                <span class="control-label">时间跨度单位</span>
                <el-select v-model="timeunitvalue" class="time-unit-selector">
                  <el-option
                    v-for="item in timeUnit"
                    :key="item"
                    :label="item"
                    :value="item"
                  />
                </el-select>
              </div>
            </div>
          </div>
          <div ref="myChart" class="chart-display"></div>
        </div>

        <!-- 请求情况时段分布图 -->
        <div v-if="pageIndex === 2" class="chart-container" v-loading="loading">
          <div class="chart-controls">
            <div class="control-section">
              <div class="control-item">
                <span class="control-label">请选择具体日期</span>
                <el-date-picker
                  v-model="timeValue2"
                  type="datetimerange"
                  :disabled-date="disabledDate"
                  :shortcuts="shortcuts"
                  range-separator="至"
                  start-placeholder="起始时间"
                  end-placeholder="结束时间"
                  format="YYYY/MM/DD HH:mm:ss"
                  value-format="YYYY-M-D HH:mm:ss"
                  class="date-picker"
                />
              </div>
              <div class="control-item">
                <span class="control-label">时间间隔</span>
                <div class="time-span-control">
                  <el-select v-model="timeSpanNum" class="time-span-selector">
                    <el-option
                      v-for="item in timeSpan"
                      :key="item"
                      :label="item"
                      :value="item"
                    />
                  </el-select>
                  <span class="unit-label">小时</span>
                </div>
              </div>
            </div>
          </div>
          <div ref="myChart" class="chart-display"></div>
        </div>

        <!-- 请求响应状态分布图 -->
        <div v-if="pageIndex === 3" class="chart-container" v-loading="loading">
          <div class="chart-controls">
            <div class="control-section">
              <div class="control-item">
                <span class="control-label">请选择具体日期</span>
                <el-date-picker
                  v-model="timeValue3"
                  type="datetimerange"
                  :disabled-date="disabledDate"
                  :shortcuts="shortcuts"
                  range-separator="至"
                  start-placeholder="起始时间"
                  end-placeholder="结束时间"
                  format="YYYY/MM/DD HH:mm:ss"
                  value-format="YYYY-M-D HH:mm:ss"
                  class="date-picker"
                />
              </div>
            </div>
          </div>
          <div class="pie-chart-layout">
            <div ref="myChart" class="pie-chart"></div>
            <div class="status-table">
              <!-- 添加表格标题区域 -->
              <div class="table-header">
                <div class="table-title">响应状态详情</div>
                <div class="table-subtitle">状态码与响应时长统计分析</div>
              </div>
              
              <el-table
                :data="chartData.tableData"
                :header-cell-style="tableHeaderStyle"
                :cell-style="tableCellStyle"
                stripe
                border
                highlight-current-row
                max-height="350"
                class="status-data-table"
              >
                <el-table-column prop="status_code" label="状态码" width="100">
                  <template #default="scope">
                    <div :class="getStatusClass(scope.row.status_code)">
                      {{ scope.row.status_code }}
                    </div>
                  </template>
                </el-table-column>
                <el-table-column prop="response_status" label="响应状态"/>
                <el-table-column prop="frequency" label="请求数量" width="100">
                  <template #default="scope">
                    <span class="request-count">{{ scope.row.frequency }}</span>
                  </template>
                </el-table-column>
                <el-table-column label="响应时长（毫秒）">
                  <el-table-column prop="response_duration_min" label="最小值" width="100"/>
                  <el-table-column prop="response_duration_avg" label="平均值" width="100">
                    <template #default="scope">
                      <span class="avg-value">{{ scope.row.response_duration_avg }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column prop="response_duration_max" label="最大值" width="100"/>
                </el-table-column>
              </el-table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, reactive, onMounted, watch } from 'vue'
import { format } from 'date-fns'
import * as echarts from 'echarts'
import { onlineService } from "@/api/task"
import type {
  OnlineServicePieChartSlice,
  OnlineServicePieTableRow,
} from "@/api/types"
import { useRoute } from "vue-router"
import { 
  ArrowRight, 
  TrendCharts, 
  Histogram, 
  PieChart,
  DataAnalysis
} from "@element-plus/icons-vue"

// 定义接口
interface ChartData {
  graphType: string;
  yData: Array<string | number>;
  xData: Array<string | number>;
  pieData: OnlineServicePieChartSlice[];
  tableData: OnlineServicePieTableRow[];
}

interface MiddleParams {
  service_id?: string | string[];
  time_unit?: string;
  time_span_num?: number;
  start_time?: string;
  end_time?: string;
}

// 响应式状态
const defaultStart = ref('')
const defaultEnd = ref('')
const timeValue1 = ref<string[]>([])
const timeValue2 = ref<string[]>([])
const timeValue3 = ref<string[]>([])
const tableHeaderStyle = {
  background: '#d32f2f',
  color: '#ffffff',
  fontSize: '14px',
  fontWeight: '600',
  borderColor: '#a82525',
  textAlign: 'center',
  padding: '12px 0',
  height: '50px'
}
const tableCellStyle = {
  textAlign: 'center',
  fontSize: '14px',
  padding: '10px 0',
  color: '#303133'
}

const disabledDate = (time: Date) => {
  return time.getTime() > Date.now()
}

const shortcuts = [
  {
    text: '近一天',
    value: () => {
      const end = new Date()
      const start = new Date()
      start.setTime(start.getTime() - 3600 * 1000 * 24)
      return [start, end]
    },
  },
  {
    text: '近一周',
    value: () => {
      const end = new Date()
      const start = new Date()
      start.setTime(start.getTime() - 3600 * 1000 * 24 * 7)
      return [start, end]
    },
  },
  {
    text: '近一个月',
    value: () => {
      const end = new Date()
      const start = new Date()
      start.setTime(start.getTime() - 3600 * 1000 * 24 * 30)
      return [start, end]
    },
  },
  {
    text: '近三个月',
    value: () => {
      const end = new Date()
      const start = new Date()
      start.setTime(start.getTime() - 3600 * 1000 * 24 * 90)
      return [start, end]
    },
  },
]

const pageIndex = ref(1)
const loading = ref(true)
const serviceId = ref('')
const timeSpan = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
const timeUnitValue = ref('')
const timeunitvalue = ref('小时')
const timeUnit = ['小时', '天', '月']
const timeSpanNum = ref(1)

const chartData = reactive<ChartData>({
  graphType: 'LineChart',
  yData: [],
  xData: [],
  pieData: [],
  tableData: [],
})

const middle = reactive<MiddleParams>({})
const myChart = ref<HTMLElement | null>(null)

// 方法
function getStatusClass(code: number | string): string {
  if (!code) return 'status-unknown'
  
  const codeStr = code.toString()
  if (codeStr.startsWith('2')) return 'status-success'
  if (codeStr.startsWith('3')) return 'status-redirect'
  if (codeStr.startsWith('4')) return 'status-client-error'
  if (codeStr.startsWith('5')) return 'status-server-error'
  
  return 'status-unknown'
}

// function getBeforeOneDay(): void {
//   let start = new Date()
//   let end = new Date().toLocaleString().split('/').join('-')
//   let sta = start.setTime(start.getTime() - 3600 * 1000 * 24)
//   sta = new Date(sta).toLocaleString().split('/').join('-')
//   defaultStart.value = sta
//   defaultEnd.value = end
//   timeValue1.value = [defaultStart.value, defaultEnd.value]
//   timeValue2.value = [defaultStart.value, defaultEnd.value]
//   timeValue3.value = [defaultStart.value, defaultEnd.value]
//   console.log(timeValue1.value, 'beforeday')
// }


function getBeforeOneDay(): void {
  const now = new Date()
  const oneDayAgo = new Date(now.getTime() - 24 * 3600 * 1000)
  
  // 当 defaultStart/End 定义为 ref<string> 时
  defaultStart.value = format(oneDayAgo, 'yyyy-MM-dd HH:mm:ss')
  defaultEnd.value = format(now, 'yyyy-MM-dd HH:mm:ss')
  
  timeValue1.value = [defaultStart.value, defaultEnd.value]
  timeValue2.value = [defaultStart.value, defaultEnd.value]
  timeValue3.value = [defaultStart.value, defaultEnd.value]
}

function changePageIndex(param: number): void {
  pageIndex.value = param
}

function loadServiceLogLineChart(param?: MiddleParams): void {
  loading.value = true
  onlineService.getLineChart(param ? (param as any) : { service_id: serviceId.value || '' }).then(res => {
    chartData.xData = res.data.xData
    chartData.yData = res.data.yData
    console.log(res.data, 'res.data in LineChart')
  })
  setTimeout(() => {
    initChart() // 刷新图表
  }, 1000)
}

function loadServiceLogHistogram(param?: MiddleParams): void {
  loading.value = true
  onlineService.getHistogram(param ? (param as any) : { service_id: serviceId.value || '' }).then(res => {
    chartData.xData = res.data.xData
    chartData.yData = res.data.yData
    console.log(res.data, 'res.data in Histogram')
  })
  setTimeout(() => {
    initChart() // 刷新图表
  }, 1000)
}

function loadServiceLogPieChart(param?: MiddleParams): void {
  loading.value = true
  onlineService.getPieChart(param ? (param as any) : { service_id: serviceId.value || '' }).then(res => {
    chartData.pieData = res.data.pie_chart_data
    chartData.tableData = res.data.table_data
    console.log(res.data, 'res.data in PieChart')
  })
  setTimeout(() => {
    initChart() // 刷新图表
  }, 1000)
}

function changeGraphType(param: string): void {
  chartData.graphType = param
  timeunitvalue.value = "小时"
  timeSpanNum.value = 1
  let localMiddle: MiddleParams = {}

  if (param === 'LineChart') {
    localMiddle = {
      service_id: serviceId.value,
      time_unit: timeUnitValue.value,
      start_time: timeValue1.value[0],
      end_time: timeValue1.value[1]
    }
    loadServiceLogLineChart(localMiddle)
  } else if (param === 'Histogram') {
    localMiddle = {
      service_id: serviceId.value,
      time_span_num: timeSpanNum.value,
      start_time: timeValue2.value[0],
      end_time: timeValue2.value[1]
    }
    loadServiceLogHistogram(localMiddle)
  } else if (param === 'PieChart') {
    localMiddle = {
      service_id: serviceId.value,
      start_time: timeValue3.value[0],
      end_time: timeValue3.value[1]
    }
    loadServiceLogPieChart(localMiddle)
  }
}

function initChart(): void {
  let option: echarts.EChartsOption
  if (chartData.graphType === 'LineChart') {
    option = {
      title: {
        text: '请求数量时间趋势图',
        left: 'center'
      },
      tooltip: {
        trigger: 'item'
      },
      xAxis: {
        type: 'category',
        name: '时间',
        nameTextStyle: {
          fontWeight: "bold",
          fontSize: 14
        },
        nameGap: 25,
        boundaryGap: false,
        data: chartData.xData.map(function (str: string | number) {
          return String(str).replace(' ', '\n')
        })
      },
      yAxis: {
        name: '请求数量/个',
        nameLocation: 'middle',
        nameTextStyle: {
          fontWeight: "bold",
          fontSize: 15,
          padding: [14, 14, 14, 14]
        },
        type: 'value',
        minInterval: 1,
        axisLine: {
          show: true,
          symbol: ['none', 'arrow'],
          symbolSize: [9, 15],
          symbolOffset: [0, 12],
          lineStyle: {
            type: 'solid'
          }
        },
      },
      series: [
        {
          data: chartData.yData,
          type: 'line',
          lineStyle: {
            color: '#d32f2f',
            width: 3
          },
          itemStyle: {
            color: '#a82525'
          },
          areaStyle: {
            color: {
              type: 'linear',
              x: 0,
              y: 0,
              x2: 0,
              y2: 1,
              colorStops: [{
                offset: 0, color: 'rgba(211, 47, 47, 0.3)'
              }, {
                offset: 1, color: 'rgba(211, 47, 47, 0.05)'
              }],
            }
          }
        }
      ]
    }
  } else if (chartData.graphType === 'Histogram') {
    option = {
      title: {
        text: '请求数量时段分布图',
        left: 'center'
      },
      tooltip: {
        trigger: 'item'
      },
      xAxis: {
        type: 'category',
        name: '时间',
        nameTextStyle: {
          fontWeight: "bold",
          fontSize: 14
        },
        nameGap: 25,
        axisLabel: {interval: 0, rotate: 30},
        data: chartData.xData
      },
      yAxis: {
        name: '请求数量/个',
        nameLocation: 'middle',
        nameTextStyle: {
          fontWeight: "bold",
          fontSize: 15,
          padding: [14, 14, 14, 14]
        },
        type: 'value',
        minInterval: 1,
        axisLine: {
          show: true,
          symbol: ['none', 'arrow'],
          symbolSize: [9, 15],
          symbolOffset: [0, 12],
          lineStyle: {
            type: 'solid'
          }
        },
      },
      series: [
        {
          data: chartData.yData,
          type: 'bar',
          barWidth: '40%',
          itemStyle: {
            color: {
              type: 'linear',
              x: 0,
              y: 0,
              x2: 0,
              y2: 1,
              colorStops: [{
                offset: 0, color: '#a82525'
              }, {
                offset: 1, color: '#d32f2f'
              }],
            }
          }
        }
      ]
    }
  } else if (chartData.graphType === 'PieChart') {
    option = {
      title: {
        text: '请求响应状态分布图',
        left: 'center'
      },
      tooltip: {
        trigger: 'item',
        formatter: '{a} <br/>{b} : {c} ({d}%)'
      },
      legend: {
        bottom: 10,
        left: 'center'
      },
      series: [
        {
          name: '响应状态',
          type: 'pie',
          radius: '55%',
          center: ['50%', '50%'],
          data: chartData.pieData,
          emphasis: {
            itemStyle: {
              shadowBlur: 10,
              shadowOffsetX: 0,
              shadowColor: 'rgba(0, 0, 0, 0.5)'
            }
          },
          labelLine: {
            smooth: 0.2,
            length: 10,
            length2: 20
          },
          itemStyle: {
            color: function(params: { name: string }) {
              // 获取状态码，可能需要从名称中提取
              const statusMatch = params.name.match(/^(\d{3})/)
              const statusCode = statusMatch ? statusMatch[1] : ''
              
              // 根据状态码返回不同颜色
              if (statusCode.startsWith('2')) {  // 2xx 成功状态
                return 'var(--el-color-success)'  // 绿色
              } else if (statusCode.startsWith('3')) {  // 3xx 重定向
                return 'var(--el-color-info)'  // 灰色
              } else if (statusCode.startsWith('4')) {  // 4xx 客户端错误
                if (statusCode === '404') {
                  return 'var(--el-color-warning)'  // 404 用橙色
                }
                return 'var(--el-color-danger)'  // 其他客户端错误用红色
              } else if (statusCode.startsWith('5')) {  // 5xx 服务器错误
                return '#d81e06'  // 深红色
              }
              
              // 默认颜色
              return '#d32f2f'  // 蓝色
            }
          }
        }
      ]
    }
  }
  
  // 初始化图表
  const chartElement = document.querySelector('.chart-display') || document.querySelector('.pie-chart')
  if (chartElement && option!) {
    const chart = echarts.init(chartElement as HTMLElement)
    chart.clear()
    chart.setOption(option)
    loading.value = false
    console.log('作图完成')
  }
}

// 监听选项变化
watch(timeunitvalue, (newValue) => {
  if (newValue === '小时') {
    timeUnitValue.value = 'HOUR'
  } else if (newValue === '天') {
    timeUnitValue.value = 'DAY'
  } else if (newValue === '月') {
    timeUnitValue.value = 'MONTH'
  } else {
    console.log('timeunitvalue error')
  }
  middle.service_id = serviceId.value
  middle.time_unit = timeUnitValue.value
  middle.start_time = timeValue1.value[0]
  middle.end_time = timeValue1.value[1]
  loadServiceLogLineChart(middle)
})

watch(timeSpanNum, (newValue) => {
  middle.service_id = serviceId.value
  middle.time_span_num = newValue
  middle.start_time = timeValue2.value[0]
  middle.end_time = timeValue2.value[1]
  console.log(middle, 'middle in watch')
  if (pageIndex.value === 2) {
    loadServiceLogHistogram(middle)
    console.log('Histogram page in watch')
  } else {
    console.log('error')
  }
})

watch(pageIndex, (newValue) => {
  getBeforeOneDay()
  timeValue1.value = [defaultStart.value, defaultEnd.value]
  timeValue2.value = [defaultStart.value, defaultEnd.value]
  timeValue3.value = [defaultStart.value, defaultEnd.value]
  if (newValue === 1) {
    changeGraphType('LineChart')
    console.log('LineChart page in watch')
  } else if (newValue === 2) {
    changeGraphType('Histogram')
    console.log('Histogram page in watch')
  } else if (newValue === 3) {
    changeGraphType('PieChart')
    console.log('PieChart page in watch')
  } else {
    console.log('error')
  }
})

watch(timeValue1, (newvalue) => {
  console.log(timeValue1.value, 'timeValue1')
  if (newvalue != null) {
    if (pageIndex.value === 1) {
      middle.service_id = serviceId.value
      middle.time_unit = timeUnitValue.value
      middle.start_time = timeValue1.value[0]
      middle.end_time = timeValue1.value[1]
      loadServiceLogLineChart(middle)
      console.log('LineChart timevalue1 in watch')
    }
  }
})

watch(timeValue2, (newvalue) => {
  console.log(timeValue2.value, 'timeValue2')
  if (newvalue != null) {
    if (pageIndex.value === 2) {
      middle.service_id = serviceId.value
      middle.time_span_num = timeSpanNum.value
      middle.start_time = timeValue2.value[0]
      middle.end_time = timeValue2.value[1]
      loadServiceLogHistogram(middle)
      console.log('Histogram timevalue2 in watch')
    } 
  }
})

watch(timeValue3, (newvalue) => {
  console.log(timeValue3.value, 'timeValue3')
  if (newvalue != null) {
    if (pageIndex.value === 3) {
      middle.service_id = serviceId.value
      middle.start_time = timeValue3.value[0]
      middle.end_time = timeValue3.value[1]
      loadServiceLogPieChart(middle)
      console.log('PieChart timevalue3 in watch')
    }
  }
})

// 组件挂载时初始化
onMounted(() => {
  getBeforeOneDay()
  const route = useRoute()
  serviceId.value = route.query.serviceId as string
  middle.service_id = serviceId.value
  middle.time_unit = timeUnitValue.value
  middle.start_time = timeValue1.value[0]
  middle.end_time = timeValue1.value[1]
  loadServiceLogLineChart(middle)
  console.log(serviceId.value, timeValue1.value, 'serviceId in created')
})
</script>

<style scoped>
/* 基础布局样式 */
.visualization-container {
  display: flex;
  flex-direction: column;
}

/* 头部区域 - 与其他组件保持一致 */
.header-area {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 30px;
  background: linear-gradient(to right, #a82525, #d32f2f);
  border-radius: 4px;
  color: white;
  margin: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.tech-title {
  font-size: 18px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 10px;
  text-shadow: 0px 1px 2px rgba(0, 0, 0, 0.2);
}

.tech-title .el-icon {
  font-size: 22px;
  color: #ffffff;
}

.nav-breadcrumb {
  display: flex;
  align-items: center;
}

.tech-breadcrumb {
  font-size: 16px;
  font-weight: 600;
  color: #ffffff !important;
}

:deep(.tech-breadcrumb span),
:deep(.tech-breadcrumb div),
:deep(.tech-breadcrumb a) {
  color: #ffffff !important;
}

:deep(.el-breadcrumb__separator) {
  color: #ffffff !important;
}

/* 主内容区域 */
.main-content-wrapper {
  background-color: white;
  margin: 0 20px 20px;
  border-radius: 4px;
  box-shadow: 0 3px 12px rgba(0, 0, 0, 0.05);
  padding: 20px;
  min-height: calc(100vh - 150px);
}

/* 统计类型导航 */
.stats-nav-section {
  margin-bottom: 20px;
}

.stats-menu {
  border-radius: 4px;
  overflow: hidden;
  border: 1px solid #ebeef5;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.03);
}

:deep(.el-menu--horizontal) {
  border-bottom: none;
}

:deep(.el-menu--horizontal > .el-menu-item) {
  height: 50px;
  line-height: 50px;
  padding: 0 25px;
  font-weight: 500;
}

:deep(.el-menu--horizontal > .el-menu-item.is-active) {
  color: #d32f2f;
  border-bottom: 2px solid #d32f2f;
}

:deep(.el-menu-item:not(.is-active):hover) {
  color: #d32f2f !important;
  background-color: rgba(211, 47, 47, 0.05);
}

/* 图表区域 */
.chart-section {
  margin-top: 30px;
}

.chart-container {
  border-radius: 4px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.03);
  border: 1px solid #ebeef5;
  padding: 20px;
  margin-bottom: 20px;
}

.chart-controls {
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 1px solid #ebeef5;
}

.control-section {
  display: flex;
  flex-wrap: wrap;
  gap: 20px;
  justify-content: center;
  align-items: center;
}

.control-item {
  display: flex;
  align-items: center;
  gap: 15px;
}

.control-label {
  color: #606266;
  font-size: 14px;
  white-space: nowrap;
}

.date-picker {
  width: 400px;
}

.time-unit-selector {
  width: 100px;
}

.time-span-control {
  display: flex;
  align-items: center;
  gap: 10px;
}

.time-span-selector {
  width: 80px;
}

.unit-label {
  color: #606266;
}

/* 图表显示 */
.chart-display {
  width: 100%;
  height: 400px;
  margin-top: 30px;
}

/* 饼图和表格布局 */
.pie-chart-layout {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  margin-top: 30px;
  gap: 30px;
}

.pie-chart {
  flex: 1;
  min-width: 300px;
  height: 400px;
}

.status-table {
  flex: 1;
  min-width: 300px;
}

.status-data-table {
  width: 100%;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  overflow: hidden;
}

/* 加载动画样式 */
:deep(.el-loading-mask) {
  background-color: rgba(255, 255, 255, 0.9);
}

:deep(.el-loading-spinner .circular) {
  width: 42px;
  height: 42px;
}

:deep(.el-loading-spinner .path) {
  stroke: #d32f2f;
  stroke-width: 2;
}

/* 响应式调整 */
@media screen and (max-width: 1200px) {
  .control-section {
    flex-direction: column;
    align-items: flex-start;
  }
  
  .control-item {
    width: 100%;
    flex-wrap: wrap;
  }
  
  .date-picker,
  .time-unit-selector,
  .time-span-control {
    width: 100%;
  }
  
  .pie-chart-layout {
    flex-direction: column;
  }
  
  .pie-chart,
  .status-table {
    width: 100%;
  }
}

@media screen and (max-width: 768px) {
  .header-area {
    padding: 15px 20px;
  }
  
  .tech-title {
    font-size: 16px;
  }
  
  :deep(.el-menu--horizontal > .el-menu-item) {
    padding: 0 15px;
    font-size: 14px;
  }
  
  .chart-controls {
    padding: 15px;
  }
  
  .chart-display,
  .pie-chart {
    height: 300px;
  }
}

.table-title {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 4px;
}

.table-subtitle {
  font-size: 13px;
  opacity: 0.85;
}


/* 表格容器样式优化 */
.status-table {
  flex: 1;
  min-width: 300px;
  border-radius: 4px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  background-color: #ffffff;
  border: none; /* 移除外边框 */
  display: flex;
  flex-direction: column;
}

/* 表格标题区域 */
.table-header {
  background: #d32f2f;
  color: white;
  padding: 15px 20px;
  border-top-left-radius: 8px;
  border-top-right-radius: 8px;
  margin-bottom: 0;
}

/* 表格样式增强 */
.status-data-table {
  width: 100%;
  margin: 0;
  border: none;
}

/* 去除表格所有边框 */
:deep(.el-table) {
  border: none !important;
}

:deep(.el-table--border) {
  border: none !important;
  border-right: none !important;
  border-bottom: none !important;
}

:deep(.el-table--border .el-table__inner-wrapper) {
  border: none !important;
}

:deep(.el-table__inner-wrapper) {
  border: none !important;
}

:deep(.el-table__header-wrapper th.el-table__cell) {
  background-color: #e8f0f9;
  color: #d32f2f;
  border-color: #e8f0f9; /* 与背景同色，消除边框 */
  border-bottom: 1px solid #d0e0f2; /* 只保留底部边框 */
}

:deep(.el-table__header) {
  border: none !important;
}

:deep(.el-table__body) {
  border: none !important;
}

:deep(.el-table__cell) {
  border-bottom: 1px solid #ebeef5 !important;
  border-right: none !important;
}

:deep(.el-table__body tr:last-child td.el-table__cell) {
  border-bottom: none !important; /* 移除最后一行底部边框 */
}

:deep(.el-table--border::after),
:deep(.el-table--border::before),
:deep(.el-table__border-left-patch) {
  display: none !important;
}

:deep(.el-table__fixed-right::before),
:deep(.el-table__fixed::before) {
  display: none !important;
}

/* 斑马纹样式优化 */
:deep(.el-table--striped .el-table__body tr.el-table__row--striped td.el-table__cell) {
  background-color: #f5f7fa;
}

:deep(.el-table__body tr:hover > td.el-table__cell) {
  background-color: #edf2fc;
}

/* 标题栏与表格间无缝连接 */
:deep(.el-table__header-wrapper) {
  margin-top: -1px;
}

/* 状态码样式优化 */
.status-success,
.status-redirect,
.status-client-error,
.status-server-error,
.status-unknown {
  font-weight: 600;
  padding: 4px 8px;
  border-radius: 4px;
  display: inline-block;
  min-width: 60px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.status-success {
  background-color: #f0f9eb;
  color: var(--el-color-success);
  border: 1px solid #e1f3d8;
}

.status-redirect {
  background-color: #f4f4f5;
  color: var(--el-color-info);
  border: 1px solid #e9e9eb;
}

.status-client-error {
  background-color: #fef0f0;
  color: var(--el-color-danger);
  border: 1px solid #fde2e2;
}

.status-server-error {
  background-color: #fef6ed;
  color: var(--el-color-warning);
  border: 1px solid #faecd8;
}

.status-unknown {
  background-color: #f4f4f5;
  color: var(--el-color-info);
  border: 1px solid #e9e9eb;
}

/* 单元格内边距优化 */
:deep(.el-table .cell) {
  padding: 10px 8px;
}

/* 请求数量和平均值样式优化 */
.request-count {
  font-weight: 600;
  color: #d32f2f;
}

.avg-value {
  font-weight: 600;
  color: #a82525;
}

/* 饼图样式匹配 */
.pie-chart {
  flex: 1;
  min-width: 300px;
  height: 400px;
  border-radius: 4px;
  border: 1px solid #dcdfe6;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  background-color: #ffffff;
  padding: 20px;
}
</style>