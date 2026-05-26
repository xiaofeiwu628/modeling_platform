<template>
  <div class="service-details-container">
    <!-- 头部区域 -->
    <div class="header-area">
      <div class="tech-title">
        <el-icon><Document /></el-icon>
        <el-breadcrumb :separator-icon="ArrowRight" class="nav-breadcrumb">
          <el-breadcrumb-item :to="{ path: '/onlineServiceList' }" class="tech-breadcrumb">
            在线服务
          </el-breadcrumb-item>
          <el-breadcrumb-item class="tech-breadcrumb">
            服务详情
          </el-breadcrumb-item>
        </el-breadcrumb>
      </div>
    </div>

    <!-- 主内容区域 -->
    <div class="main-content-wrapper">
      <!-- 基本信息 -->
      <div class="info-section">
        <div class="section-header">
          <div class="section-line"></div>
          <span class="section-title">基本信息</span>
        </div>
        <div class="section-content">
          <el-descriptions
            class="info-descriptions"
            :column="2"
            border
          >
            <el-descriptions-item label="服务名称">
              <span class="info-value text-bold">{{ formOfBaseInformation.serviceName || '-' }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="服务ID">
              <span class="info-value code-font">{{ formOfBaseInformation.serviceId || '-' }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="服务状态">
              <el-tag :type="getServiceStateType" size="default" class="status-tag">
                {{ serviceStateDic[formOfBaseInformation.serviceState] || '未知' }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="部署方式">
              <el-tag type="info" size="default" class="type-tag">
                {{ serviceTypeDic[formOfBaseInformation.serviceType] || '-' }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="创建时间" :span="2">
              <span class="info-value">{{ formOfBaseInformation.createTime || '-' }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="服务描述" :span="2">
              <span class="info-value desc-text">{{ formOfBaseInformation.desc || '暂无描述信息' }}</span>
            </el-descriptions-item>
          </el-descriptions>
        </div>
      </div>
      
      <!-- 模型信息 -->
      <div v-if="formOfBaseInformation.serviceType === 'official'" class="info-section">
        <div class="section-header">
          <div class="section-line"></div>
          <span class="section-title">模型信息</span>
        </div>
        <div class="section-content">
          <el-table 
            :data="modelInformationTableData" 
            class="info-table" 
            border 
            :header-cell-style="tableHeaderStyle"
            :cell-style="tableCellStyle"
            stripe
          >
            <el-table-column prop="modelName" label="模型名称" min-width="20%" align="center"/>
            <el-table-column prop="modelId" label="模型ID" min-width="20%" align="center"/>
            <el-table-column prop="taskId" label="所属任务ID" min-width="20%" align="center"/>
            <el-table-column prop="taskHistoryId" label="任务运行ID" min-width="20%" align="center"/>
            <el-table-column prop="isPublic" label="是否公开" min-width="20%" align="center">
              <template #default="scope">
                <el-tag :type="scope.row.isPublic === '公开' ? 'success' : 'info'" size="small">
                  {{ scope.row.isPublic }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </div>

      <!-- 镜像信息 -->
      <div v-if="formOfBaseInformation.serviceType === 'custom'" class="info-section">
        <div class="section-header">
          <div class="section-line"></div>
          <span class="section-title">镜像信息</span>
        </div>
        <div class="section-content">
          <el-table 
            :data="imageInformationTableData" 
            class="info-table" 
            border 
            :header-cell-style="tableHeaderStyle"
            :cell-style="tableCellStyle"
            stripe
          >
            <el-table-column prop="imageName" label="镜像名称" min-width="25%" align="center"/>
            <el-table-column prop="imageId" label="镜像ID" min-width="25%" align="center"/>
            <el-table-column prop="imageVersionId" label="镜像版本ID" min-width="25%" align="center"/>
            <el-table-column prop="tag" label="版本号" min-width="25%" align="center">
              <template #default="scope">
                <el-tag type="primary" size="small">v{{ scope.row.tag }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </div>

      <!-- 资源规格 -->
      <div class="info-section">
        <div class="section-header">
          <div class="section-line"></div>
          <span class="section-title">资源规格</span>
        </div>
        <div class="section-content">
          <el-row :gutter="40" class="resource-info">
            <el-col :span="12">
              <div class="resource-card">
                <div class="resource-icon">
                  <el-icon size="24"><Cpu /></el-icon>
                </div>
                <div class="resource-data">
                  <div class="resource-value">{{ formOfResource.cpuCoresNum }}</div>
                  <div class="resource-label">CPU核心数</div>
                </div>
              </div>
            </el-col>
            <el-col :span="12">
              <div class="resource-card">
                <div class="resource-icon memory-icon">
                  <el-icon size="24"><Memo /></el-icon>
                </div>
                <div class="resource-data">
                  <div class="resource-value">{{ formOfResource.memory }}</div>
                  <div class="resource-label">内存</div>
                </div>
              </div>
            </el-col>
          </el-row>
        </div>
      </div>

      <!-- 请求说明 -->
      <div class="info-section">
        <div class="section-header">
          <div class="section-line"></div>
          <span class="section-title">请求说明</span>
        </div>
        <div class="section-content">
          <el-form
            label-position="left"
            label-width="120px"
            :model="formOfRequestDesc"
            class="request-form"
          >
            <el-form-item label="HTTP方法">
              <el-tag type="success" size="small">POST</el-tag>
            </el-form-item>
            
            <el-form-item label="请求URL">
              <div class="url-container">
                <div class="url-value">{{ formOfRequestDesc.url }}</div>
                <div class="url-note" v-if="formOfBaseInformation.serviceType === 'custom'">
                  注：您可以根据需要在上述URL基础上进行延伸，如：{{ formOfRequestDesc.url }}/example
                </div>
                <!-- 接口调用说明 -->
                <div class="url-instruction">
                  <div class="instruction-title">
                    <el-icon><InfoFilled /></el-icon>
                    <span>外部脚本/软件调用说明</span>
                  </div>
                  <div class="instruction-content">
                    <p>若您需要使用 Python、cURL 或 Postman 等外部工具进行批量/自动化请求，请参考以下配置：</p>
                    <ul class="instruction-list">
                      <li><strong>接口地址：</strong>可以直接调用上方显示的完整 URL。如果进行私有化部署或在不同服务器网络环境下，请确保该 URL 可达。如有需要，可将域名/IP及端口替换为实际部署的网关地址。</li>
                      <li><strong>请求方法：</strong><code>POST</code></li>
                      <li><strong>请求头 (Headers)：</strong>
                        <div class="mini-table">
                          <div class="mini-row">
                            <span class="key">Content-Type</span>
                            <span class="val">application/json</span>
                          </div>
                          <div class="mini-row">
                            <span class="key">Token</span>
                            <span class="val">您的身份认证令牌 (如：{{ headerTableData[0]?.value || '获取失败，请先登录' }})</span>
                          </div>
                        </div>
                      </li>
                      <li><strong>数据格式：</strong>请求体请使用 JSON 格式，参数与下方 “Body请求体” 及 “请求示例” 保持一致。</li>
                      <li><strong>批量请求建议：</strong>在大批量请求时，建议使用连接池以维持 HTTP 长连接 (Keep-Alive)，并合理配置并发度以获得最佳性能。</li>
                    </ul>
                  </div>
                </div>
              </div>
            </el-form-item>
            
            <el-form-item label="Header">
              <el-table 
                :data="headerTableData" 
                class="header-table" 
                border 
                :header-cell-style="tableHeaderStyle"
                :cell-style="tableCellStyle"
                stripe
              >
                <el-table-column prop="name" label="参数" min-width="30%" align="center"/>
                <el-table-column prop="value" label="取值" min-width="70%" align="center"/>
              </el-table>
            </el-form-item>
            
            <el-form-item label="Body请求体">
              <el-table 
                :data="bodyRequestBody" 
                class="body-table" 
                border 
                :header-cell-style="tableHeaderStyle"
                :cell-style="tableCellStyle"
                stripe
              >
                <el-table-column prop="param" label="参数" min-width="10%" align="center"/>
                <el-table-column prop="required" label="必填" min-width="10%" align="center">
                  <template #default="scope">
                    <el-tag :type="scope.row.required === '是' ? 'danger' : 'info'" size="small">
                      {{ scope.row.required }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="type" label="类型" min-width="10%" align="center">
                  <template #default="scope">
                    <el-tag type="primary" size="small">{{ scope.row.type }}</el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="desc" label="说明" min-width="70%" align="center"/>
              </el-table>
            </el-form-item>

            <el-form-item label="请求示例" v-if="formOfBaseInformation.serviceType === 'official'">
              <div class="code-example">
                <pre>{{ formattedRequestExample }}</pre>
              </div>
            </el-form-item>
          </el-form>
        </div>
      </div>

      <!-- API测试 -->
      <div class="info-section">
        <div class="section-header">
          <div class="section-line"></div>
          <span class="section-title">API测试</span>
          <div class="test-status" v-if="testStatus">
            <el-tag :type="testStatus.type" size="small">{{ testStatus.text }}</el-tag>
          </div>
        </div>
        <div class="section-content">
          <el-form label-position="top" :model="testForm" class="test-form">
            <el-row :gutter="20">
              <el-col :span="16" :xs="24">
                <el-form-item label="请求URL" required>
                  <el-input v-model="testForm.url" placeholder="请输入请求URL" class="url-input">
                    <template #prepend>
                      <el-select v-model="testForm.method" style="width: 100px">
                        <el-option label="POST" value="POST" />
                        <el-option label="GET" value="GET" />
                      </el-select>
                    </template>
                  </el-input>
                </el-form-item>
              </el-col>
              <el-col :span="8" :xs="24">
                <el-form-item label="Token">
                  <el-input
                    v-model="testForm.token"
                    placeholder="请输入Token"
                    type="password"
                    show-password
                    class="token-input"
                  />
                </el-form-item>
              </el-col>
            </el-row>

            <div class="url-note test-note">
              提示：平台已开启跨域代理。以 <code>/online-api</code> 开头的接口请求将被自动代理转发至目标网关，避免浏览器跨域 (CORS) 限制。
            </div>

            <!-- 配置 Tabs -->
            <div class="request-config-tabs">
              <el-tabs v-model="activeTestTab" type="border-card">
                <!-- 请求体 Tab -->
                <el-tab-pane name="body" label="请求体 (Body)">
                  <div class="body-container-inner">
                    <div class="body-type-selector">
                      <el-radio-group v-model="testForm.bodyType" size="small">
                        <el-radio-button label="json">JSON</el-radio-button>
                        <el-radio-button label="form">Form Data</el-radio-button>
                        <el-radio-button label="raw">Raw</el-radio-button>
                      </el-radio-group>
                    </div>

                    <div v-if="testForm.bodyType === 'json'" class="json-editor">
                      <el-input
                        v-model="testForm.jsonBody"
                        type="textarea"
                        :rows="8"
                        placeholder='请输入JSON格式数据，例如：{"data":[{"feature":"value"}]}'
                        class="code-textarea"
                      />
                      <div class="json-actions">
                        <el-button size="small" :icon="DocumentCopy" @click="formatJson">格式化</el-button>
                        <el-button size="small" :icon="Check" @click="validateJson">验证JSON</el-button>
                        <el-button size="small" :icon="Memo" @click="useExampleData">使用示例</el-button>
                      </div>
                    </div>

                    <div v-else-if="testForm.bodyType === 'form'" class="form-data-editor">
                      <div
                        v-for="(param, index) in testForm.formData"
                        :key="`form-${index}`"
                        class="form-param-row"
                      >
                        <el-input v-model="param.key" placeholder="参数名" class="form-param-key" />
                        <span class="form-separator">=</span>
                        <el-input v-model="param.value" placeholder="参数值" class="form-param-value" />
                        <el-button
                          type="danger"
                          :icon="Delete"
                          circle
                          size="small"
                          @click="removeFormParam(index)"
                        />
                      </div>
                      <el-button type="primary" :icon="Plus" size="small" plain @click="addFormParam">
                        添加参数
                      </el-button>
                    </div>

                    <div v-else class="raw-editor">
                      <el-input
                        v-model="testForm.rawBody"
                        type="textarea"
                        :rows="8"
                        placeholder="请输入原始请求体"
                        class="code-textarea"
                      />
                    </div>
                  </div>
                </el-tab-pane>

                <!-- 请求头 Tab -->
                <el-tab-pane name="headers" label="请求头 (Headers)">
                  <div class="headers-container-inner">
                    <div
                      v-for="(header, index) in testForm.headers"
                      :key="`header-${index}`"
                      class="header-row"
                    >
                      <el-input v-model="header.key" placeholder="参数名" class="header-key-input" />
                      <span class="header-separator">:</span>
                      <el-input v-model="header.value" placeholder="参数值" class="header-value-input" />
                      <el-button
                        type="danger"
                        :icon="Delete"
                        circle
                        size="small"
                        @click="removeHeader(index)"
                      />
                    </div>
                    <el-button type="primary" :icon="Plus" size="small" plain @click="addHeader">
                      添加请求头
                    </el-button>
                  </div>
                </el-tab-pane>
              </el-tabs>
            </div>

            <!-- 操作按钮 -->
            <div class="test-actions-bar">
              <el-button
                type="primary"
                :icon="Position"
                :loading="testLoading"
                size="large"
                class="test-btn"
                @click="sendTestRequest"
              >
                {{ testLoading ? '发送中...' : '发送请求' }}
              </el-button>
              <el-button :icon="Refresh" size="large" @click="clearTestForm">清空</el-button>
              <el-button :icon="CopyDocument" size="large" @click="copyRequestAsCurl">
                复制为cURL
              </el-button>
            </div>
          </el-form>
        </div>
      </div>

      <!-- 测试结果 -->
      <div class="info-section" v-if="testResult.show">
        <div class="section-header">
          <div class="section-line"></div>
          <span class="section-title">测试结果</span>
          <div class="result-meta">
            <el-tag :type="testResult.success ? 'success' : 'danger'" size="small">
              {{ testResult.success ? '成功' : '失败' }}
            </el-tag>
            <span class="response-time" v-if="testResult.responseTime">
              {{ testResult.responseTime }}ms
            </span>
          </div>
        </div>
        <div class="section-content">
          <div class="response-status" v-if="testResult.status">
            <div class="status-item">
              <span class="status-label">状态码：</span>
              <el-tag :type="getStatusType(testResult.status)" size="small">
                {{ testResult.status }}
              </el-tag>
            </div>
            <div class="status-item" v-if="testResult.statusText">
              <span class="status-label">状态文本：</span>
              <span>{{ testResult.statusText }}</span>
            </div>
          </div>

          <div class="response-headers">
            <h4 class="result-section-title">响应头</h4>
            <div class="headers-display" v-if="Object.keys(testResult.headers || {}).length > 0">
              <div v-for="(value, key) in testResult.headers" :key="key" class="header-item">
                <span class="header-key">{{ key }}:</span>
                <span class="header-value">{{ value }}</span>
              </div>
            </div>
            <div v-else class="headers-display">
              <span class="empty-result">未获取到响应头信息</span>
            </div>
          </div>

          <div class="response-body">
            <h4 class="result-section-title">响应体</h4>
            <div class="response-actions">
              <el-button size="small" :icon="DocumentCopy" @click="formatResponseData">格式化</el-button>
              <el-button size="small" :icon="CopyDocument" @click="copyResponse">复制</el-button>
              <el-button size="small" :icon="Download" @click="downloadResponse">下载</el-button>
            </div>
            <pre class="response-data">{{ formattedResponse }}</pre>
          </div>

          <div class="error-info" v-if="testResult.error">
            <h4 class="result-section-title error-title">错误信息</h4>
            <pre class="error-data">{{ testResult.error }}</pre>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>


<script>
import axios from 'axios';
import { useRoute } from 'vue-router';
import { onlineService } from "@/api/task";
import {
  ArrowRight,
  Check,
  CopyDocument,
  Cpu,
  Delete,
  Document,
  DocumentCopy,
  Download,
  InfoFilled,
  Memo,
  Plus,
  Position,
  Refresh
} from '@element-plus/icons-vue';
import { ElMessage } from "element-plus";

export default {
  name: "OnlineServiceDetails",
  data() {
    return {
      activeTestTab: 'body',
      formOfBaseInformation: {},
      modelInformationTableData: [],
      imageInformationTableData: [],
      formOfRequestDesc: {},
      headerTableData: [
        {
          name: 'Token',
          value: localStorage.getItem("Token") || localStorage.getItem("token"),
        }
      ],
      bodyRequestBody: [
        {
          param: 'data',
          required: '是',
          type: 'Array',
          desc: '待预测数据，每条待预测数据是由各个特征及其取值构成的键值对的集合'
        }
      ],
      taskID: '',
      historyID: '',
      version: '',
      ArrowRight,
      Check,
      CopyDocument,
      Document,
      DocumentCopy,
      Download,
      Cpu,
      Delete,
      InfoFilled,
      Memo,
      Plus,
      Position,
      Refresh,
      specificDesc1: {},
      specificDesc2: {},
      serviceId: '',
      formOfResource: {},
      onlineServiceTarget: import.meta.env.VITE_ONLINE_SERVICE_TARGET || '',
      testLoading: false,
      testStatus: null,
      formattedResponse: '',
      testForm: {
        url: '',
        method: 'POST',
        token: '',
        headers: [
          { key: 'Content-Type', value: 'application/json' }
        ],
        bodyType: 'json',
        jsonBody: '',
        formData: [
          { key: '', value: '' }
        ],
        rawBody: ''
      },
      testResult: {
        show: false,
        success: false,
        status: undefined,
        statusText: '',
        headers: {},
        data: undefined,
        error: '',
        responseTime: 0
      },
      serviceStateDic: {
        running: '运行中',
        stoped: '停止',
        exited: '停止',
        error: '未知异常',
        error_connection: '连接异常',
        error_starting: '启动异常',
        error_running: '运行异常',
        waiting: '等待资源',
        starting: '部署中',
      },
      serviceTypeDic: {
        custom: '镜像部署',
        official: '模型部署',
      },
      tableHeaderStyle: {
        background: '#f0f5fa',
        color: '#a82525',
        fontSize: '14px',
        fontWeight: '600',
        textAlign: 'center',
        padding: '12px 0',
        borderBottom: '2px solid #d32f2f',
      },
      tableCellStyle: {
        textAlign: 'center',
        fontSize: '14px',
        padding: '10px 0',
        color: '#303133'
      }
    }
  },
  computed: {
    getServiceStateType() {
      const stateMap = {
        running: 'success',
        stoped: 'info',
        exited: 'info',
        error: 'danger',
        error_connection: 'danger',
        error_starting: 'danger',
        error_running: 'danger',
        waiting: 'warning',
        starting: 'warning',
      };
      return stateMap[this.formOfBaseInformation.serviceState] || 'info';
    },
    formattedRequestExample() {
      if (this.specificDesc1 && Object.keys(this.specificDesc1).length > 0) {
        return JSON.stringify(this.specificDesc1, null, 2);
      }
      return '无请求示例数据';
    }
  },
  created() {
    const route = useRoute();
    this.taskID = route.query.taskId;
    this.historyID = route.query.historyId;
    this.version = route.query.version;
    this.serviceId = route.query.serviceId;
    this.loadServiceDetails();
  },
  methods: {
    loadServiceDetails() {
      onlineService.getOnlineService({
        service_id: this.serviceId
      }).then(res => {
        let middle = {}
        this.formOfBaseInformation['serviceName'] = res.data.service_name;
        this.formOfBaseInformation['serviceId'] = res.data.service_id;
        this.formOfBaseInformation['serviceState'] = res.data.service_state;
        this.formOfBaseInformation['createTime'] = res.data.create_time;
        this.formOfBaseInformation['desc'] = res.data.service_desc;
        this.formOfBaseInformation['serviceType'] = res.data.service_type;
        if (res.data.service_type === 'custom') {
          middle['imageName'] = res.data.image_version_data.image_name;
          middle['imageVersionId'] = res.data.image_version_data.image_version_id;
          middle['tag'] = res.data.image_version_data.tag;
          middle['imageId'] = res.data.image_version_data.image_id;
          this.imageInformationTableData.push(middle);
        } else if (res.data.service_type === 'official') {
          middle['modelName'] = res.data.model_data.model_name;
          middle['modelId'] = res.data.model_id;
          middle['taskId'] = res.data.task_id;
          middle['taskHistoryId'] = res.data.task_history_id;
          middle['isPublic'] = res.data.model_data.is_public === '1' ? '公开' : '不公开';
          this.modelInformationTableData.push(middle);
        } else {
          ElMessage({message: '参数异常！', type: 'error', offset: 60})
        }
        this.formOfResource['memory'] = (res.data.memory / 1000000000) + 'GB';
        this.formOfResource['cpuCoresNum'] = res.data.cpu_cores_num;
        this.formOfRequestDesc.url = this.getUsableRequestUrl(res.data.kong_url || '');
        this.specificDesc1 = JSON.parse(JSON.stringify(res.data.request_data));
        this.testForm.url = this.normalizeDisplayUrl(res.data.kong_url || '');
        this.testForm.token = localStorage.getItem("Token") || localStorage.getItem("token") || '';
        if (res.data.request_data) {
          this.testForm.jsonBody = JSON.stringify(res.data.request_data, null, 2);
        }
        console.log(this.specificDesc1, 'specificDesc1')
        console.log(res.data, 'res.data in loadServiceDetails');
        console.log(this.modelInformationTableData, 'modelInformationTableData in loadServiceDetails');
      })
    },
    getUsableRequestUrl(url) {
      if (!url) return '';
      let targetOrigin = window.location.origin;
      if (this.onlineServiceTarget) {
        try {
          const targetUrl = new URL(this.onlineServiceTarget);
          targetOrigin = targetUrl.origin;
        } catch (e) {
          if (this.onlineServiceTarget.startsWith('http://') || this.onlineServiceTarget.startsWith('https://')) {
            targetOrigin = this.onlineServiceTarget;
          }
        }
      }
      try {
        const parsed = new URL(url);
        return `${targetOrigin}${parsed.pathname}${parsed.search}`;
      } catch (error) {
        const separator = url.startsWith('/') ? '' : '/';
        return `${targetOrigin}${separator}${url}`;
      }
    },
    normalizeDisplayUrl(url) {
      if (!url) return '';
      try {
        const parsed = new URL(url);
        return `/online-api${parsed.pathname}${parsed.search}`;
      } catch (error) {
        if (url.startsWith('/online-api')) return url;
        return `/online-api${url.startsWith('/') ? url : `/${url}`}`;
      }
    },
    getOnlineServiceTargetUrl() {
      if (!this.onlineServiceTarget) return null;
      try {
        return new URL(this.onlineServiceTarget);
      } catch (error) {
        return null;
      }
    },
    buildRequestUrl() {
      const rawUrl = this.testForm.url.replace(/\s+/g, '').trim();
      if (!rawUrl) return '';
      if (rawUrl.startsWith('/online-api')) return rawUrl;
      
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        try {
          const parsed = new URL(rawUrl);
          return `/online-api${parsed.pathname}${parsed.search}`;
        } catch (e) {
          // ignore parsing error
        }
        return rawUrl;
      }
      
      return `/online-api${rawUrl.startsWith('/') ? rawUrl : `/${rawUrl}`}`;
    },
    addHeader() {
      this.testForm.headers.push({ key: '', value: '' });
    },
    removeHeader(index) {
      this.testForm.headers.splice(index, 1);
    },
    addFormParam() {
      this.testForm.formData.push({ key: '', value: '' });
    },
    removeFormParam(index) {
      this.testForm.formData.splice(index, 1);
    },
    formatJson() {
      try {
        this.testForm.jsonBody = JSON.stringify(JSON.parse(this.testForm.jsonBody), null, 2);
        ElMessage.success('JSON格式化成功');
      } catch (error) {
        ElMessage.error('JSON格式错误');
      }
    },
    validateJson() {
      try {
        JSON.parse(this.testForm.jsonBody);
        ElMessage.success('JSON格式正确');
      } catch (error) {
        ElMessage.error(`JSON格式错误：${error.message}`);
      }
    },
    useExampleData() {
      if (this.specificDesc1 && Object.keys(this.specificDesc1).length > 0) {
        this.testForm.jsonBody = JSON.stringify(this.specificDesc1, null, 2);
        ElMessage.success('已填入请求示例');
        return;
      }
      this.testForm.jsonBody = JSON.stringify({ data: [{ feature1: 'value1', feature2: 'value2' }] }, null, 2);
      ElMessage.info('已填入默认示例');
    },
    clearTestForm() {
      this.testForm.jsonBody = '';
      this.testForm.rawBody = '';
      this.testForm.formData = [{ key: '', value: '' }];
      this.testForm.headers = [{ key: 'Content-Type', value: 'application/json' }];
      this.testResult.show = false;
      this.testStatus = null;
      ElMessage.info('已清空请求体和结果');
    },
    buildAxiosConfig() {
      const headers = {};
      if (this.testForm.token) {
        headers.Token = this.testForm.token;
      }
      this.testForm.headers.forEach((header) => {
        if (header.key && header.value) {
          headers[header.key] = header.value;
        }
      });

      const config = {
        method: this.testForm.method.toLowerCase(),
        url: this.buildRequestUrl(),
        timeout: 30000,
        headers,
        validateStatus: () => true,
      };

      if (this.testForm.method !== 'GET') {
        if (this.testForm.bodyType === 'json' && this.testForm.jsonBody) {
          config.data = JSON.parse(this.testForm.jsonBody);
          config.headers['Content-Type'] = 'application/json';
        } else if (this.testForm.bodyType === 'form') {
          const formData = new URLSearchParams();
          this.testForm.formData.forEach((param) => {
            if (param.key && param.value) formData.append(param.key, param.value);
          });
          config.data = formData;
          config.headers['Content-Type'] = 'application/x-www-form-urlencoded';
        } else if (this.testForm.bodyType === 'raw' && this.testForm.rawBody) {
          config.data = this.testForm.rawBody;
        }
      }
      return config;
    },
    async sendTestRequest() {
      if (!this.testForm.url.trim()) {
        ElMessage.error('请输入请求URL');
        return;
      }
      this.testLoading = true;
      this.testStatus = { type: 'warning', text: '发送中...' };
      this.testResult.show = false;
      const startTime = Date.now();

      try {
        const config = this.buildAxiosConfig();
        const response = await axios(config);
        const responseTime = Date.now() - startTime;
        const headers = {};
        Object.entries(response.headers || {}).forEach(([key, value]) => {
          headers[key.toLowerCase()] = String(value);
        });

        this.testResult = {
          show: true,
          success: response.status >= 200 && response.status < 300,
          status: response.status,
          statusText: response.statusText,
          headers,
          data: response.data,
          error: response.status >= 200 && response.status < 300 ? '' : `HTTP ${response.status}: ${response.statusText || '请求失败'}`,
          responseTime,
        };
        this.formattedResponse = typeof response.data === 'object'
          ? JSON.stringify(response.data, null, 2)
          : String(response.data ?? '');
        this.testStatus = this.testResult.success
          ? { type: 'success', text: '请求成功' }
          : { type: 'danger', text: '请求失败' };

        if (this.testResult.success) {
          ElMessage.success(`请求成功，耗时 ${responseTime}ms`);
        } else {
          ElMessage.error(`请求失败：HTTP ${response.status}`);
        }
      } catch (error) {
        const responseTime = Date.now() - startTime;
        this.testResult = {
          show: true,
          success: false,
          status: error.response?.status,
          statusText: error.response?.statusText || '',
          headers: error.response?.headers || {},
          data: error.response?.data,
          error: error.message || '请求失败',
          responseTime,
        };
        this.formattedResponse = error.response?.data
          ? (typeof error.response.data === 'object' ? JSON.stringify(error.response.data, null, 2) : String(error.response.data))
          : '请求失败，请检查服务状态或代理配置';
        this.testStatus = { type: 'danger', text: '请求失败' };
        ElMessage.error(`请求失败：${this.testResult.error}`);
      } finally {
        this.testLoading = false;
      }
    },
    async copyRequestAsCurl() {
      try {
        let curlCommand = `curl -X ${this.testForm.method} "${this.buildRequestUrl()}"`;
        if (this.testForm.token) {
          curlCommand += ` \\\n  -H "Token: ${this.testForm.token}"`;
        }
        this.testForm.headers.forEach((header) => {
          if (header.key && header.value) {
            curlCommand += ` \\\n  -H "${header.key}: ${header.value}"`;
          }
        });
        if (this.testForm.method !== 'GET') {
          if (this.testForm.bodyType === 'json' && this.testForm.jsonBody) {
            curlCommand += ` \\\n  -d '${this.testForm.jsonBody}'`;
          } else if (this.testForm.bodyType === 'form') {
            const formParams = this.testForm.formData
              .filter((param) => param.key && param.value)
              .map((param) => `${encodeURIComponent(param.key)}=${encodeURIComponent(param.value)}`)
              .join('&');
            if (formParams) curlCommand += ` \\\n  -d "${formParams}"`;
          } else if (this.testForm.bodyType === 'raw' && this.testForm.rawBody) {
            curlCommand += ` \\\n  -d '${this.testForm.rawBody}'`;
          }
        }
        await navigator.clipboard.writeText(curlCommand);
        ElMessage.success('cURL命令已复制');
      } catch (error) {
        ElMessage.error('复制失败');
      }
    },
    formatResponseData() {
      try {
        this.formattedResponse = JSON.stringify(JSON.parse(this.formattedResponse), null, 2);
        ElMessage.success('响应体格式化成功');
      } catch (error) {
        ElMessage.warning('响应体不是有效JSON');
      }
    },
    async copyResponse() {
      try {
        await navigator.clipboard.writeText(this.formattedResponse);
        ElMessage.success('响应体已复制');
      } catch (error) {
        ElMessage.error('复制失败');
      }
    },
    downloadResponse() {
      const blob = new Blob([this.formattedResponse], { type: 'application/json;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `api-response-${Date.now()}.json`;
      link.click();
      URL.revokeObjectURL(url);
    },
    getStatusType(status) {
      if (status >= 200 && status < 300) return 'success';
      if (status >= 300 && status < 400) return 'warning';
      if (status >= 400) return 'danger';
      return 'info';
    }
  }
}
</script>

<style scoped>
/* 容器样式 */
.service-details-container {
  display: flex;
  flex-direction: column;
  background-color: #f5f7fa;
  min-height: 100vh;
}

/* 头部区域 */
.header-area {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px 32px;
  background: linear-gradient(135deg, #a82525, #d32f2f);
  border-radius: 4px;
  color: white;
  margin: 20px 20px 0;
  box-shadow: 0 8px 20px rgba(168, 37, 37, 0.15);
  position: relative;
  overflow: hidden;
}

.header-area::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0) 100%);
  transform: skewX(-45deg) translateX(-150%);
  transition: transform 0.8s ease;
}

.header-area:hover::before {
  transform: skewX(-45deg) translateX(150%);
}

.tech-title {
  font-size: 18px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 12px;
  text-shadow: 0px 1px 2px rgba(0, 0, 0, 0.3);
  letter-spacing: 0.5px;
}

.tech-title .el-icon {
  font-size: 24px;
  color: #ffffff;
  background: rgba(255, 255, 255, 0.2);
  padding: 8px;
  border-radius: 4px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
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
  transition: opacity 0.2s ease;
}

:deep(.tech-breadcrumb a:hover) {
  opacity: 0.8;
}

:deep(.el-breadcrumb__separator) {
  color: #ffffff !important;
}

/* 主内容区域 */
.main-content-wrapper {
  background-color: transparent;
  margin: 10px 20px 20px;
  padding: 0;
  min-height: calc(100vh - 150px);
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* 区块样式 */
.info-section {
  margin-bottom: 0;
  background-color: #ffffff;
  border-radius: 4px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.04);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  overflow: hidden;
}

.info-section:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.08);
}

.section-header {
  display: flex;
  align-items: center;
  padding: 18px 24px;
  border-bottom: 1px solid #f0f2f5;
  background: #ffffff;
}

.section-line {
  width: 5px;
  height: 24px;
  background: linear-gradient(to bottom, #a82525, #d32f2f);
  border-radius: 3px;
  margin-right: 15px;
}

.section-title {
  font-size: 18px;
  font-weight: 600;
  color: #a82525;
  letter-spacing: 0.5px;
}

.section-content {
  padding: 24px 30px;
}

/* 表单与描述列表样式 */
.info-descriptions {
  margin: 10px 0;
}

:deep(.el-descriptions__table) {
  border-radius: 4px;
  overflow: hidden;
  border-collapse: collapse;
}

:deep(.el-descriptions__label) {
  background-color: #f8fafc !important;
  color: #a82525 !important;
  font-weight: 600 !important;
  width: 150px;
  padding: 16px 20px !important;
}

:deep(.el-descriptions__content) {
  padding: 16px 20px !important;
  color: #333333 !important;
}

.info-value {
  font-size: 14px;
}

.info-value.text-bold {
  font-weight: 600;
  color: #1d2129;
}

.info-value.code-font {
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  font-weight: 500;
  color: #4e5969;
}

.info-value.desc-text {
  color: #4e5969;
  line-height: 1.5;
}

.status-tag,
.type-tag {
  border-radius: 4px;
}

.info-form {
  max-width: 800px;
}

:deep(.el-form-item) {
  margin-bottom: 24px;
  position: relative;
  padding-left: 10px;
  border-left: 2px solid transparent;
  transition: border-color 0.3s ease;
}

:deep(.el-form-item:hover) {
  border-left-color: #d32f2f;
}

:deep(.el-form-item__label) {
  font-weight: 600;
  color: #a82525;
  font-size: 15px;
}

:deep(.el-form-item__content) {
  line-height: 1.6;
  font-size: 15px;
}

:deep(.el-form-item__content span) {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  color: #333;
}

:deep(.el-form-item:last-child) {
  margin-bottom: 0;
}

/* 表格样式 */
.info-table, 
.header-table, 
.body-table {
  width: 100%;
  border-radius: 4px;
  overflow: hidden;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.03);
}

:deep(.el-table) {
  --el-table-header-bg-color: #f0f5fa;
  --el-table-border-color: #e5e9f2;
  --el-table-row-hover-bg-color: #f0f7ff;
  border-radius: 4px;
  overflow: hidden;
}

:deep(.el-table::before) {
  display: none;
}

:deep(.el-table th) {
  padding: 14px 0;
  font-size: 14px;
}

:deep(.el-table__header) {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

:deep(.el-table--striped .el-table__body tr.el-table__row--striped td.el-table__cell) {
  background-color: #f8fafc;
}

:deep(.el-table--enable-row-hover .el-table__body tr:hover > td.el-table__cell) {
  background-color: #f0f7ff;
  transition: background-color 0.2s ease;
}

:deep(.el-table td.el-table__cell) {
  transition: background-color 0.2s ease;
}

:deep(.el-table .cell) {
  padding: 0 15px;
}

/* 标签样式美化 */
:deep(.el-tag) {
  border-radius: 4px;
  padding: 0 10px;
  height: 26px;
  line-height: 24px;
  font-weight: 500;
  transition: all 0.2s ease;
}

:deep(.el-tag--small) {
  padding: 0 8px;
  height: 24px;
  line-height: 22px;
}

:deep(.el-tag.el-tag--success) {
  background-color: rgba(103, 194, 58, 0.1);
  border-color: rgba(103, 194, 58, 0.2);
  color: var(--el-color-success);
}

:deep(.el-tag.el-tag--info) {
  background-color: rgba(144, 147, 153, 0.1);
  border-color: rgba(144, 147, 153, 0.2);
  color: #606266;
}

:deep(.el-tag.el-tag--primary) {
  background-color: rgba(64, 158, 255, 0.1);
  border-color: rgba(64, 158, 255, 0.2);
  color: var(--el-color-primary);
}

:deep(.el-tag.el-tag--danger) {
  background-color: rgba(245, 108, 108, 0.1);
  border-color: rgba(245, 108, 108, 0.2);
  color: var(--el-color-danger);
}

:deep(.el-tag.el-tag--warning) {
  background-color: rgba(230, 162, 60, 0.1);
  border-color: rgba(230, 162, 60, 0.2);
  color: var(--el-color-warning);
}

/* 资源规格卡片样式 */
.resource-info {
  padding: 10px 0;
}

.resource-card {
  display: flex;
  align-items: center;
  padding: 24px;
  background: linear-gradient(145deg, #ffffff, #f8fafc);
  border-radius: 4px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  border: 1px solid #ebeef5;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  position: relative;
  overflow: hidden;
  height: 100%;
}

.resource-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
}

.resource-card::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 4px;
  background: linear-gradient(to right, #a82525, #d32f2f);
  opacity: 0;
  transition: opacity 0.3s ease;
}

.resource-card:hover::after {
  opacity: 1;
}

.resource-icon {
  width: 70px;
  height: 70px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  margin-right: 24px;
  background: linear-gradient(135deg, rgba(211, 47, 47, 0.2), rgba(211, 47, 47, 0.1));
  color: #d32f2f;
  box-shadow: 0 4px 10px rgba(211, 47, 47, 0.15);
  transition: transform 0.3s ease;
}

.resource-card:hover .resource-icon {
  transform: scale(1.05);
}

.memory-icon {
  background: linear-gradient(135deg, rgba(168, 37, 37, 0.2), rgba(168, 37, 37, 0.1));
  color: #a82525;
  box-shadow: 0 4px 10px rgba(168, 37, 37, 0.15);
}

.resource-data {
  display: flex;
  flex-direction: column;
}

.resource-value {
  font-size: 26px;
  font-weight: 700;
  color: #a82525;
  margin-bottom: 8px;
  letter-spacing: 0.5px;
}

.resource-label {
  font-size: 14px;
  color: #606266;
  text-transform: uppercase;
  letter-spacing: 1px;
  font-weight: 500;
}

/* 请求说明样式 */
.request-form {
  width: 100%;
}

.url-container {
  line-height: 1.8;
}

.url-value {
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  background-color: #f8fafc;
  padding: 12px 16px;
  border-radius: 4px;
  border: 1px solid #ebeef5;
  font-size: 14px;
  word-break: break-all;
  color: #a82525;
  box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.05);
  position: relative;
}

.url-value::before {
  content: "URL";
  position: absolute;
  top: -10px;
  left: 12px;
  background: #f8fafc;
  padding: 0 8px;
  font-size: 12px;
  color: var(--el-color-info);
  border: 1px solid #ebeef5;
  border-radius: 4px;
}

.url-note {
  margin-top: 12px;
  color: var(--el-color-danger);
  font-size: 13px;
  background: rgba(245, 108, 108, 0.05);
  padding: 8px 12px;
  border-radius: 4px;
  border-left: 3px solid var(--el-color-danger);
}

.code-example {
  margin-bottom: 20px;
  width: 100%;
}

.code-example pre {
  background-color: #1f2937;
  padding: 20px;
  border-radius: 4px;
  overflow: auto;
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  white-space: pre-wrap;
  word-break: break-all;
  font-size: 14px;
  line-height: 1.6;
  max-height: 500px;
  min-height: 180px;
  width: 100%;
  box-sizing: border-box;
  color: #e5e7eb;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  position: relative;
}

/* 接口调用说明样式 */
.url-instruction {
  margin-top: 15px;
  background-color: #fcfdfe;
  border: 1px solid #eef2f6;
  border-left: 4px solid #a82525;
  border-radius: 4px;
  padding: 18px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.02);
}

.instruction-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  color: #a82525;
  font-size: 15px;
  margin-bottom: 12px;
}

.instruction-title .el-icon {
  font-size: 18px;
  color: #a82525;
}

.instruction-content {
  font-size: 13.5px;
  color: #4e5969;
  line-height: 1.6;
}

.instruction-content p {
  margin: 0 0 10px 0;
  color: #1d2129;
}

.instruction-list {
  margin: 0;
  padding-left: 18px;
}

.instruction-list li {
  margin-bottom: 10px;
}

.instruction-list li:last-child {
  margin-bottom: 0;
}

.instruction-list code {
  background-color: #f1f3f5;
  color: #d32f2f;
  padding: 2px 6px;
  border-radius: 4px;
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  font-size: 12px;
}

.mini-table {
  margin-top: 8px;
  background-color: #ffffff;
  border: 1px solid #e5e6eb;
  border-radius: 4px;
  max-width: 500px;
  overflow: hidden;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.01);
}

.mini-row {
  display: flex;
  border-bottom: 1px solid #e5e6eb;
  font-size: 12.5px;
}

.mini-row:last-child {
  border-bottom: none;
}

.mini-row .key {
  width: 120px;
  padding: 8px 12px;
  background-color: #f7f8fa;
  font-weight: 600;
  color: #a82525;
  border-right: 1px solid #e5e6eb;
  flex-shrink: 0;
}

.mini-row .val {
  flex: 1;
  padding: 8px 12px;
  color: #4e5969;
  word-break: break-all;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}

.code-example pre::before {
  content: "请求示例";
  position: absolute;
  top: -10px;
  left: 15px;
  background: #f5f7fa;
  padding: 3px 10px;
  font-size: 12px;
  color: #606266;
  border-radius: 4px;
  font-family: -apple-system, BlinkMacSystemFont, sans-serif;
  font-weight: 500;
}

/* API测试样式 */
.test-status,
.result-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-left: auto;
}

.test-form,
.url-input,
.token-input {
  width: 100%;
}

/* API测试 Tabs */
.request-config-tabs {
  margin-top: 20px;
  margin-bottom: 24px;
  width: 100%;
}

:deep(.request-config-tabs .el-tabs--border-card) {
  border: 1px solid #ebeef5;
  border-radius: 4px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.03);
  overflow: hidden;
}

:deep(.request-config-tabs .el-tabs__header) {
  background-color: #f8fafc;
  border-bottom: 1px solid #ebeef5;
}

:deep(.request-config-tabs .el-tabs__item) {
  color: #606266;
  font-weight: 500;
  font-size: 14px;
  transition: all 0.2s ease;
}

:deep(.request-config-tabs .el-tabs__item.is-active) {
  color: #a82525;
  font-weight: 600;
  background-color: #ffffff;
  border-right-color: #ebeef5;
  border-left-color: #ebeef5;
}

.body-container-inner,
.headers-container-inner {
  padding: 8px 4px;
}

.body-type-selector {
  margin-bottom: 16px;
}

.test-actions-bar {
  display: flex;
  justify-content: flex-start;
  align-items: center;
  gap: 15px;
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid #f0f2f5;
  width: 100%;
}

.test-note {
  margin-top: 10px;
  margin-bottom: 16px;
}

.header-row,
.form-param-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
}

.header-key-input,
.form-param-key {
  flex: 1;
  min-width: 140px;
}

.header-value-input,
.form-param-value {
  flex: 2;
}

.header-separator,
.form-separator {
  color: var(--el-color-info);
  font-weight: 600;
}

.json-editor,
.form-data-editor,
.raw-editor {
  padding: 16px;
}

.code-textarea :deep(.el-textarea__inner) {
  background-color: #1f2937;
  color: #e5e7eb;
  border: none;
  border-radius: 4px;
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  font-size: 14px;
  line-height: 1.6;
}

.json-actions,
.test-actions,
.response-actions {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.json-actions {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #ebeef5;
}

.test-btn {
  background: linear-gradient(to right, #a82525, #d32f2f);
  border: none;
  border-radius: 4px;
  box-shadow: 0 4px 12px rgba(168, 37, 37, 0.22);
}

.response-time {
  color: var(--el-color-info);
  font-size: 12px;
}

.response-status {
  display: flex;
  gap: 24px;
  margin-bottom: 20px;
  padding: 16px;
  background: #f8fafc;
  border-radius: 4px;
}

.status-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.status-label {
  color: #606266;
  font-weight: 600;
}

.result-section-title {
  margin: 0 0 12px;
  padding-bottom: 8px;
  border-bottom: 2px solid #f0f2f5;
  color: #a82525;
  font-size: 16px;
  font-weight: 600;
}

.headers-display {
  max-height: 260px;
  overflow: auto;
  padding: 16px;
  background: #f8fafc;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  margin-bottom: 20px;
}

.header-item {
  display: flex;
  gap: 8px;
  margin-bottom: 8px;
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  font-size: 13px;
}

.header-item:last-child {
  margin-bottom: 0;
}

.header-item .header-key {
  min-width: 180px;
  color: #a82525;
  font-weight: 600;
}

.header-item .header-value {
  flex: 1;
  color: #303133;
  word-break: break-all;
}

.empty-result {
  color: var(--el-color-info);
  font-style: italic;
}

.response-body {
  margin-bottom: 20px;
}

.response-data,
.error-data {
  max-height: 500px;
  overflow: auto;
  padding: 20px;
  border-radius: 4px;
  white-space: pre-wrap;
  word-break: break-all;
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  font-size: 14px;
  line-height: 1.6;
}

.response-data {
  background-color: #1f2937;
  color: #e5e7eb;
}

.error-title {
  color: var(--el-color-danger);
}

.error-data {
  background: #fef0f0;
  color: var(--el-color-danger);
  border: 1px solid #fbc4c4;
}

/* 响应式调整 */
@media (max-width: 768px) {
  .header-area {
    padding: 18px;
    margin: 15px 15px 0;
  }
  
  .tech-title {
    font-size: 16px;
  }
  
  .main-content-wrapper {
    margin: 10px 15px 15px;
    gap: 15px;
  }
  
  .section-content {
    padding: 18px 20px;
  }
  
  .resource-info {
    padding: 0;
  }
  
  .resource-card {
    margin-bottom: 15px;
    padding: 18px;
  }

  .resource-icon {
    width: 55px;
    height: 55px;
    margin-right: 18px;
  }
  
  .url-value {
    font-size: 13px;
    padding: 10px;
  }

  .code-example pre {
    padding: 15px;
    font-size: 13px;
  }

  .url-instruction {
    padding: 12px;
  }

  .mini-row {
    flex-direction: column;
  }

  .mini-row .key {
    width: 100%;
    border-right: none;
    border-bottom: 1px solid #e5e6eb;
  }

  .header-row,
  .form-param-row,
  .response-status {
    align-items: stretch;
    flex-direction: column;
  }

  .header-item {
    flex-direction: column;
  }
}

@media (max-width: 576px) {
  .section-header {
    padding: 15px 18px;
  }
  
  .section-content {
    padding: 15px;
  }
  
  .resource-icon {
    width: 45px;
    height: 45px;
    margin-right: 15px;
  }
  
  .resource-value {
    font-size: 20px;
  }
}
</style>
