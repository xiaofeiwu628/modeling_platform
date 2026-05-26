<template>
  <div class="annotation-page">
    <div class="header-area">
      <div class="title-block">
        <el-icon><EditPen /></el-icon>
        <div>
          <h2>数据标注</h2>
          <p>上传 CSV 或 JSON 文件，完成标签编辑后复用数据集服务保存入库</p>
        </div>
      </div>
      <div class="data-metrics">
        <div class="metric-card">
          <div class="metric-value">{{ rows.length }}</div>
          <div class="metric-label">数据项</div>
        </div>
        <div class="metric-card">
          <div class="metric-value">{{ labelStats.length }}</div>
          <div class="metric-label">标签数</div>
        </div>
        <div class="metric-card">
          <div class="metric-value">{{ labeledCount }}</div>
          <div class="metric-label">已标注</div>
        </div>
      </div>
    </div>

    <div class="content-panel">
      <div class="workspace-grid">
        <section class="control-panel">
          <div class="panel-title">
            <el-icon><Upload /></el-icon>
            <span>文件与入库配置</span>
          </div>

          <el-upload
            drag
            :auto-upload="false"
            :limit="1"
            accept=".csv,.json,application/json,text/csv"
            :on-change="handleFileChange"
            :on-remove="resetFile"
            class="upload-box"
          >
            <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
            <div class="el-upload__text">拖拽文件到此处，或点击选择</div>
            <template #tip>
              <div class="upload-tip">支持 CSV / JSON，本地解析后再保存到后端</div>
            </template>
          </el-upload>

          <el-form label-position="top" class="save-form">
            <el-form-item label="目标数据集">
              <div class="dataset-row">
                <el-select
                  v-model="saveForm.setId"
                  filterable
                  placeholder="请选择数据集"
                  class="dataset-select"
                  :loading="datasetLoading"
                >
                  <el-option
                    v-for="item in datasetOptions"
                    :key="item.set_id"
                    :label="`${item.set_name}（ID:${item.set_id}）`"
                    :value="item.set_id"
                  />
                </el-select>
                <el-button :icon="Refresh" @click="loadDatasets" />
              </div>
            </el-form-item>

            <el-form-item label="保存表名">
              <el-input v-model="saveForm.tableName" placeholder="例如：标注结果表" />
            </el-form-item>

            <el-form-item label="描述">
              <el-input
                v-model="saveForm.tableDesc"
                type="textarea"
                :rows="3"
                placeholder="记录标注任务说明"
              />
            </el-form-item>

            <el-form-item label="批量标签">
              <div class="batch-row">
                <el-input v-model="batchLabel" placeholder="输入标签名" clearable />
                <el-button type="primary" @click="applyBatchLabel">应用到筛选结果</el-button>
              </div>
            </el-form-item>
          </el-form>

          <div class="label-panel">
            <div class="sub-title">标签统计</div>
            <el-empty v-if="labelStats.length === 0" description="暂无标签" :image-size="70" />
            <div v-else class="tag-list">
              <el-tag
                v-for="item in labelStats"
                :key="item.label"
                effect="light"
                class="stat-tag"
              >
                {{ item.label }} · {{ item.count }}
              </el-tag>
            </div>
          </div>
        </section>

        <section class="table-panel">
          <div class="toolbar">
            <div class="table-title">
              <el-icon><Grid /></el-icon>
              <span>标注工作台</span>
            </div>
            <div class="toolbar-actions">
              <el-input
                v-model="keyword"
                placeholder="搜索内容或标签"
                clearable
                class="search-input"
              >
                <template #prefix>
                  <el-icon><Search /></el-icon>
                </template>
              </el-input>
              <el-button :icon="Download" @click="downloadAnnotatedFile" :disabled="rows.length === 0">
                导出
              </el-button>
              <el-button
                type="primary"
                :icon="Finished"
                :loading="saving"
                :disabled="rows.length === 0"
                @click="saveAnnotatedFile"
              >
                保存入库
              </el-button>
            </div>
          </div>

          <el-alert
            v-if="activeFile"
            type="info"
            :closable="false"
            class="file-alert"
            show-icon
          >
            <template #title>
              当前文件：{{ activeFile.name }}，类型：{{ fileKindText }}
            </template>
          </el-alert>

          <el-empty v-if="rows.length === 0" description="请先上传待标注文件" />

          <el-table
            v-else
            :data="pagedRows"
            border
            stripe
            class="annotation-table"
            :header-cell-style="{ background: '#a82525', color: '#fff', textAlign: 'center' }"
            :cell-style="{ textAlign: 'center' }"
            height="560"
          >
            <el-table-column prop="index" label="序号" width="80" fixed="left" />
            <el-table-column label="标注标签" width="220" fixed="left">
              <template #default="{ row }">
                <el-select
                  v-model="row.label"
                  filterable
                  allow-create
                  default-first-option
                  clearable
                  placeholder="选择或输入标签"
                  @change="markDirty"
                >
                  <el-option
                    v-for="item in labelOptions"
                    :key="item"
                    :label="item"
                    :value="item"
                  />
                </el-select>
              </template>
            </el-table-column>

            <el-table-column
              v-if="fileKind === 'json'"
              prop="content"
              label="文本内容"
              min-width="420"
              show-overflow-tooltip
            />

            <el-table-column
              v-for="column in visibleCsvColumns"
              v-else
              :key="column"
              :label="column"
              min-width="180"
              show-overflow-tooltip
            >
              <template #default="{ row }">
                {{ row.values[column] }}
              </template>
            </el-table-column>

            <el-table-column label="操作" width="160" fixed="right">
              <template #default="{ row }">
                <el-button link type="primary" @click="openEditDialog(row)">
                  <el-icon><Edit /></el-icon>
                  编辑
                </el-button>
                <el-button link type="danger" @click="clearLabel(row)">
                  清除标签
                </el-button>
              </template>
            </el-table-column>
          </el-table>

          <div v-if="rows.length > 0" class="pagination-row">
            <span>共 {{ filteredRows.length }} 条</span>
            <el-pagination
              v-model:current-page="currentPage"
              v-model:page-size="pageSize"
              :page-sizes="[10, 20, 50, 100]"
              layout="sizes, prev, pager, next"
              :total="filteredRows.length"
            />
          </div>
        </section>
      </div>
    </div>

    <el-dialog v-model="editVisible" title="编辑数据项" width="720px" destroy-on-close>
      <el-form v-if="editingRow" label-position="top">
        <el-form-item label="标注标签">
          <el-select
            v-model="editingRow.label"
            filterable
            allow-create
            default-first-option
            clearable
            placeholder="选择或输入标签"
            class="full-width"
          >
            <el-option
              v-for="item in labelOptions"
              :key="item"
              :label="item"
              :value="item"
            />
          </el-select>
        </el-form-item>

        <template v-if="fileKind === 'json'">
          <el-form-item label="文本内容">
            <el-input v-model="editingRow.content" type="textarea" :rows="8" />
          </el-form-item>
        </template>

        <template v-else>
          <el-form-item
            v-for="column in csvColumns"
            :key="column"
            :label="column"
          >
            <el-input v-model="editingRow.values[column]" />
          </el-form-item>
        </template>
      </el-form>
      <template #footer>
        <el-button @click="editVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmEdit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script lang="ts" setup>
import { computed, onMounted, reactive, ref, watch } from "vue";
import { ElMessage, type UploadFile } from "element-plus";
import {
  Download,
  Edit,
  EditPen,
  Finished,
  Grid,
  Refresh,
  Search,
  Upload,
  UploadFilled,
} from "@element-plus/icons-vue";
import { dataset, file } from "@/api/data";
import type { DataSetInfo } from "@/api/types";

type FileKind = "csv" | "json" | "";

interface AnnotationRow {
  index: number;
  label: string;
  content: string;
  values: Record<string, string>;
  source: unknown;
}

const activeFile = ref<File | null>(null);
const fileKind = ref<FileKind>("");
const csvColumns = ref<string[]>([]);
const rows = ref<AnnotationRow[]>([]);
const datasetOptions = ref<DataSetInfo[]>([]);
const datasetLoading = ref(false);
const saving = ref(false);
const keyword = ref("");
const batchLabel = ref("");
const currentPage = ref(1);
const pageSize = ref(20);
const editVisible = ref(false);
const editingRow = ref<AnnotationRow | null>(null);

const saveForm = reactive({
  setId: undefined as number | undefined,
  tableName: "",
  tableDesc: "",
});

const fileKindText = computed(() => {
  if (fileKind.value === "csv") return "CSV 表格";
  if (fileKind.value === "json") return "JSON 文本";
  return "未识别";
});

const visibleCsvColumns = computed(() => csvColumns.value.slice(0, 8));

const labeledCount = computed(() => rows.value.filter((item) => item.label.trim()).length);

const labelStats = computed(() => {
  const stat = new Map<string, number>();
  rows.value.forEach((row) => {
    const label = row.label.trim();
    if (!label) return;
    stat.set(label, (stat.get(label) || 0) + 1);
  });
  return Array.from(stat.entries())
    .map(([label, count]) => ({ label, count }))
    .sort((a, b) => b.count - a.count);
});

const labelOptions = computed(() => labelStats.value.map((item) => item.label));

const filteredRows = computed(() => {
  const word = keyword.value.trim().toLowerCase();
  if (!word) return rows.value;
  return rows.value.filter((row) => {
    const valueText = fileKind.value === "csv"
      ? Object.values(row.values).join(" ")
      : row.content;
    return `${row.label} ${valueText}`.toLowerCase().includes(word);
  });
});

const pagedRows = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value;
  return filteredRows.value.slice(start, start + pageSize.value);
});

watch([keyword, pageSize], () => {
  currentPage.value = 1;
});

onMounted(() => {
  loadDatasets();
});

async function loadDatasets() {
  datasetLoading.value = true;
  try {
    const res = await dataset.getAll();
    if (res.code === "0") {
      datasetOptions.value = res.data || [];
      if (!saveForm.setId && datasetOptions.value.length > 0) {
        saveForm.setId = datasetOptions.value[0].set_id;
      }
    } else {
      ElMessage.error(res.msg || "数据集加载失败");
    }
  } catch {
    ElMessage.error("数据集加载失败，请检查后端服务");
  } finally {
    datasetLoading.value = false;
  }
}

async function handleFileChange(uploadFile: UploadFile) {
  const rawFile = uploadFile.raw;
  if (!rawFile) return;
  const ext = rawFile.name.split(".").pop()?.toLowerCase();
  if (ext !== "csv" && ext !== "json") {
    ElMessage.error("仅支持 CSV 或 JSON 文件");
    return;
  }

  try {
    const text = await rawFile.text();
    activeFile.value = rawFile;
    fileKind.value = ext;
    if (ext === "csv") {
      parseCsvFile(text);
    } else {
      parseJsonFile(text);
    }
    saveForm.tableName = buildDefaultTableName(rawFile.name);
    saveForm.tableDesc = `数据标注结果：${rawFile.name}`;
    ElMessage.success("文件解析成功");
  } catch (error) {
    resetFile();
    ElMessage.error(error instanceof Error ? error.message : "文件解析失败");
  }
}

function resetFile() {
  activeFile.value = null;
  fileKind.value = "";
  csvColumns.value = [];
  rows.value = [];
  keyword.value = "";
  batchLabel.value = "";
  currentPage.value = 1;
}

function parseCsvFile(text: string) {
  const matrix = parseCsv(text);
  if (matrix.length < 2) {
    throw new Error("CSV 至少需要包含表头和一行数据");
  }
  const headers = matrix[0].map((item, index) => item.trim() || `字段${index + 1}`);
  csvColumns.value = headers;
  rows.value = matrix.slice(1)
    .filter((line) => line.some((cell) => cell.trim() !== ""))
    .map((line, rowIndex) => {
      const values: Record<string, string> = {};
      headers.forEach((header, colIndex) => {
        values[header] = line[colIndex] ?? "";
      });
      const existingLabel = values.annotation_label || values.label || "";
      return {
        index: rowIndex + 1,
        label: existingLabel,
        content: Object.values(values).join(" "),
        values,
        source: values,
      };
    });
}

function parseJsonFile(text: string) {
  const parsed = JSON.parse(text) as unknown;
  const items = Array.isArray(parsed) ? parsed : [parsed];
  rows.value = items.map((item, index) => {
    const objectValue = isRecord(item) ? item : { value: item };
    const label = readStringField(objectValue, ["annotation_label", "label", "tag", "category"]);
    const content = readStringField(objectValue, ["text", "content", "sentence", "value", "name"]) ||
      JSON.stringify(item, null, 2);
    return {
      index: index + 1,
      label,
      content,
      values: {},
      source: objectValue,
    };
  });
  csvColumns.value = [];
}

function parseCsv(text: string): string[][] {
  const rowsResult: string[][] = [];
  let row: string[] = [];
  let cell = "";
  let quoted = false;

  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    const next = text[i + 1];
    if (char === '"') {
      if (quoted && next === '"') {
        cell += '"';
        i += 1;
      } else {
        quoted = !quoted;
      }
    } else if (char === "," && !quoted) {
      row.push(cell);
      cell = "";
    } else if ((char === "\n" || char === "\r") && !quoted) {
      if (char === "\r" && next === "\n") i += 1;
      row.push(cell);
      rowsResult.push(row);
      row = [];
      cell = "";
    } else {
      cell += char;
    }
  }

  if (cell.length > 0 || row.length > 0) {
    row.push(cell);
    rowsResult.push(row);
  }
  return rowsResult;
}

function readStringField(source: Record<string, unknown>, keys: string[]) {
  for (const key of keys) {
    const value = source[key];
    if (value !== undefined && value !== null) return String(value);
  }
  return "";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function buildDefaultTableName(fileName: string) {
  const baseName = fileName.replace(/\.[^/.]+$/, "");
  return `${baseName}_标注结果`;
}

function markDirty() {
  // Keep computed label statistics reactive when tags are edited inline.
}

function applyBatchLabel() {
  const label = batchLabel.value.trim();
  if (!label) {
    ElMessage.warning("请输入批量标签");
    return;
  }
  filteredRows.value.forEach((row) => {
    row.label = label;
  });
  ElMessage.success(`已为 ${filteredRows.value.length} 条数据设置标签`);
}

function clearLabel(row: AnnotationRow) {
  row.label = "";
}

function openEditDialog(row: AnnotationRow) {
  editingRow.value = row;
  editVisible.value = true;
}

function confirmEdit() {
  editVisible.value = false;
  ElMessage.success("已更新当前数据项");
}

function validateBeforeSave() {
  if (!activeFile.value || !fileKind.value || rows.value.length === 0) {
    ElMessage.warning("请先上传并解析文件");
    return false;
  }
  if (!saveForm.setId) {
    ElMessage.warning("请选择目标数据集");
    return false;
  }
  if (!saveForm.tableName.trim()) {
    ElMessage.warning("请输入保存表名");
    return false;
  }
  return true;
}

async function saveAnnotatedFile() {
  if (!validateBeforeSave()) return;
  saving.value = true;
  try {
    const annotatedFile = buildAnnotatedFile();
    if (fileKind.value === "csv") {
      const headers = buildCsvHeaders();
      const dataType = headers.map(() => "String").join(",");
      const columnsSave = headers.map(() => "1").join(",");
      const res = await file.upload({
        SetId: saveForm.setId,
        File: annotatedFile,
        TableName: saveForm.tableName,
        TableDesc: saveForm.tableDesc,
        DataType: dataType,
        HasHeader: true,
        TableHead: headers.join(","),
        ColumnsSave: columnsSave,
        ColumnsSeparator: "__comma",
        EncodingMethod: "UTF-8",
      });
      if (res.code !== "0") throw new Error(res.msg || "CSV 保存失败");
      ElMessage.success(res.msg || "标注数据已保存入库");
    } else {
      const preview = await file.getTagList({
        file: annotatedFile,
        setId: saveForm.setId,
        tableName: saveForm.tableName,
        tableDesc: saveForm.tableDesc,
        encodingMethod: "UTF-8",
      });
      if (preview.code !== "0") throw new Error(preview.msg || "JSON 标签预处理失败");
      const res = await file.saveJson({
        tempTableName: preview.data.tempTableName,
        file: annotatedFile,
      });
      if (res.code !== "0") throw new Error(res.msg || "JSON 保存失败");
      ElMessage.success(res.msg || "标注 JSON 已保存入库");
    }
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : "保存失败");
  } finally {
    saving.value = false;
  }
}

function buildAnnotatedFile() {
  if (!activeFile.value) throw new Error("文件不存在");
  if (fileKind.value === "csv") {
    const content = buildCsvContent();
    return new File([content], buildAnnotatedFileName("csv"), { type: "text/csv;charset=utf-8" });
  }
  const content = JSON.stringify(buildJsonContent(), null, 2);
  return new File([content], buildAnnotatedFileName("json"), { type: "application/json;charset=utf-8" });
}

function buildAnnotatedFileName(ext: string) {
  const baseName = activeFile.value?.name.replace(/\.[^/.]+$/, "") || "annotation";
  return `${baseName}_annotated.${ext}`;
}

function buildCsvHeaders() {
  const hasLabelColumn = csvColumns.value.includes("annotation_label");
  return hasLabelColumn ? csvColumns.value : [...csvColumns.value, "annotation_label"];
}

function buildCsvContent() {
  const headers = buildCsvHeaders();
  const lines = [
    headers.map(escapeCsvCell).join(","),
    ...rows.value.map((row) => headers.map((header) => {
      if (header === "annotation_label") return escapeCsvCell(row.label);
      return escapeCsvCell(row.values[header] ?? "");
    }).join(",")),
  ];
  return lines.join("\r\n");
}

function escapeCsvCell(value: string) {
  if (/[",\r\n]/.test(value)) {
    return `"${value.replace(/"/g, '""')}"`;
  }
  return value;
}

function buildJsonContent() {
  return rows.value.map((row) => {
    const source: Record<string, unknown> = isRecord(row.source) ? { ...row.source } : { value: row.source };
    source.annotation_label = row.label;
    source.content = row.content;
    return source;
  });
}

function downloadAnnotatedFile() {
  if (rows.value.length === 0) return;
  const annotatedFile = buildAnnotatedFile();
  const url = URL.createObjectURL(annotatedFile);
  const link = document.createElement("a");
  link.href = url;
  link.download = annotatedFile.name;
  link.click();
  URL.revokeObjectURL(url);
}
</script>

<style scoped>
.annotation-page {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

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

.title-block {
  display: flex;
  align-items: center;
  gap: 14px;
}

.title-block .el-icon {
  font-size: 30px;
}

.title-block h2 {
  margin: 0;
  font-size: 24px;
  font-weight: 700;
}

.title-block p {
  margin: 6px 0 0;
  font-size: 14px;
  opacity: 0.85;
}

.data-metrics {
  display: flex;
  gap: 20px;
}

.metric-card {
  min-width: 92px;
  background: rgba(255, 255, 255, 0.18);
  border-radius: 4px;
  padding: 10px 20px;
  text-align: center;
  backdrop-filter: blur(10px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.12);
}

.metric-value {
  font-size: 26px;
  font-weight: 600;
}

.metric-label {
  font-size: 14px;
  opacity: 0.85;
}

.content-panel {
  background-color: white;
  margin: 0 20px 20px;
  border-radius: 4px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.05);
  padding: 20px;
  min-height: calc(100vh - 210px);
}

.workspace-grid {
  display: grid;
  grid-template-columns: 320px minmax(0, 1fr);
  gap: 20px;
}

.control-panel,
.table-panel {
  border: 1px solid #ebeef5;
  border-radius: 4px;
  padding: 18px;
  background: #fff;
}

.panel-title,
.table-title {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #a82525;
  font-size: 18px;
  font-weight: 600;
}

.upload-box {
  margin-top: 18px;
}

.upload-tip {
  color: var(--el-color-info);
  font-size: 12px;
  margin-top: 6px;
}

.save-form {
  margin-top: 20px;
}

.dataset-row,
.batch-row {
  display: flex;
  gap: 10px;
  width: 100%;
}

.dataset-select {
  flex: 1;
}

.label-panel {
  margin-top: 22px;
  padding-top: 18px;
  border-top: 1px solid #ebeef5;
}

.sub-title {
  margin-bottom: 12px;
  color: #606266;
  font-weight: 600;
}

.tag-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.stat-tag {
  max-width: 100%;
}

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  margin-bottom: 16px;
}

.toolbar-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.search-input {
  width: 260px;
}

.file-alert {
  margin-bottom: 14px;
}

.annotation-table {
  width: 100%;
  border-radius: 4px;
}

.pagination-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 16px;
  color: #606266;
}

.full-width {
  width: 100%;
}

:deep(.el-upload-dragger) {
  padding: 24px 12px;
}

:deep(.el-button.is-link) {
  color: #a82525;
}

@media (max-width: 1180px) {
  .workspace-grid {
    grid-template-columns: 1fr;
  }

  .header-area,
  .toolbar {
    align-items: flex-start;
    flex-direction: column;
  }

  .toolbar-actions {
    width: 100%;
    flex-wrap: wrap;
  }

  .search-input {
    width: 100%;
  }
}
</style>
