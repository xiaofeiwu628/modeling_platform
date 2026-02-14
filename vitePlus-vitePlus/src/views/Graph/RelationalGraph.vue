<template>
  <div class="container">
    <!-- 头部 -->
    <div class="top">
      <div v-if="hasLogin" class="back" @click="exit">
        <svg-icon name="back"></svg-icon>
      </div>
      <div v-else class="logo">
        <svg-icon height="30px" name="logo" width="30px"></svg-icon>
        <span class="title">{{ appTitle }}</span>
      </div>
      <div class="tabbar-center">
        <el-input
          v-if="queryParams.searchMode !== SearchModeEnum.NODE_AND_RELATION"
          v-model="queryParams.keyword"
          :placeholder="`搜索${SearchModeMap[queryParams.searchMode]}`"
          class="keyword_input"
          @keydown.enter="getNewGraphData()"
        >
          <template #prepend>
            <span class="graph_name" :title="graphData.name">{{ graphData.name }}</span>
          </template>
        </el-input>
        <span v-else>
          <el-input
            v-model="queryParams.startText"
            class="start_text_input"
            placeholder="前键"
            @keydown.enter="getNewGraphData()"
          >
            <template #prepend>
              <span class="graph_name">{{ graphData.name }}</span>
            </template>
          </el-input>
          <el-input
            v-model="queryParams.relationText"
            class="relation_text_input"
            placeholder="关系"
            @keydown.enter="getNewGraphData()"
          ></el-input>
          <el-input
            v-model="queryParams.endText"
            class="end_text_input"
            placeholder="后键"
            @keydown.enter="getNewGraphData()"
          ></el-input>
        </span>
        <el-dropdown class="search_mode" trigger="click" @command="changeSearchMode">
          <span>
            <svg-icon
              :name="searchModeIcon[queryParams.searchMode].label"
              height="20px"
              width="20px"
            ></svg-icon>
            <el-icon class="el-icon--right"><arrow-down /></el-icon>
          </span>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item
                v-for="item in searchModeIcon"
                :key="item.value"
                :command="item.value"
              >
                <svg-icon :name="item.label" height="20px" width="20px"></svg-icon>
              </el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
        <el-button
          :icon="Search"
          :type="fuzzyQueryBtnType"
          class="searchBtn"
          @click="getNewGraphData(0)"
        >
          模糊
        </el-button>
        <el-button
          :icon="Search"
          :type="exactQueryBtnType"
          class="searchBtn"
          @click="getNewGraphData(1)"
        >
          精确
        </el-button>
      </div>
      <div class="top-right">
        <template v-if="hasLogin && currentGraphId">
          <el-button class="add-btn" size="small" @click="openAddNodeDialog">添加节点</el-button>
          <el-button class="add-btn" size="small" @click="openAddRelationDialog">添加关系</el-button>
        </template>
        <el-popover placement="bottom-end" width="220" trigger="click">
        <template #reference>
          <el-button circle icon="Setting" />
        </template>
        <template #default>
          <el-form inline label-suffix=":" label-width="80px">
            <el-form-item label="路径数量">
              <el-input-number
                v-model="queryParams.pathCount"
                :step="1"
                :max="300"
                :min="1"
                size="small"
              />
            </el-form-item>
            <el-form-item label="路径长度">
              <el-input-number
                v-model="queryParams.pathLength"
                :step="1"
                :max="6"
                :min="1"
                size="small"
              />
            </el-form-item>
            <el-form-item label="节点关系">
              <el-switch
                v-model="isShowEdgeLabel"
                :active-action-icon="View"
                :inactive-action-icon="Hide"
                inline-prompt
              />
            </el-form-item>
            <el-form-item label="节点名称">
              <el-switch
                v-model="isShowLabel"
                :active-action-icon="View"
                :inactive-action-icon="Hide"
                inline-prompt
              />
            </el-form-item>
          </el-form>
        </template>
        </el-popover>
      </div>
      <div class="backAndForward">
        <el-button :icon="Back" class="nav-btn" size="small" @click="back">后退</el-button>
        <el-button class="nav-btn" size="small" @click="forward">
          前进
          <el-icon class="el-icon--right">
            <Right />
          </el-icon>
        </el-button>
      </div>
    </div>
    <!--  绘图容器：占满顶部以下剩余空间 -->
    <div class="chartWrap">
      <div ref="graphDom" class="chartDom"></div>
    </div>
    <div class="scaleSlider">
      <el-button :icon="Plus" circle class="upScaleBtn" size="small" @click="zoomIn"></el-button>
      <el-slider
        v-model="scaleValue"
        :max="3"
        :min="0.3"
        :step="0.01"
        height="200px"
        vertical
        @input="changeScale"
      />
      <el-button
        :icon="Minus"
        circle
        class="downScaleBtn"
        size="small"
        @click="zoomOut"
      ></el-button>
    </div>

    <!-- 添加节点弹窗 -->
    <el-dialog v-model="addNodeVisible" title="添加节点" width="420px" destroy-on-close @closed="addNodeForm.nodeId = ''; addNodeForm.label = ''; addNodeForm.text = ''">
      <el-form :model="addNodeForm" label-width="80px">
        <el-form-item label="节点ID">
          <el-input v-model="addNodeForm.nodeId" placeholder="唯一标识，如 n1" />
        </el-form-item>
        <el-form-item label="标签">
          <el-input v-model="addNodeForm.label" placeholder="如 人物" />
        </el-form-item>
        <el-form-item label="文本">
          <el-input v-model="addNodeForm.text" placeholder="显示名称" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addNodeVisible = false">取消</el-button>
        <el-button type="primary" :loading="addNodeLoading" @click="submitAddNode">确定</el-button>
      </template>
    </el-dialog>

    <!-- 添加关系弹窗 -->
    <el-dialog v-model="addRelationVisible" title="添加关系" width="420px" destroy-on-close @closed="addRelationForm.startNodeId = ''; addRelationForm.relationText = ''; addRelationForm.endNodeId = ''">
      <el-form :model="addRelationForm" label-width="90px">
        <el-form-item label="起点节点ID">
          <el-input v-model="addRelationForm.startNodeId" placeholder="已存在的节点 nodeId" />
        </el-form-item>
        <el-form-item label="关系">
          <el-input v-model="addRelationForm.relationText" placeholder="如 位于" />
        </el-form-item>
        <el-form-item label="终点节点ID">
          <el-input v-model="addRelationForm.endNodeId" placeholder="已存在的节点 nodeId" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addRelationVisible = false">取消</el-button>
        <el-button type="primary" :loading="addRelationLoading" @click="submitAddRelation">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script lang="ts" setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import * as echarts from 'echarts'
import { graph, createNode, createRelation } from '@/api/graph'
import type { GraphDetailVO, GraphSearchRequest, Link } from '@/api/types'
import { ElMessage } from 'element-plus'
import { Back, Hide, Minus, Plus, Right, Search, View } from '@element-plus/icons-vue'
import { refreshSvg } from '@/utils/svg'
import { useRoute, useRouter } from 'vue-router'
import { GraphMatchModeEnum } from '@/enums/GraphMatchModeEnum'
import { SearchModeEnum, SearchModeMap } from '@/enums/SearchModeEnum'
import SvgIcon from '@/components/SvgIcon/index.vue'
import { getStoredToken } from '@/utils/token'

const appTitle = import.meta.env.VITE_APP_TITLE || '智能中台建模平台'

// 路由器
const $router = useRouter()
// 路由
const $route = useRoute()
// 是否登录（用于显示返回按钮）
const hasLogin = ref(Boolean(getStoredToken()))
// 图的Dom
const graphDom = ref<HTMLElement>()
// 关系图实例
let graphChart: echarts.ECharts
// 关系图数据
const graphData = ref<GraphDetailVO>({} as GraphDetailVO)
// 是否显示连线标签
const isShowEdgeLabel = ref(true)
// 返回箭头颜色
const leftArrowColor = ref('#aaa')
// 前进箭头颜色
const rightArrowColor = ref('#aaa')
// 模糊查询按钮颜色
const fuzzyQueryBtnType = ref('default')
// 精确查询按钮颜色
const exactQueryBtnType = ref('default')
// 是否显示标签
const isShowLabel = ref(true)
// 查询记录
const queryRecord = ref<GraphSearchRequest[]>([])
// 查询索引
const currRecordIndex = ref<number>(-1)
// 查询参数
const queryParams = ref<GraphSearchRequest>({
  id: '',
  searchMode: 0,
  keyword: '',
  startText: '',
  relationText: '',
  endText: '',
  matchMode: 0,
  pathLength: 3,
  pathCount: 200,
})
// 缩放比例
const scaleValue = ref(1)
// 当前图谱 ID（用于添加节点/关系）
const currentGraphId = computed(() => {
  const id = queryParams.value.id
  if (id == null || id === '') return null
  const num = typeof id === 'string' ? parseInt(id, 10) : id
  return Number.isNaN(num) ? null : num
})
// 添加节点/关系弹窗
const addNodeVisible = ref(false)
const addRelationVisible = ref(false)
const addNodeLoading = ref(false)
const addRelationLoading = ref(false)
const addNodeForm = ref({ nodeId: '', label: '', text: '' })
const addRelationForm = ref({ startNodeId: '', relationText: '', endNodeId: '' })
// 搜索模式图标选择
const searchModeIcon = [
  {
    value: SearchModeEnum.NODE,
    label: 'node',
  },
  {
    value: SearchModeEnum.RELATION,
    label: 'relation',
  },
  {
    value: SearchModeEnum.LABEL,
    label: 'label',
  },
  {
    value: SearchModeEnum.NODE_AND_RELATION,
    label: 'node-and-relation',
  },
]

// 改变搜索模式
const changeSearchMode = (command: string) => {
  queryParams.value.searchMode = parseInt(command, 10)
}

// 添加节点
const openAddNodeDialog = () => {
  addNodeForm.value = { nodeId: '', label: '', text: '' }
  addNodeVisible.value = true
}
const submitAddNode = async () => {
  const gid = currentGraphId.value
  if (gid == null) return
  const { nodeId, label, text } = addNodeForm.value
  if (!nodeId?.trim()) {
    ElMessage.warning('请填写节点ID')
    return
  }
  addNodeLoading.value = true
  try {
    await createNode({ nodeId: nodeId.trim(), label: label?.trim() ?? '', text: text?.trim() ?? '', graphId: gid })
    ElMessage.success('节点已添加')
    addNodeVisible.value = false
    getGraphData()
  } catch (e: any) {
    ElMessage.error(e?.message || e?.data?.message || '添加失败')
  } finally {
    addNodeLoading.value = false
  }
}

// 添加关系
const openAddRelationDialog = () => {
  addRelationForm.value = { startNodeId: '', relationText: '', endNodeId: '' }
  addRelationVisible.value = true
}
const submitAddRelation = async () => {
  const gid = currentGraphId.value
  if (gid == null) return
  const { startNodeId, relationText, endNodeId } = addRelationForm.value
  if (!startNodeId?.trim() || !endNodeId?.trim()) {
    ElMessage.warning('请填写起点与终点节点ID')
    return
  }
  addRelationLoading.value = true
  try {
    await createRelation({
      startNodeId: startNodeId.trim(),
      relationText: relationText?.trim() ?? '',
      endNodeId: endNodeId.trim(),
      graphId: gid,
    })
    ElMessage.success('关系已添加')
    addRelationVisible.value = false
    getGraphData()
  } catch (e: any) {
    ElMessage.error(e?.message || e?.data?.message || '添加失败')
  } finally {
    addRelationLoading.value = false
  }
}

// 初始化数据
const initData = () => {
  queryParams.value.id = ($route.query.graphId as string) || ''
}

// 初始化图表
const initChart = () => {
  if (!graphDom.value) return
  graphChart = echarts.init(graphDom.value)
  const option: echarts.EChartsOption = {
    tooltip: {
      confine: true,
      textStyle: {
        fontSize: 18,
      },
    },
    toolbox: {
      show: true,
      feature: {
        myRefresh: {
          show: true,
          title: '刷新',
          icon: refreshSvg,
          onclick: function () {
            getGraphData()
          },
        },
        saveAsImage: {
          name: '图谱',
          title: '保存为图片',
        },
      },
      right: 10,
      top: 10,
      z: 100,
    },
    grid: {
      top: 100,
    },
    legend: {
      show: true,
      itemGap: 10,
      right: 0,
      bottom: 0,
      padding: 15,
      orient: 'vertical',
    },
    color: [
      '#1baccc',
      '#2db68d',
      '#feae01',
      '#E37F54',
      '#FFB0B0',
      '#4e66e0',
      '#3b9fd6',
      '#a6a6a6',
      '#ef3b3b',
      '#bc4ee0',
      '#f5879b',
      '#458630',
      '#b7a6d7',
      '#fde971',
      '#b3cde0',
      '#a6d7d0',
      '#9d684b',
      '#cf9ef6',
    ],
    series: [
      {
        type: 'graph',
        layout: 'force',
        legendHoverLink: false,
        roam: true,
        nodeScaleRatio: 0.6,
        zoom: 1,
        draggable: true,
        symbolSize: 35,
        edgeSymbol: ['none', 'arrow'],
        edgeSymbolSize: 10,
        scaleLimit: {
          min: 0.3,
          max: 3,
        },
        label: {
          show: true,
          position: 'right',
          formatter: '{b}',
          color: 'inherit',
          width: 60,
          overflow: 'truncate',
        },
        edgeLabel: {
          show: true,
          lineHeight: 10,
          formatter: '{c}',
          overflow: 'truncate',
          width: 80,
          fontSize: 12,
        },
        lineStyle: {
          color: 'source',
          curveness: 0.1,
          opacity: 0.8,
        },
        force: {
          repulsion: 120,
          gravity: 0.04,
          edgeLength: 130,
          layoutAnimation: true,
        },
        animationDurationUpdate: 5500,
        emphasis: {
          lineStyle: {
            width: 7,
          },
          focus: 'adjacency',
        },
      },
    ],
  }
  graphChart.setOption(option)
  graphChart.on('click', { dataType: 'node' }, function ({ data }: any) {
    queryParams.value.searchMode = SearchModeEnum.NODE
    queryParams.value.keyword = data.name
    getNewGraphData()
  })
  graphChart.on('click', { dataType: 'edge' }, function ({ data }: any) {
    queryParams.value.searchMode = SearchModeEnum.RELATION
    queryParams.value.keyword = data.value
    getNewGraphData()
  })
  graphChart.on('graphroam', function ({ zoom }: any) {
    if (typeof zoom === 'number') {
      scaleValue.value = parseFloat((zoom * scaleValue.value).toFixed(2))
      if (scaleValue.value < 0.3) {
        scaleValue.value = 0.3
      } else if (scaleValue.value > 3) {
        scaleValue.value = 3
      }
    }
  })
}

// 调整图表大小
const resizeChart = () => {
  graphChart.resize()
}

// 如果相同的起点和终点有多个，修改连线的弧度
const changeEdgeCurveness = (links: Link[]) => {
  const map = new Map()
  for (let i = 0; i < links.length; i++) {
    const link = links[i]
    const key = link.source + '-' + link.target
    if (map.has(key)) {
      map.set(key, map.get(key) + 0.2)
      link.lineStyle = {
        curveness: map.get(key),
      }
    } else {
      map.set(key, 0.1)
    }
  }
  return links
}

// 请求图表数据（id 保持字符串，避免大整数精度丢失）
const getGraphData = async () => {
  const id = queryParams.value.id
  if (id == null || id === '' || !/^\d+$/.test(String(id))) {
    return
  }
  graphChart.showLoading()
  try {
    const result = await graph.search(queryParams.value)
    const data = result?.data
    if (!data || (result?.code !== 0 && result?.code !== '0')) {
      ElMessage.warning(result?.msg || '图谱数据为空')
      graphChart.hideLoading()
      return
    }
    graphData.value = data
    document.title = `${appTitle}-${data.name || '图谱'}`
    const nodes = data.nodes ?? []
    const rawLinks = data.links ?? []
    // 用节点下标作为 source/target，保证 ECharts 能正确画边（避免 id 精度或类型不匹配）
    const idToIndex: Record<string, number> = {}
    nodes.forEach((n, i) => {
      if (n.id != null) idToIndex[String(n.id)] = i
    })
    const links = rawLinks
      .map((l) => {
        const si = idToIndex[String(l.source)]
        const ti = idToIndex[String(l.target)]
        if (si == null || ti == null) return null
        return { ...l, source: si, target: ti }
      })
      .filter((l): l is Link => l != null)
    const option = {
      series: [
        {
          data: nodes,
          categories: data.categories ?? [],
          links: changeEdgeCurveness(links),
        },
      ],
    }
    graphChart.setOption(option)
  } catch (error) {
    ElMessage.error('图谱加载失败，请稍后重试（若未安装 Neo4j，后端会从 MySQL 降级加载）')
  } finally {
    graphChart.hideLoading()
  }
}

// 首次直接访问一个节点
const getNewGraphData = (matchMode?: GraphMatchModeEnum) => {
  const id = queryParams.value.id
  if (id === undefined || id === '' || !/^\d+$/.test(String(id))) {
    return
  }
  if (matchMode !== undefined) {
    queryParams.value.matchMode = matchMode
  }
  if (queryRecord.value.length > 0) {
    const lastQuery = queryRecord.value[queryRecord.value.length - 1]
    if (
      lastQuery.searchMode === queryParams.value.searchMode &&
      lastQuery.keyword === queryParams.value.keyword &&
      lastQuery.startText === queryParams.value.startText &&
      lastQuery.relationText === queryParams.value.relationText &&
      lastQuery.endText === queryParams.value.endText &&
      lastQuery.matchMode === queryParams.value.matchMode &&
      lastQuery.pathLength === queryParams.value.pathLength &&
      lastQuery.pathCount === queryParams.value.pathCount
    ) {
      return
    }
  }
  queryRecord.value = (queryRecord.value || []).slice(0, currRecordIndex.value + 1)
  queryRecord.value.push({
    ...queryParams.value,
  })
  currRecordIndex.value = queryRecord.value.length - 1
  getGraphData()
}

// 返回上次查询结果
const back = () => {
  if (currRecordIndex.value > 0) {
    currRecordIndex.value--
    queryParams.value = { ...queryRecord.value[currRecordIndex.value] }
    getGraphData()
  }
}

// 前往下次查询结果
const forward = () => {
  if (currRecordIndex.value < queryRecord.value.length - 1) {
    currRecordIndex.value++
    queryParams.value = { ...queryRecord.value[currRecordIndex.value] }
    getGraphData()
  }
}

// 缩放
const changeScale = () => {
  graphChart.setOption({
    series: [
      {
        zoom: scaleValue.value,
      },
    ],
  })
}

// 放大
const zoomIn = () => {
  if (scaleValue.value < 3) {
    scaleValue.value = parseFloat((scaleValue.value + 0.1).toFixed(2))
    changeScale()
  }
}

// 缩小
const zoomOut = () => {
  if (scaleValue.value > 0.3) {
    scaleValue.value = parseFloat((scaleValue.value - 0.1).toFixed(2))
    changeScale()
  }
}

// 连线标签按钮状态改变
watch(
  () => isShowEdgeLabel.value,
  (value) => {
    const option = {
      series: [
        {
          edgeLabel: {
            show: value,
          },
        },
      ],
    }
    graphChart.setOption(option)
  },
)

// 点击左上角返回按钮：优先根据来源跳转，否则返回图谱服务
const exit = () => {
  const lastPos = $route.params.lastPos || $route.query.lastPos
  const lastPosString = typeof lastPos === 'string' ? lastPos : ''
  const routeMap: Record<string, string> = {
    Datascreen: '/datascreen',
    DataView: '/dataView',
    EntityView: '/entityView',
    Home: '/home',
    GraphList: '/graphList',
  }
  if (routeMap[lastPosString]) {
    $router.push(routeMap[lastPosString])
    return
  }
  $router.push('/graphList')
}

// 标签状态改变
watch(
  () => isShowLabel.value,
  (value) => {
    const option = {
      series: [
        {
          label: {
            show: value,
          },
        },
      ],
    }
    graphChart.setOption(option)
  },
)

// 根据查询数组和索引动态修改箭头颜色
watch(
  () => currRecordIndex.value,
  (index) => {
    if (index <= 0) {
      leftArrowColor.value = '#aaa'
    } else {
      leftArrowColor.value = '#0273e8'
    }
    if (index === queryRecord.value.length - 1) {
      rightArrowColor.value = '#aaa'
    } else {
      rightArrowColor.value = '#0273e8'
    }
  },
)

// 监听模式改变，设置按钮状态
watch(
  () => queryParams.value.matchMode,
  (newValue) => {
    if (newValue === 0) {
      fuzzyQueryBtnType.value = 'success'
      exactQueryBtnType.value = 'default'
    } else if (newValue === 1) {
      fuzzyQueryBtnType.value = 'default'
      exactQueryBtnType.value = 'success'
    }
  },
  { immediate: true },
)

// 挂载
onMounted(async () => {
  initData()
  initChart()
  getNewGraphData(queryParams.value.matchMode)
  addEventListener('resize', resizeChart)
})

// 卸载
onUnmounted(() => {
  graphChart.dispose()
  removeEventListener('resize', resizeChart)
  document.title = appTitle
})
</script>

<style lang="scss" scoped>
/* 根部容器：左侧导航栏以右、整页高度，顶部栏+图表区 */
.container {
  position: relative;
  display: flex;
  flex-direction: column;
  height: 100vh;
  overflow: hidden;
  background-color: #fbfcfa;
}

/* 顶部区域（返回栏）：不伸缩 */
.top {
  flex-shrink: 0;
  position: relative;
  display: flex;
  flex-wrap: nowrap;
  justify-content: space-between;
  padding: 2.2vh;
  white-space: nowrap;
  background-color: #f2f3f3;

  .logo {
    position: relative;
    display: flex;
    align-items: center;
    cursor: pointer;

    .title {
      position: absolute;
      left: 35px;
      font-size: 20px;
      font-style: italic;
      font-weight: bold;
      color: #409eff;
    }
  }

  .title {
    width: 100px;
    font-size: 20px;
    font-style: italic;
    font-weight: bold;
    line-height: 1.5;
    color: #409eff;
  }

  :deep(.el-input-group__prepend) {
    background-color: #f5f7fa;
  }

  .search_mode {
    margin-top: 5px;
    margin-left: 10px;
    cursor: pointer;
  }

  .tabbar-center {
    flex: 1 1 auto;
    min-width: 720px;
    margin: 0 12px;
  }

  .top-right {
    display: flex;
    align-items: center;
    flex-shrink: 0;
    gap: 8px;
  }

  .graph_name {
    min-width: 6rem;
    max-width: 11rem;
    overflow: hidden;
    text-align: center;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  :deep(.el-input__inner) {
    text-align: center;
  }

  .keyword_input {
    width: 11rem;
  }

  .start_text_input {
    width: 6rem;

    :deep(.el-input__wrapper) {
      border-radius: 0;
      box-shadow:
        0 1px 0 0 var(--el-input-border-color, var(--el-border-color)) inset,
        0 -1px 0 0 var(--el-input-border-color, var(--el-border-color)) inset,
        1px 0 0 0 var(--el-input-border-color, var(--el-border-color)) inset;
    }
  }

  .relation_text_input {
    width: 3.5rem;

    :deep(.el-input__wrapper) {
      border-radius: 0;
      box-shadow:
        0 1px 0 0 var(--el-input-border-color, var(--el-border-color)) inset,
        0 -1px 0 0 var(--el-input-border-color, var(--el-border-color)) inset;
    }

    :deep(.el-input__wrapper)::before,
    :deep(.el-input__wrapper)::after {
      position: absolute;
      top: 25%;
      width: 1px;
      height: 50%;
      content: '';
      background-color: var(--el-input-border-color, var(--el-border-color));
    }

    :deep(.el-input__wrapper)::before {
      left: 0;
    }

    :deep(.el-input__wrapper)::after {
      right: 0;
    }
  }

  .end_text_input {
    width: 3.5rem;

    :deep(.el-input__wrapper) {
      border-start-start-radius: 0;
      border-end-start-radius: 0;
      box-shadow:
        0 1px 0 0 var(--el-input-border-color, var(--el-border-color)) inset,
        0 -1px 0 0 var(--el-input-border-color, var(--el-border-color)) inset,
        -1px 0 0 0 var(--el-input-border-color, var(--el-border-color)) inset;
    }
  }
}

.back {
  font-size: 20px;
  cursor: pointer;
}

.back::after {
  float: right;
  font-size: 19px;
  font-weight: bold;
  line-height: 1.5;
  color: #409eff;
  content: '返回';
}

.switch {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  width: 170px;
}

.add-btn {
    margin-right: 0;
  }
  .backAndForward {
  position: absolute;
  bottom: -50px;
  left: 20px;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: space-around;
  width: 80px;
  height: 50px;
  font-size: 20px;
}

.nav-btn {
  cursor: pointer;
}

.nav-btn:first-child {
  color: v-bind(leftArrowColor);
}

.nav-btn:last-child {
  color: v-bind(rightArrowColor);
}

.nav-btn:hover {
  background-color: transparent;
}

.nav-btn:focus {
  background-color: transparent;
  border: 1px solid rgb(124 124 124 / 20%);
}

.searchBtn {
  margin-left: 12px;
}

/* 绘图区外层：占满剩余空间 */
.chartWrap {
  flex: 1;
  min-height: 0;
  position: relative;
  width: 100%;
}

/* 绘图区：全屏填满（左侧导航栏以右、返回以下） */
.chartDom {
  width: 100%;
  height: 100%;
}

.scaleSlider {
  position: absolute;
  top: 28%;
  right: 15px;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 7px 0;
  border-radius: 50%;
}

.upScaleBtn,
.downScaleBtn {
  margin: 10px;
  font-size: 17px;
  color: #5da3ea;
  background-color: transparent;
}
</style>
