<template>
  <div class="graph-list-page">
    <!-- 顶部导航区域：与数据集管理一致，深蓝底 + 白底蓝字统计卡片 -->
    <div class="header-area">
      <el-breadcrumb :separator-icon="separatorIcon">
        <el-breadcrumb-item class="tech-title">
          <el-icon><Connection /></el-icon>
          图谱服务
        </el-breadcrumb-item>
      </el-breadcrumb>
      <div class="graph-metrics">
        <div class="metric-card">
          <div class="metric-value">{{ pagination.total }}</div>
          <div class="metric-label">图谱总数</div>
        </div>
      </div>
    </div>

    <div class="content-panel">
      <!-- 搜索区域：与数据集管理一致，灰底 + 左侧创建按钮 + 右侧搜索 -->
      <div class="search-container">
        <div class="left-area">
          <el-button type="primary" class="create-btn" @click="openCreateDialog">
            <el-icon><Plus /></el-icon>新建图谱
          </el-button>
        </div>
        <div class="right-area">
          <el-input
            v-model="keyword"
            placeholder="请输入关键字搜索"
            clearable
            class="tech-input"
            @keyup.enter="load"
            @clear="load"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
          <el-button type="primary" class="search-btn" @click="load">
            <el-icon><Search /></el-icon>查询
          </el-button>
        </div>
      </div>

      <!-- 图谱列表表格 -->
      <div class="table-container">
        <el-table
          v-loading="loading"
          :data="list"
          border
          stripe
          class="data-table"
          style="width: 100%"
          :cell-style="{ 'text-align': 'center' }"
          :header-cell-style="{ 'text-align': 'center', background: '#a82525', color: '#fff', fontWeight: '600' }"
        >
        <el-table-column prop="name" label="图谱名称" min-width="140" show-overflow-tooltip>
          <template #default="{ row }">
            {{ row.name ?? '--' }}
          </template>
        </el-table-column>
        <el-table-column prop="description" label="图谱描述" min-width="180" show-overflow-tooltip>
          <template #default="{ row }">
            {{ row.description || '--' }}
          </template>
        </el-table-column>
        <el-table-column label="图谱权限" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.isPublic === 1" type="success" effect="dark" round>公开</el-tag>
            <el-tag v-else type="primary" effect="dark" round>私有</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="上传时间" width="170" />
        <el-table-column label="操作" width="260" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" :disabled="row.status !== 0" @click="enterGraph(row)">
              <el-icon><View /></el-icon>
              查看
            </el-button>
            <el-button type="primary" link size="small" disabled>
              <el-icon><Edit /></el-icon>
              编辑
            </el-button>
            <el-button
              v-if="row.isPublic === 0"
              type="primary"
              link
              size="small"
              @click="handlePublish(row)"
            >
              <el-icon><Upload /></el-icon>
              发布
            </el-button>
            <el-popconfirm title="确定删除该图谱吗？" @confirm="handleDelete(row)">
              <template #reference>
                <el-button type="danger" link size="small">
                  <el-icon><Delete /></el-icon>
                  删除
                </el-button>
              </template>
            </el-popconfirm>
          </template>
        </el-table-column>
      </el-table>
      <!-- 分页 -->
      <div class="pagination-wrap">
        <span class="total-text">共{{ pagination.total }}条</span>
        <el-pagination
          v-model:current-page="pagination.current"
          v-model:page-size="pagination.pageSize"
          :total="pagination.total"
          :page-sizes="[10, 20, 50]"
          layout="prev, pager, next"
          class="pager"
          @current-change="load"
        />
        <span class="jump-text">前往</span>
        <el-input
          v-model.number="jumpPage"
          type="number"
          min="1"
          :max="maxPage"
          class="jump-input"
          @keyup.enter="goToPage"
        />
        <span class="jump-text">页</span>
        <el-select v-model="pagination.pageSize" class="page-size-select" @change="load">
          <el-option :value="10" label="10条/页" />
          <el-option :value="20" label="20条/页" />
          <el-option :value="50" label="50条/页" />
        </el-select>
      </div>
      </div>
    </div>

    <!-- 新建图谱弹窗：三步 基本信息 → 节点文件 → 关系文件 -->
    <el-dialog
      v-model="createVisible"
      title="新建图谱"
      width="720px"
      :close-on-click-modal="false"
      destroy-on-close
      class="create-graph-dialog"
      @closed="resetCreateForm"
    >
      <el-steps :active="createStep" finish-status="success" align-center class="create-steps">
        <el-step title="基本信息" />
        <el-step title="节点文件" />
        <el-step title="关系文件" />
      </el-steps>

      <el-form ref="createFormRef" :model="createForm" :rules="createRules" label-width="100px" class="create-form">
        <!-- 第 1 步：基本信息 -->
        <template v-if="createStep === 0">
          <el-form-item label="图谱名称" prop="name" required>
            <el-input v-model="createForm.name" placeholder="请输入图谱名称" maxlength="256" show-word-limit />
          </el-form-item>
          <el-form-item label="图谱描述" prop="description">
            <el-input v-model="createForm.description" type="textarea" placeholder="请输入图谱描述" :rows="2" />
          </el-form-item>
          <el-form-item label="图谱权限" prop="isPublic" required>
            <el-radio-group v-model="createForm.isPublic">
              <el-radio :value="0">私有</el-radio>
              <el-radio :value="1">公开</el-radio>
            </el-radio-group>
          </el-form-item>
        </template>

        <!-- 第 2 步：节点文件 -->
        <template v-if="createStep === 1">
        <el-form-item label="节点文件" required>
          <div class="file-row">
            <el-button type="primary" @click="triggerNodeFile">选择文件</el-button>
            <input ref="nodeFileInput" type="file" accept=".csv,.txt" class="file-hidden" @change="onNodeFileChange" />
            <el-tag v-if="createForm.nodeFile" type="success" closable class="file-tag" @close="createForm.nodeFile = null; nodePreview = []">
              {{ createForm.nodeFile?.name }}
            </el-tag>
          </div>
        </el-form-item>
        <el-form-item label="列分隔符" required>
          <el-radio-group v-model="createForm.nodeFileDelimiter" @change="parseNodePreview">
            <el-radio value=",">英文半角逗号</el-radio>
            <el-radio value="，">中文半角逗号</el-radio>
            <el-radio :value="'\t'">制表符</el-radio>
            <el-radio value=";">英文分号</el-radio>
            <el-radio value="；">中文分号</el-radio>
            <el-radio value=" ">空格</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="nodePreview.length > 0" label="文件预览">
          <div class="preview-table-wrap">
            <table class="preview-table">
              <thead>
                <tr>
                  <th v-for="(idx) in PREVIEW_COLS" :key="idx">
                    <el-select v-model="nodeColumnMapping[idx]" size="small" placeholder="选择列含义" @change="applyNodeMapping">
                      <el-option label="标签 (label)" value="label" />
                      <el-option label="文本 (text)" value="text" />
                      <el-option label="节点id (唯一标识)" value="nodeId" />
                    </el-select>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, ri) in nodePreview" :key="ri">
                  <td v-for="ci in PREVIEW_COLS" :key="ci">{{ row[ci] ?? '' }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </el-form-item>
        </template>

        <!-- 第 3 步：关系文件 -->
        <template v-if="createStep === 2">
        <el-form-item label="关系文件" required>
          <div class="file-row">
            <el-button type="primary" @click="triggerRelationFile">选择文件</el-button>
            <input ref="relationFileInput" type="file" accept=".csv,.txt" class="file-hidden" @change="onRelationFileChange" />
            <el-tag v-if="createForm.relationFile" type="success" closable class="file-tag" @close="createForm.relationFile = null; relationPreview = []">
              {{ createForm.relationFile?.name }}
            </el-tag>
          </div>
        </el-form-item>
        <el-form-item label="列分隔符" required>
          <el-radio-group v-model="createForm.relationFileDelimiter" @change="parseRelationPreview">
            <el-radio value=",">英文半角逗号</el-radio>
            <el-radio value="，">中文半角逗号</el-radio>
            <el-radio :value="'\t'">制表符</el-radio>
            <el-radio value=";">英文分号</el-radio>
            <el-radio value="；">中文分号</el-radio>
            <el-radio value=" ">空格</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="relationPreview.length > 0" label="文件预览">
          <div class="preview-table-wrap">
            <table class="preview-table">
              <thead>
                <tr>
                  <th v-for="(idx) in PREVIEW_COLS" :key="idx">
                    <el-select v-model="relationColumnMapping[idx]" size="small" placeholder="选择列含义" @change="applyRelationMapping">
                      <el-option label="前键节点id" value="startId" />
                      <el-option label="关系文本" value="relationText" />
                      <el-option label="后键节点id" value="endId" />
                    </el-select>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, ri) in relationPreview" :key="ri">
                  <td v-for="ci in PREVIEW_COLS" :key="ci">{{ row[ci] ?? '' }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </el-form-item>
        </template>
      </el-form>

      <template #footer>
        <el-button @click="resetCreateForm(); createVisible = false">重置</el-button>
        <el-button v-if="createStep > 0" @click="createStep--">上一步</el-button>
        <el-button v-if="createStep < 2" type="primary" @click="nextStep">下一步</el-button>
        <el-button v-if="createStep === 2" type="primary" :loading="createLoading" @click="submitCreate">创建</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed, markRaw } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowRight, Connection, Delete, Edit, Plus, Search, Upload, View } from '@element-plus/icons-vue'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { getMyGraphPage, createGraphWithFiles, deleteGraph, publishGraph } from '@/api/graph'
import type { Graph } from '@/api/graph'

const separatorIcon = markRaw(ArrowRight)
const DELIMITER_MAP: Record<string, string> = { ',': ',', '，': '，', '\t': '\t', ';': ';', '；': '；', ' ': ' ' }

function parseCsv(file: File, delimiter: string, maxRows = 10): string[][] {
  return new Promise((resolve) => {
    const reader = new FileReader()
    reader.onload = () => {
      const text = (reader.result as string) || ''
      const rows = text.split(/\r?\n/).filter(Boolean).slice(0, maxRows)
      const d = DELIMITER_MAP[delimiter] ?? delimiter
      resolve(rows.map((row) => row.split(d).map((c) => c.trim())))
    }
    reader.readAsText(file, 'UTF-8')
  })
}

const router = useRouter()
const loading = ref(false)
const list = ref<Graph[]>([])
const keyword = ref('')
const pagination = reactive({ current: 1, pageSize: 10, total: 0 })
const jumpPage = ref(1)
const maxPage = computed(() => Math.max(1, Math.ceil(pagination.total / pagination.pageSize)))

const load = async () => {
  loading.value = true
  try {
    const res = await getMyGraphPage({
      current: pagination.current,
      pageSize: pagination.pageSize,
      name: keyword.value || undefined,
    })
    list.value = (res.data?.records ?? []) as Graph[]
    pagination.total = res.data?.total ?? 0
    jumpPage.value = pagination.current
  } catch (e) {
    ElMessage.error('加载图谱列表失败')
  } finally {
    loading.value = false
  }
}

const goToPage = () => {
  const p = Math.min(maxPage.value, Math.max(1, Number(jumpPage.value) || 1))
  pagination.current = p
  jumpPage.value = p
  load()
}

const enterGraph = (row: Graph) => {
  router.push({ path: '/graph', query: { graphId: row.id } })
}

const handlePublish = async (row: Graph) => {
  try {
    await publishGraph(row.id)
    ElMessage.success('发布成功')
    load()
  } catch {
    ElMessage.error('发布失败')
  }
}

const handleDelete = async (row: Graph) => {
  try {
    await deleteGraph(row.id)
    ElMessage.success('删除成功')
    load()
  } catch {
    ElMessage.error('删除失败')
  }
}

// 创建图谱（三步：0 基本信息 1 节点文件 2 关系文件）
const createStep = ref(0)
const createVisible = ref(false)
const createLoading = ref(false)
const createFormRef = ref<FormInstance>()
const nodeFileInput = ref<HTMLInputElement>()
const relationFileInput = ref<HTMLInputElement>()
const nodePreview = ref<string[][]>([])
const relationPreview = ref<string[][]>([])
const nodeColumnMapping = ref<string[]>(['label', 'text', 'nodeId'])
const relationColumnMapping = ref<string[]>(['startId', 'relationText', 'endId'])

const PREVIEW_COLS = [0, 1, 2]

const createForm = reactive({
  name: '',
  description: '',
  isPublic: 0 as number,
  nodeFile: null as File | null,
  relationFile: null as File | null,
  nodeFileDelimiter: ',',
  relationFileDelimiter: ',',
  nodeIdColumnIndex: 0,
  nodeLabelColumnIndex: 1,
  nodeTextColumnIndex: 2,
  startIdColumnIndex: 0,
  endIdColumnIndex: 1,
  relationColumnIndex: 2,
})
const createRules: FormRules = {
  name: [{ required: true, message: '请输入图谱名称', trigger: 'blur' }],
}

function triggerNodeFile() {
  nodeFileInput.value?.click()
}
function triggerRelationFile() {
  relationFileInput.value?.click()
}

async function onNodeFileChange(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  createForm.nodeFile = file
  await parseNodePreview()
  input.value = ''
}

async function onRelationFileChange(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  createForm.relationFile = file
  await parseRelationPreview()
  input.value = ''
}

async function parseNodePreview() {
  if (!createForm.nodeFile) {
    nodePreview.value = []
    return
  }
  const rows = await parseCsv(createForm.nodeFile, createForm.nodeFileDelimiter)
  nodePreview.value = rows
  nodeColumnMapping.value = ['label', 'text', 'nodeId']
  applyNodeMapping()
}

async function parseRelationPreview() {
  if (!createForm.relationFile) {
    relationPreview.value = []
    return
  }
  const rows = await parseCsv(createForm.relationFile, createForm.relationFileDelimiter)
  relationPreview.value = rows
  relationColumnMapping.value = ['startId', 'relationText', 'endId']
  applyRelationMapping()
}

function applyNodeMapping() {
  const m = nodeColumnMapping.value
  const idx = (v: string) => m.indexOf(v)
  createForm.nodeIdColumnIndex = idx('nodeId') >= 0 ? idx('nodeId') : 0
  createForm.nodeLabelColumnIndex = idx('label') >= 0 ? idx('label') : 1
  createForm.nodeTextColumnIndex = idx('text') >= 0 ? idx('text') : 2
}

function applyRelationMapping() {
  const m = relationColumnMapping.value
  const idx = (v: string) => m.indexOf(v)
  createForm.startIdColumnIndex = idx('startId') >= 0 ? idx('startId') : 0
  createForm.relationColumnIndex = idx('relationText') >= 0 ? idx('relationText') : 1
  createForm.endIdColumnIndex = idx('endId') >= 0 ? idx('endId') : 2
}

const openCreateDialog = () => {
  createStep.value = 0
  createVisible.value = true
}

const nextStep = async () => {
  if (createStep.value === 0) {
    try {
      await createFormRef.value?.validate()
    } catch {
      return
    }
    createStep.value = 1
    return
  }
  if (createStep.value === 1) {
    if (!createForm.nodeFile) {
      ElMessage.warning('请选择节点文件')
      return
    }
    createStep.value = 2
  }
}

const resetCreateForm = () => {
  createStep.value = 0
  createForm.name = ''
  createForm.description = ''
  createForm.isPublic = 0
  createForm.nodeFile = null
  createForm.relationFile = null
  createForm.nodeFileDelimiter = ','
  createForm.relationFileDelimiter = ','
  nodeColumnMapping.value = ['label', 'text', 'nodeId']
  relationColumnMapping.value = ['startId', 'relationText', 'endId']
  nodePreview.value = []
  relationPreview.value = []
  applyNodeMapping()
  applyRelationMapping()
  createFormRef.value?.resetFields()
}

const submitCreate = async () => {
  if (!createForm.nodeFile || !createForm.relationFile) {
    ElMessage.warning('请上传节点文件和关系文件')
    return
  }
  await createFormRef.value?.validate().catch(() => {})
  createLoading.value = true
  try {
    const formData = new FormData()
    formData.append('name', createForm.name)
    if (createForm.description) formData.append('description', createForm.description)
    formData.append('isPublic', createForm.isPublic === 1 ? 'YES' : 'NO')
    formData.append('nodeFile', createForm.nodeFile)
    formData.append('relationFile', createForm.relationFile)
    formData.append('nodeFileDelimiter', createForm.nodeFileDelimiter)
    formData.append('relationFileDelimiter', createForm.relationFileDelimiter)
    formData.append('nodeIdColumnIndex', String(createForm.nodeIdColumnIndex))
    formData.append('nodeLabelColumnIndex', String(createForm.nodeLabelColumnIndex))
    formData.append('nodeTextColumnIndex', String(createForm.nodeTextColumnIndex))
    formData.append('startIdColumnIndex', String(createForm.startIdColumnIndex))
    formData.append('endIdColumnIndex', String(createForm.endIdColumnIndex))
    formData.append('relationColumnIndex', String(createForm.relationColumnIndex))

    const res = await createGraphWithFiles(formData)
    const id = res.data
    createVisible.value = false
    ElMessage.success('图谱已创建，正在导入数据…')
    load()
    if (id) {
      router.push({ path: '/graph', query: { graphId: id } })
    }
  } catch (e: any) {
    ElMessage.error(e?.message || e?.data?.message || '创建失败')
  } finally {
    createLoading.value = false
  }
}

onMounted(() => load())
</script>

<style lang="scss" scoped>
.graph-list-page {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-height: calc(100vh - 60px);
}

/* 顶部导航区域：与数据集管理一致 */
.header-area {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 30px;
  background: linear-gradient(to right, #d32f2f, #d32f2f);
  border-radius: 8px;
  color: white;
  margin: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.tech-title {
  font-size: 24px;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 10px;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
  color: #ffffff !important;
}

:deep(.tech-title span),
:deep(.tech-title div),
:deep(.tech-title a) {
  color: #ffffff !important;
}

.tech-title .el-icon {
  font-size: 28px;
  color: #ffffff;
}

.graph-metrics {
  display: flex;
  gap: 20px;
}

/* 统计卡片：与数据集管理「数据集总数」一致，半透明白底、白字 */
.metric-card {
  background: rgba(255, 255, 255, 0.18);
  border-radius: 8px;
  padding: 10px 20px;
  text-align: center;
  backdrop-filter: blur(10px);
  transition: all 0.3s;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.12);
}

.metric-card:hover {
  transform: translateY(-3px);
  background: rgba(255, 255, 255, 0.2);
}

.metric-value {
  font-size: 26px;
  font-weight: 600;
}

.metric-label {
  font-size: 14px;
  opacity: 0.8;
}

/* 内容面板 */
.content-panel {
  background-color: white;
  margin: 0 20px 20px;
  border-radius: 8px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.05);
  padding: 20px;
  min-height: calc(100vh - 210px);
}

/* 搜索区域：与数据集管理一致，灰底渐变 */
.search-container {
  padding: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(to right, #f6f8fa, #e9ecef);
  border-radius: 8px;
  margin-bottom: 25px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.03);
}

.right-area {
  display: flex;
  gap: 15px;
  align-items: center;
}

.tech-input {
  width: 360px;
  border-radius: 6px;
  transition: all 0.3s;
}

.tech-input:focus-within {
  box-shadow: 0 0 0 2px rgba(24, 144, 255, 0.2);
  transform: translateY(-1px);
}

.create-btn,
.search-btn {
  background: linear-gradient(to right, #a82525, #d32f2f);
  border: none;
  border-radius: 6px;
  transition: all 0.3s;
}

.create-btn:hover,
.search-btn:hover {
  background: linear-gradient(to right, #d32f2f, #a82525);
  transform: translateY(-1px);
  box-shadow: 0 5px 15px rgba(168, 37, 37, 0.2);
}

.table-container {
  margin: 0;
  border-radius: 8px;
  overflow: hidden;
}

:deep(.el-table__row) {
  transition: all 0.2s;
}

:deep(.el-table__row:hover) {
  background-color: #f0f8ff !important;
  transform: translateY(-2px);
  box-shadow: 0 5px 10px rgba(0, 0, 0, 0.03);
}

:deep(.el-button.is-link) {
  color: #a82525;
}

.table-container .pagination-wrap {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 16px;
  flex-wrap: wrap;
  .total-text {
    color: #606266;
    font-size: 14px;
  }
  .pager {
    margin: 0;
  }
  .jump-text {
    font-size: 14px;
    color: #606266;
  }
  .jump-input {
    width: 56px;
    margin: 0 4px;
  }
  .page-size-select {
    width: 100px;
  }
}

.file-hidden {
  position: absolute;
  width: 0;
  height: 0;
  opacity: 0;
}
.file-row {
  display: flex;
  align-items: center;
  gap: 12px;
  .file-tag {
    max-width: 280px;
    overflow: hidden;
    text-overflow: ellipsis;
  }
}
.preview-table-wrap {
  border: 1px solid #dcdfe6;
  border-radius: 6px;
  overflow: hidden;
  max-height: 240px;
  overflow-y: auto;
}
.preview-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  th, td {
    border: 1px solid #ebeef5;
    padding: 8px 10px;
    text-align: left;
  }
  thead th {
    background: #f5f7fa;
    min-width: 120px;
  }
  tbody tr:nth-child(even) {
    background: #fafafa;
  }
}
.create-steps {
  margin-bottom: 24px;
}
.create-form {
  :deep(.el-form-item) {
    margin-bottom: 24px;
  }
  :deep(.el-form-item__label) {
    .el-form-item.is-required:not(.is-no-asterisk) .el-form-item__label::before {
      content: '*';
      color: var(--el-color-danger);
    }
  }
}
</style>
