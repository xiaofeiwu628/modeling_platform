<template>
  <div class="image-repository">
    <!-- 顶部导航区域 -->
    <div class="header-area">
      <el-breadcrumb :separator-icon="ArrowRight">
        <el-breadcrumb-item class="tech-title">
          <el-icon><Picture /></el-icon>
          {{ pageIndex === 1 ? '我的镜像' : '公开镜像' }}
        </el-breadcrumb-item>
      </el-breadcrumb>
      
      <!-- 镜像概览卡片 -->
      <div class="image-metrics" v-if="pageIndex === 1">
        <div class="metric-card">
          <div class="metric-value">{{myImageData.length}}</div>
          <div class="metric-label">我的镜像总数</div>
        </div>
        <div class="metric-card">
          <div class="metric-value">{{getTotalVersions(myImageData)}}</div>
          <div class="metric-label">镜像版本总数</div>
        </div>
        <div class="metric-card">
          <div class="metric-value">{{getUsedImageVersions(myImageData)}}</div>
          <div class="metric-label">使用中版本</div>
        </div>
      </div>
      
      <div class="image-metrics" v-if="pageIndex === 2">
        <div class="metric-card">
          <div class="metric-value">{{publicImageData.length}}</div>
          <div class="metric-label">公开镜像总数</div>
        </div>
      </div>
    </div>

    <div class="content-panel">
      <!-- 页面导航栏 -->
      <div class="tab-container">
        <el-menu class="el-menu-m" mode="horizontal" :default-active="pageIndex.toString()">
          <el-menu-item index="1" @click="changePageIndex(1)">我的镜像</el-menu-item>
          <el-menu-item index="2" @click="changePageIndex(2)">公开镜像</el-menu-item>
        </el-menu>
      </div>

      <!--我的镜像-->
      <div v-if="pageIndex === 1">
        <div class="action-bar">
            <div class="left-area">
              <el-button type="primary" @click="openImageImportDialog" class="create-btn">
                <el-icon><Plus /></el-icon>
                镜像创建
              </el-button>
            </div>
          
          <div class="middle-area">
            <!-- 可以添加筛选功能 -->
          </div>
          
          <div class="right-area">
            <div class="search-box">
              <el-input
                v-model="selectInputByImageName"
                placeholder="输入镜像名称查询"
                class="search-input"
                clearable
                @clear="loadMyImage"
                @keyup.enter="selectByImageName"
              >
                <template #prefix>
                  <el-icon><Search /></el-icon>
                </template>
                <template #append>
                  <el-button @click="selectByImageName">
                    <el-icon><Search /></el-icon>
                  </el-button>
                </template>
              </el-input>
            </div>
            
            <el-button 
              class="refresh-btn" 
              @click="loadMyImage" 
              :loading="myImageLoading"
              type="primary"
              plain>
              <el-icon class="refresh-icon" :class="{ 'is-loading': myImageLoading }"><Refresh /></el-icon>
              刷新列表
            </el-button>
          </div>
        </div>

        <!--我的镜像列表-->
        <div class="table-container">
          <el-table 
            :data="myImageData" 
            border 
            v-loading="myImageLoading" 
            :row-style="{ height: '65px' }"
            :cell-style="{ 'text-align': 'center' }"
            :header-cell-style="{ 'text-align': 'center', background: '#1a2942', color: '#fff' }"
            class="image-table"
          >
            <el-table-column type="expand" min-width="3%">
              <template #default="slot">
                <el-table 
                  :data="slot.row.image_version" 
                  style="width: 90%; margin: 15px auto" 
                  border 
                  :header-cell-style="{ 'text-align': 'center', background: '#f5f7fa', color: '#606266' }"
                  :cell-style="{ 'text-align': 'center' }"
                  class="version-table"
                >
                  <el-table-column prop="tag" label="版本号" min-width="15%" align="center"/>
                  <el-table-column prop="image_version_id" label="版本ID" min-width="15%" align="center"/>
                  <el-table-column prop="version_desc" label="描述" min-width="15%" align="center"/>
                  <el-table-column prop="is_used" label="是否使用" min-width="15%" align="center">
                    <template #default="scope">
                      <el-link :underline="false" type="primary" @click="openServiceDialog(scope.row)" v-if="scope.row.is_used === 1">{{ imageStateDic[scope.row.is_used as keyof typeof imageStateDic] }}</el-link>
                      <el-tag type="info" effect="plain" v-if="scope.row.is_used === 0">{{ imageStateDic[scope.row.is_used as keyof typeof imageStateDic] }}</el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column prop="create_time" label="导入时间" min-width="18%" align="center"/>
                  <el-table-column label="操作" min-width="22%">
                    <template #default="scope">
                      <div class="action-buttons">
                        <el-dropdown class="action-dropdown">
                          <span class="el-dropdown-link">
                            部署 <el-icon class="el-icon--right"><ArrowDown /></el-icon>
                          </span>
                          <template #dropdown>
                            <el-dropdown-menu>
                              <el-dropdown-item @click="createOnlineService(slot.row,scope.row)">在线服务</el-dropdown-item>
                            </el-dropdown-menu>
                          </template>
                        </el-dropdown>
                        
                        <el-popconfirm title="确定删除吗？" @confirm="versionDeleteMethod(scope.row,slot.row)">
                          <template #reference>
                            <el-button link type="primary" class="action-button">删除</el-button>
                          </template>
                        </el-popconfirm>
                      </div>
                    </template>
                  </el-table-column>
                </el-table>
              </template>
            </el-table-column>
            <el-table-column prop="image_name" label="镜像名称" sortable min-width="12%" align="center"/>
            <el-table-column prop="image_id" label="镜像ID" min-width="12%" align="center"/>
            <el-table-column prop="image_desc" label="描述" min-width="12%" align="center"/>
            <el-table-column prop="is_public" label="是否公开" min-width="12%" align="center">
              <template #default="scope">
                <el-tag 
                  :type="scope.row.is_public === 0 ? 'info' : 'success'"
                  effect="light"
                  round
                >
                  {{scope.row.is_public === 0 ? '不公开' : '公开'}}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="version_num" label="版本数量" min-width="12%" align="center"/>
            <el-table-column prop="create_time" label="创建时间" min-width="12%" align="center"/>
            <el-table-column label="操作" min-width="25%">
              <template #default="scope">
                <div class="action-buttons">
                  <el-button 
                    type="primary" 
                    size="small" 
                    @click="addVersion(scope.row)"
                    class="action-btn"
                    round>新增版本</el-button>
                  <el-button 
                    type="primary" 
                    size="small" 
                    @click="openModifyVersionDialog(scope.row)"
                    class="action-btn"
                    round>修改</el-button>
                  <el-button 
                    type="danger" 
                    size="small" 
                    @click="openImageDeleteDialog(scope.row)"
                    class="action-btn"
                    round>删除</el-button>
                </div>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </div>

      <!--公开镜像-->
      <div v-if="pageIndex === 2">
        <div class="action-bar">
          <div class="left-area">
            <el-button 
              class="refresh-btn" 
              @click="loadPublicImage({is_public:1})" 
              :loading="publicImageLoading"
              type="primary"
              plain>
              <el-icon class="refresh-icon" :class="{ 'is-loading': publicImageLoading }"><Refresh /></el-icon>
              刷新列表
            </el-button>
          </div>
          
          <div class="middle-area">
            <!-- 可以添加筛选功能 -->
          </div>
          
          <div class="right-area">
            <div class="search-box">
              <el-input
                v-model="selectInputByPublicImageName"
                placeholder="输入镜像名称查询"
                class="search-input"
                clearable
                @clear="loadPublicImage"
                @keyup.enter="selectByPublicImageName"
              >
                <template #prefix>
                  <el-icon><Search /></el-icon>
                </template>
                <template #append>
                  <el-button @click="selectByPublicImageName">
                    <el-icon><Search /></el-icon>
                  </el-button>
                </template>
              </el-input>
            </div>
          </div>
        </div>
        
        <!--公开镜像列表-->
        <div class="table-container">
          <el-table 
            :data="publicImageData" 
            border 
            v-loading="publicImageLoading" 
            :row-style="{ height: '65px' }"
            :cell-style="{ 'text-align': 'center' }"
            :header-cell-style="{ 'text-align': 'center', background: '#1a2942', color: '#fff' }"
            class="image-table"
          >
            <el-table-column type="expand" min-width="3%">
              <template #default="slot">
                <el-table 
                  :data="slot.row.image_version" 
                  style="width: 90%; margin: 15px auto" 
                  border 
                  :header-cell-style="{ 'text-align': 'center', background: '#f5f7fa', color: '#606266' }"
                  :cell-style="{ 'text-align': 'center' }"
                  class="version-table"
                >
                  <el-table-column prop="tag" label="版本号" min-width="13%" align="center"/>
                  <el-table-column prop="image_version_id" label="版本ID" min-width="13%" align="center"/>
                  <el-table-column prop="version_desc" label="描述" min-width="13%" align="center"/>
                  <el-table-column prop="create_time" label="创建时间" min-width="13%" align="center"/>
                  <el-table-column label="操作" min-width="22%">
                    <template #default="scope">
                      <div class="action-buttons">
                        <el-dropdown class="action-dropdown">
                          <span class="el-dropdown-link">
                            部署 <el-icon class="el-icon--right"><ArrowDown /></el-icon>
                          </span>
                          <template #dropdown>
                            <el-dropdown-menu>
                              <el-dropdown-item @click="createOnlineService(scope.row)">在线服务</el-dropdown-item>
                            </el-dropdown-menu>
                          </template>
                        </el-dropdown>
                      </div>
                    </template>
                  </el-table-column>
                </el-table>
              </template>
            </el-table-column>
            <el-table-column prop="image_name" label="镜像名称" sortable min-width="12%" align="center"/>
            <el-table-column prop="image_id" label="镜像ID" min-width="12%" align="center"/>
            <el-table-column prop="image_desc" label="描述" min-width="12%" align="center"/>
            <el-table-column prop="username" label="拥有者" min-width="12%" align="center" sortable>
              <template #default="scope">
                <div class="owner-cell">
                  <span>{{scope.row.username}}</span>
                  <el-tag
                    :type="scope.row.modify_permission === '其他' ? 'danger' : 'success'"
                    effect="light"
                    size="small"
                    round
                  >{{ scope.row.modify_permission }}</el-tag>
                </div>
              </template>
            </el-table-column>
            <el-table-column prop="version_num" label="版本数量" min-width="12%" align="center"/>
            <el-table-column prop="create_time" label="创建时间" min-width="12%" align="center"/>
            <el-table-column fixed="right" label="操作" min-width="25%">
              <template #default="scope">
                <!-- 公共镜像操作按钮 -->
              </template>
            </el-table-column>
          </el-table>
        </div>
      </div>
      
      <!-- 各种弹出对话框保持原样，只是更新样式 -->
      <!--镜像信息修改对话框-->
      <el-dialog v-model="modifyMyImageDialog" title="镜像修改" width="500px" class="image-dialog">
        <el-form
            label-position="left"
            label-width="100px"
            :model="formOfModifyMyImage"
            style="max-width: 420px;margin-left: 10px"
        >
          <el-form-item label="镜像名称">
            <el-input v-model="formOfModifyMyImage.imageName" disabled />
          </el-form-item>
          <el-form-item label="镜像描述">
            <el-input type="textarea" v-model="formOfModifyMyImage.imageDesc" />
          </el-form-item>
          <el-form-item label="是否公开">
            <el-radio-group v-model="formOfModifyMyImage.isPublic" style="margin-left: 10px" >
              <el-radio label="不公开" />
              <el-radio label="公开" />
            </el-radio-group>
          </el-form-item>
        </el-form>
        <template #footer>
            <span>
              <el-button @click="modifyMyImageDialog = false">取消</el-button>
              <el-button type="primary" @click="modifyMyImage">确定</el-button>
            </span>
        </template>
      </el-dialog>

      <!--镜像创建-->
      <el-dialog v-model="importMyImageInfoDialog" title="镜像创建" width="30%" class="image-dialog">
        <el-form
            label-position="right"
            label-width="100px"
            :model="formOfImageInfoImport"
            style="max-width: 420px;margin-left: 10px"
            :rules="rules"
            ref="imageImportRef"
        >
          <el-form-item label="镜像名称" prop="imageName">
            <el-input v-model="formOfImageInfoImport.imageName" />
          </el-form-item>
          <el-form-item label="镜像描述">
            <el-input type="textarea" placeholder="请输入镜像描述，100字以内" maxlength="100" rows="4" v-model="formOfImageInfoImport.imageDesc" />
          </el-form-item>
          <el-form-item label="是否公开">
            <el-radio-group v-model="formOfImageInfoImport.isPublic" style="margin-left: 10px" >
              <el-radio label="不公开" />
              <el-radio label="公开" />
            </el-radio-group>
          </el-form-item>
        </el-form>
        <template #footer>
            <span>
              <el-button @click="importMyImageInfoDialog = false">取消</el-button>
              <el-button type="primary" @click="importMyImageInfo">确定</el-button>
            </span>
        </template>
      </el-dialog>

      <!--新增镜像版本-->
      <el-dialog v-model="importMyImageVersionDialog" title="新增版本" width="30%" class="image-dialog">
        <el-form
            label-position="right"
            label-width="100px"
            :model="formOfImageVersionImport"
            style="max-width: 420px;margin-left: 10px"
            :rules="rules"
            ref="imageVersionImportRef"
        >
          <el-form-item label="版本号" prop="tag">
            <el-input v-model="formOfImageVersionImport.tag" placeholder="e.g:1.0"/>
          </el-form-item>
          <el-form-item label="描述">
            <el-input type="textarea" placeholder="请输入镜像版本的描述，100字以内" maxlength="100" rows="4" v-model="formOfImageVersionImport.imageVersionDesc" />
          </el-form-item>
          <el-form-item label="上传文件">
            <el-button @click="uploadFileDialog = true" type="primary" plain>点击上传</el-button>
          </el-form-item>
        </el-form>
        <template #footer>
            <span>
              <el-button @click="importMyImageVersionDialog = false">取消</el-button>
              <el-button type="primary" @click="importMyImageVersion">确定</el-button>
            </span>
        </template>

        <!--上传文件窗口-->
        <el-dialog v-model="uploadFileDialog" title="文件上传" width="35%" class="upload-dialog" append-to-body>
          <el-upload
              class="upload-demo"
              drag
              action=""
              :on-change="importFile"
              :auto-upload="false"
              :limit="1"
              :before-upload="beforeUploadFile"
              ref="uploadRef"
          >
            <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
            <div class="el-upload__text">
              将文件拖到此处，或<em>点击上传</em>
            </div>
            <template #tip>
              <div class="el-upload__tip">
                请上传镜像文件的压缩包
              </div>
            </template>
          </el-upload>
          <template #footer>
            <span>
              <el-button @click="importFileCancel">取消</el-button>
              <el-button type="primary" @click="uploadFileDialog = false">确定</el-button>
            </span>
          </template>
        </el-dialog>
      </el-dialog>

      <!--上传中-弹出框-->
      <el-dialog
          v-model="uploadingDialog"
          title="文件上传"
          :show-close="false"
          width="21%"
          class="uploading-dialog"
          :close-on-click-modal="false"
          :close-on-press-escape="false">
        <div class="upload-progress-container">
          <div class="progress-chart">
            <el-progress type="dashboard" :percentage="completionDic[identifier]">
              <template #default="{ percentage }">
                <span class="percentage-value">{{ percentage }}%</span>
                <span class="percentage-label" v-if="uploadingFlag">上传中</span>
              </template>
            </el-progress>
          </div>
          <div class="progress-message">
            <p>{{uploadMessage}}</p>
          </div>
        </div>
        <template #footer>
          <div>
            <el-button v-if="!closeFlag" @click="cancelUpload" type="danger">取消上传</el-button>
            <el-button v-if="closeFlag" type="primary" @click="uploadingDialog = false">关闭</el-button>
          </div>
        </template>
      </el-dialog>

      <!--镜像对应服务的列表-->
      <el-dialog v-model="imageServiceDialog" title="在线服务列表" min-width="500px" class="image-dialog">
        <el-table 
          :data="imageServiceData" 
          border 
          :header-cell-style="{'text-align': 'center', background: '#f5f7fa'}" 
          :cell-style="{ 'text-align': 'center' }"
          v-loading="imageServiceLoading"
          class="service-table">
          <el-table-column property="service_name" label="服务名称" min-width="35%" align="center"/>
          <el-table-column property="service_id" label="服务ID" min-width="35%" align="center">
            <template #default="scope">
              <el-link :underline="false" type="primary" @click="toServicePage(scope.row)">{{ scope.row.service_id }}</el-link>
            </template>
          </el-table-column>
          <el-table-column property="service_state" label="状态" min-width="30%" align="center">
            <template #default="scope">
              <el-tag :style="setStateStyle(scope.row.service_state)" round >{{ serviceStateDic[scope.row.service_state as keyof typeof serviceStateDic]}}</el-tag>
            </template>
          </el-table-column>
        </el-table>
        <template #footer>
          <span>
            <el-button @click="imageServiceDialog = false">确定</el-button>
          </span>
        </template>
      </el-dialog>

      <!--镜像整体删除的提示弹出框-->
      <el-dialog v-model="imageDeleteDialog" width="400px" class="confirm-dialog">
        <template #header>
          <div class="confirm-header">
            <el-icon size="20px" color="#ff4949"><WarningFilled /></el-icon>
            <span class="confirm-title">提示</span>
          </div>
        </template>
        <div class="confirm-content">
          当前镜像包含 <b>{{imageDeleteData.versionNum}}</b> 个版本，确定要删除吗？
        </div>
        <template #footer>
          <span>
            <el-button @click="imageDeleteDialog = false">取消</el-button>
            <el-button type="primary" @click="imageDeleteMethod">确定</el-button>
          </span>
        </template>
      </el-dialog>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, reactive, computed, watch, onMounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, FormInstance } from "element-plus"
import { UploadFilled, ArrowDown, WarningFilled, Refresh, ArrowRight, Picture, Search, Plus } from '@element-plus/icons-vue'
import { imageRepository } from "@/api/model"
import { algoFile, algoImage, algoService } from "@/api/algo"
import type { AlgoImagePushReq, AlgoMergeSliceReq, ID, ImageItem, ImageServiceItem, ImageVersionItem } from "@/api/types"
import md5 from 'js-md5'
import SparkMD5 from 'spark-md5'

const router = useRouter()
const route = useRoute()

// ======================== 基础数据 ========================
const pageIndex = ref(1)
const selectInputByImageName = ref('')
const selectInputByPublicImageName = ref('')
const myImageData = ref<ImageItem[]>([])
const publicImageData = ref<ImageItem[]>([])
const myImageLoading = ref(false)
const publicImageLoading = ref(false)
const modifyMyImageDialog = ref(false)
const formOfModifyMyImage = reactive<{ imageName?: string; imageDesc?: string; isPublic?: string }>({})
const formOfImageInfoImport = reactive<{ imageName: string; isPublic: string; imageDesc: string }>({ imageName: '', isPublic: '不公开', imageDesc: '' })
const formOfImageVersionImport = reactive<{ tag?: string; imageVersionDesc?: string }>({})
const uploadFile = ref<File | null>(null)
const importMyImageInfoDialog = ref(false)
const uploadFileDialog = ref(false)
const importMyImageVersionDialog = ref(false)
const uploadingDialog = ref(false)
const sliceSize = 10 * 1024 * 1024
const successUploadSliceDic = reactive<Record<string, number>>({})
const rules = {
  imageName: [{ required: true, message: '请输入镜像名称！', trigger: 'blur' }],
  tag: [{ required: true, message: '请输入版本号！', trigger: 'blur' }]
}
const completionDic = reactive<Record<string, number | string>>({})
const identifier = ref('')
const imageNameDic = reactive<Record<string, string>>({})
const imageIdDic = reactive<Record<string, ID>>({})
const imageTagDic = reactive<Record<string, string>>({})
const imageVersionDescDic = reactive<Record<string, string>>({})
const fileSizeDic = reactive<Record<string, number>>({})
const fileNameDic = reactive<Record<string, string>>({})
const publicImageOwner = ref(1)
const publicImageOwnerList = [
  { label: '显示所有公开镜像', value: 1 },
  { label: '显示当前用户公开镜像', value: 2 },
  { label: '显示其他用户公开镜像', value: 3 }
]
const currentImageName = ref('')
const currentImageId = ref('')
const imageStateDic = { 0: '未在使用', 1: '正在使用' }
const abortController = ref(new AbortController())
const imageServiceDialog = ref(false)
const imageServiceLoading = ref(false)
const imageDeleteDialog = ref(false)
const imageServiceData = ref<ImageServiceItem[]>([])
const imageDeleteData = reactive<{ currentImageId: string; versionNum: string }>({ currentImageId: '', versionNum: '' })
const imageUploadErr = ref(false)
const closeFlag = ref(false)
const uploadMessage = ref('')
const uploadingFlag = ref(true)
const serviceStateDic = {
  running: '运行中',
  stoped: '停止',
  exited: '停止',
  error: '异常',
  waiting: '等待资源',
  starting: '部署中',
}

// ref for form validation
const imageImportRef = ref<FormInstance>()
const imageVersionImportRef = ref<FormInstance>()
const uploadRef = ref()

// ======================== 计算属性与工具函数 ========================
// 获取所有镜像版本总数
function getTotalVersions(imageList: ImageItem[]) {
  let total = 0
  imageList.forEach(image => {
    if (image.version_num) {
      total += typeof image.version_num === 'string' ? parseInt(image.version_num) : image.version_num
    }
  })
  return total
}

// 获取使用中的镜像版本数
function getUsedImageVersions(imageList: ImageItem[]) {
  let usedCount = 0
  imageList.forEach(image => {
    if (image.image_version && image.image_version.length > 0) {
      image.image_version.forEach((version: ImageVersionItem) => {
        if (version.is_used === 1) {
          usedCount++
        }
      })
    }
  })
  return usedCount
}

// ======================== 业务方法 ========================
// 切换页面索引
function changePageIndex(param: number) {
  pageIndex.value = param
}

// 加载我的镜像
type ImageRepoQuery = Partial<ImageItem> & { image_name?: string; is_public?: number; image_version_id?: ID }

function loadMyImage(param?: ImageRepoQuery) {
  myImageLoading.value = true
  imageRepository.getImageRepositoryList(param ? param : {}).then(res => {
    myImageData.value = res.data
    myImageLoading.value = false
  })
}

// 加载公开镜像
function loadPublicImage(param?: ImageRepoQuery) {
  publicImageLoading.value = true
  imageRepository.getImageRepositoryList(param ? param : { is_public: 1 }).then(res => {
    publicImageData.value = res.data
    publicImageLoading.value = false
  })
}

// 根据镜像状态选择（占位函数）
function selectByImageState() {
  // 实现根据状态筛选的逻辑
}

// 打开镜像创建对话框
function openImageImportDialog() {
  importMyImageInfoDialog.value = true
  formOfImageInfoImport.imageName = ''
  formOfImageInfoImport.isPublic = '不公开'
  formOfImageInfoImport.imageDesc = ''
}

// 根据镜像名称模糊搜索
function selectByImageName() {
  let middle = { image_name: selectInputByImageName.value }
  loadMyImage(middle)
}

// 部署在线服务
function createOnlineService(image: ImageItem, imageVersion?: ImageVersionItem) {
  router.push({
    path: '/onlineServiceDeploy',
    query: {
      imageName: image.image_name,
      imageId: image.image_id,
      imageTag: imageVersion?.tag,
      imageVersionId: imageVersion?.image_version_id,
      deployMode: 'imageSpecific'
    }
  })
}

// 打开镜像版本对应的在线服务列表
function openServiceDialog(param: ImageVersionItem) {
  imageServiceDialog.value = true
  let middle = { image_version_id: param.image_version_id }
  imageRepository.getImageServiceList(middle).then(res => {
    imageServiceData.value = res.data
  })
}

// 打开修改镜像对话框（占位函数）
function openModifyImageDialog() {
  // 实现打开修改镜像对话框的逻辑
}

// 打开修改镜像版本对话框
function openModifyVersionDialog(param: ImageItem) {
  modifyMyImageDialog.value = true
  currentImageId.value = String(param.image_id)
  formOfModifyMyImage.imageName = param.image_name
  formOfModifyMyImage.imageDesc = param.image_desc
  formOfModifyMyImage.isPublic = param.is_public === 0 ? '不公开' : '公开'
}

// 修改镜像信息
function modifyMyImage() {
  let middle = {
    image_id: currentImageId.value,
    image_name: formOfModifyMyImage.imageName,
    image_desc: formOfModifyMyImage.imageDesc,
    is_public: formOfModifyMyImage.isPublic === '不公开' ? 0 : 1,
  }
  algoService.customModify(middle).then(() => {
    ElMessage({ message: '修改成功！', type: 'success', offset: 60 })
    modifyMyImageDialog.value = false
    loadMyImage()
  }).catch(() => {
    ElMessage({ message: '修改失败！', type: 'error', offset: 60 })
    modifyMyImageDialog.value = false
  })
}

// 删除镜像版本
function versionDeleteMethod(param: ImageVersionItem, slot: ImageItem) {
  let middle = { image_version_id: param.image_version_id }
  algoService.imageVersionDelete(middle).then(() => {
    ElMessage({ message: '删除成功！', type: 'success', offset: 60 })
    loadMyImage()
  }).catch(() => {
    ElMessage({ message: '删除失败！', type: 'error', offset: 60 })
  })
}

// 添加镜像版本
function addVersion(param: ImageItem) {
  importMyImageVersionDialog.value = true
  formOfImageVersionImport.tag = ''
  formOfImageVersionImport.imageVersionDesc = ''
  currentImageName.value = param.image_name
  currentImageId.value = String(param.image_id)
  nextTick(() => {
    if (uploadRef.value && uploadRef.value.clearFiles) {
      uploadRef.value.clearFiles()
    }
  })
  uploadFile.value = null
}

// 打开镜像删除提示框
function openImageDeleteDialog(param: ImageItem) {
  imageDeleteDialog.value = true
  imageDeleteData.currentImageId = String(param.image_id)
  imageDeleteData.versionNum = String(param.version_num ?? '')
}

// 镜像整体删除
function imageDeleteMethod() {
  let middle = { image_id: imageDeleteData.currentImageId }
  algoService.customDelete(middle).then(() => {
    ElMessage({ message: '删除成功！', type: 'success', offset: 60 })
    imageDeleteDialog.value = false
    imageDeleteData.currentImageId = ''
    imageDeleteData.versionNum = ''
    loadMyImage()
  }).catch(() => {
    imageDeleteDialog.value = false
    imageDeleteData.currentImageId = ''
    imageDeleteData.versionNum = ''
    ElMessage({ message: '删除失败！', type: 'error', offset: 60 })
  })
}

// 根据镜像拥有者筛选（占位函数）
function selectByImageOwner() {
  // 实现根据拥有者筛选的逻辑
}

// 根据公开镜像名称模糊搜索
function selectByPublicImageName() {
  let middle = {
    image_name: selectInputByPublicImageName.value,
    is_public: 1
  }
  loadPublicImage(middle)
}

// 取消上传
function cancelUpload() {
  uploadingDialog.value = false
  abortController.value.abort()
  algoFile.uploadCancel(JSON.stringify(identifier.value)).then(() => {
    // 通知后端取消上传成功
  }).catch(() => {
    // 通知后端取消上传失败
  })
}

// 创建镜像
async function importMyImageInfo() {
  if (!imageImportRef.value) return
  
  await imageImportRef.value.validate((valid: boolean) => {
    if (valid) {
      // 验证成功后调用创建镜像的接口
      let middle = {
        image_name: formOfImageInfoImport.imageName,
        image_desc: formOfImageInfoImport.imageDesc || '',
        is_public: formOfImageInfoImport.isPublic === '不公开' ? 0 : 1,
      }
      
      algoService.customSave(middle).then(() => {
        ElMessage({ message: '创建成功！', type: 'success', offset: 60 })
        importMyImageInfoDialog.value = false
        loadMyImage()
      }).catch(err => {
        if (err.response && err.response.status === 412) {
          ElMessage({ message: err.response.data.detail, type: 'error', offset: 60 })
        } else {
          importMyImageInfoDialog.value = false
          ElMessage({ message: '创建失败！', type: 'error', offset: 60 })
        }
      })
    } else {
      ElMessage({ message: '请完善服务信息！', type: 'error', offset: 60 })
    }
  })
}

// 文件切片处理
async function fileSlice() {
  if (!uploadFile.value) {
    ElMessage({ message: '请上传镜像文件！', type: 'error', offset: 60 })
    return
  }
  
  importMyImageVersionDialog.value = false
  uploadingFlag.value = true
  closeFlag.value = false
  uploadMessage.value = ''
  uploadingDialog.value = true
  ElMessage({ message: '开始上传!', type: 'success', offset: 60 })
  
  // 上传文件切片的数量
  const sliceNum = Math.ceil(uploadFile.value.size / sliceSize)
  await computeFileMd5(uploadFile.value, sliceNum)
  
  // 文件的唯一标识符
  const id = identifier.value
  imageNameDic[id] = currentImageName.value
  imageIdDic[id] = currentImageId.value
  imageTagDic[id] = formOfImageVersionImport.tag || ''
  imageVersionDescDic[id] = formOfImageVersionImport.imageVersionDesc || ''
  fileSizeDic[id] = uploadFile.value.size
  fileNameDic[id] = uploadFile.value.name
  
  successUploadSliceDic[id] = 0
  imageUploadErr.value = false
  abortController.value = new AbortController()
  uploadMessage.value += '\n正在上传文件切片...'
  
  for (let i = 1; i <= sliceNum; i++) {
    let chunk
    if (i === sliceNum) {
      chunk = uploadFile.value.slice((i - 1) * sliceSize, fileSizeDic[id])
    } else {
      chunk = uploadFile.value.slice((i - 1) * sliceSize, i * sliceSize)
    }
    
    const formData = new FormData()
    formData.append("file", chunk)
    formData.append("identifier", id)
    formData.append("number", String(i - 1))
    uploadFileInter(formData, sliceNum, id)
  }
  
  nextTick(() => {
    if (uploadRef.value && uploadRef.value.clearFiles) {
      uploadRef.value.clearFiles()
    }
  })
  uploadFile.value = null
}

// 新增版本确认
async function importMyImageVersion() {
  if (!imageVersionImportRef.value) return
  
  await imageVersionImportRef.value.validate((valid: boolean) => {
    if (valid) {
      imageRepository.judgeImageVersionRepeat({
        image_id: currentImageId.value,
        tag: formOfImageVersionImport.tag || ''
      }).then(res => {
        if (res.data.code === '1') {//weijiejuedewenti
          ElMessage({ message: '版本号重复！', type: 'error', offset: 60 })
        } else {
          fileSlice()
        }
      })
    } else {
      ElMessage({ message: '请根据提示修改完善信息！', type: 'error', offset: 60 })
    }
  })
}

// 分片上传文件
function uploadFileInter(data: FormData, sliceNum: number, id: string) {
  const middle = { signal: abortController.value.signal }
  
  algoFile.uploadSlice(data, abortController.value.signal).then(res => {
    if (res.data.code === 200) {
      successUploadSliceDic[id] += 1
      completionDic[id] = ((successUploadSliceDic[id] / sliceNum) * 100).toFixed(1)
      
      // 当前切片是文件的最后一个切片，发送合并切片请求
      if (successUploadSliceDic[id] === sliceNum) {
        uploadMessage.value += '\n切片上传完成！'
        const mergeData = {
          name: fileNameDic[id],
          total_slice: sliceNum,
          identifier: id
        }
        mergeSlice(mergeData, id)
      }
    }
  }).catch(err => {
    if (err.code === 'ERR_CANCELED') {
      // 请求已取消
    } else {
      abortController.value.abort() // 分片上传的接口出错，停止后续接口的上传
      imageUploadErr.value = true
    }
  })
}

// 合并切片
function mergeSlice(data: AlgoMergeSliceReq, id: string) {
  uploadingFlag.value = false
  uploadMessage.value += '\n合并文件中...'
  
  const middle = { signal: abortController.value.signal }
  
  algoFile.mergeSlice(data, abortController.value.signal).then(() => {
    uploadMessage.value += '\n合并文件成功！'
    pushImage(id)
  }).catch(() => {
    uploadMessage.value += '\n合并错误！'
    uploadingFlag.value = false
    closeFlag.value = true
  })
  
  successUploadSliceDic[id] = 0
}

// 将镜像push到harbor仓库
function pushImage(id: string) {
  uploadMessage.value += '\n正在推送文件至仓库...'
  
  const data: AlgoImagePushReq = {
    image_id: imageIdDic[id],
    image_name: imageNameDic[id],
    tag: imageTagDic[id],
    file_name: fileNameDic[id],
    desc: imageVersionDescDic[id] || '',
    md5: id
  }
  
  const middle = { signal: abortController.value.signal }
  
  algoImage.push(data, abortController.value.signal).then(() => {
    closeFlag.value = true
    uploadMessage.value += '\n文件推送成功！'
    uploadMessage.value += '\n上传成功！'
    loadMyImage()
  }).catch(() => {
    closeFlag.value = true
    uploadMessage.value += '\n文件推送失败！'
    uploadMessage.value += '\n上传失败！'
  })
}

// 处理导入文件
function importFile(file: { raw: File }) {
  identifier.value = ''
  uploadFile.value = file.raw
  completionDic[identifier.value] = 0
}

// 计算文件的MD5码
function computeFileMd5(file: File, chunkCount: number) {
  uploadMessage.value += '\n正在计算文件的MD5码'
  
  return new Promise<string>((resolve, reject) => {
    let blobSlice = File.prototype.slice
    let chunks = chunkCount
    let currentChunk = 0
    let spark = new SparkMD5.ArrayBuffer()
    let fileReader = new FileReader()
    
    fileReader.onload = function (e: ProgressEvent<FileReader>) {
      if (!e.target?.result) return
      spark.append(e.target.result as ArrayBuffer)
      currentChunk++
      
      if (currentChunk < chunks) {
        loadNext()
      } else {
        identifier.value = spark.end()
        completionDic[identifier.value] = 0
        resolve(identifier.value)
      }
    }
    
    fileReader.onerror = function (e) {
      closeFlag.value = true
      reject(e)
    }
    
    function loadNext() {
      let start = currentChunk * sliceSize
      let end = start + sliceSize
      
      if (end > file.size) {
        end = file.size
      }
      
      fileReader.readAsArrayBuffer(blobSlice.call(file, start, end))
    }
    
    loadNext()
  })
}

// 导入文件取消
function importFileCancel() {
  if (uploadRef.value && uploadRef.value.clearFiles) {
    uploadRef.value.clearFiles()
  }
  uploadFile.value = null
  uploadFileDialog.value = false
}

// 上传文件前的校验
function beforeUploadFile(file: File) {
  const suffix = file.name.split('.').pop()
  const trueOrFalse = (suffix === 'zip' || suffix === 'tar')
  
  if (!trueOrFalse) {
    ElMessage({ message: '文件格式不正确！', type: 'error', offset: 60 })
  }
  
  return trueOrFalse
}

// 跳转到服务页面
function toServicePage(param: ImageServiceItem) {
  router.push({ path: 'OnlineServiceList', query: { serviceId: param.service_id } })
}

// 设置状态样式
function setStateStyle(param: string) {
  if (param === '运行中' || param === 'running') {
    return { "background-color": "#409eff", "color": "white", "width": "80px" }
  } else if (param === '部署中' || param === 'starting') {
    return { "background-color": "#69B0E9", "color": "white", "width": "80px" }
  } else if (param === '停止' || param === 'stoped' || param === 'exited') {
    return { "background-color": "#E29194", "color": "white", "width": "80px" }
  } else if (param === '异常' || param === 'error') {
    return { "background-color": "#CD353B", "color": "white", "width": "80px" }
  } else if (param === '等待部署' || param === 'waiting') {
    return { "background-color": "#00CED1", "color": "white", "width": "80px" }
  }
  return {}
}

// ======================== 监听与生命周期 ========================
// 监听页面索引变化
watch(pageIndex, (newValue) => {
  if (newValue === 2) {
    loadPublicImage({ is_public: 1 })
  } else if (newValue === 1) {
    loadMyImage()
  }
}, { immediate: true })

// 监听上传错误状态
watch(imageUploadErr, (newValue, oldValue) => {
  if (!oldValue && newValue) {
    uploadMessage.value += '\n上传文件失败！'
    uploadingFlag.value = false
    closeFlag.value = true
  }
}, { deep: true })

// 组件挂载
onMounted(() => {
  if (route.query.imageVersionId) {
    let imageVersionId = route.query.imageVersionId as string
    let middle = { image_version_id: imageVersionId }
    loadMyImage(middle)
  } else {
    loadMyImage()
  }
})
</script>

<style scoped>
.image-repository {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.header-area {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 30px;
  background: linear-gradient(to right, #4c75a3, #4c75a3);
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
  text-shadow: 0px 1px 2px rgba(0, 0, 0, 0.2);
  color: #ffffff !important;
}

/* 面包屑内嵌套元素样式 */
:deep(.tech-title span),
:deep(.tech-title div),
:deep(.tech-title a) {
  color: #ffffff !important;
}

.tech-title .el-icon {
  font-size: 28px;
  color: #ffffff;
}

.image-metrics {
  display: flex;
  gap: 20px;
}

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

.content-panel {
  background-color: white;
  margin: 0 20px 20px;
  border-radius: 8px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.05);
  padding: 20px;
  min-height: calc(100vh - 210px);
}

.tab-container {
  margin-bottom: 20px;
}

.el-menu-m {
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 20px;
}

:deep(.el-menu-m .el-menu-item) {
  font-weight: 500;
  transition: all 0.3s ease;
}

:deep(.el-menu-m .el-menu-item.is-active) {
  background-color: rgba(76, 117, 163, 0.1);
  color: #4c75a3;
}

.action-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding: 15px 20px;
  background-color: #f9fafc;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.left-area, .right-area {
  display: flex;
  align-items: center;
  gap: 12px;
}

.middle-area {
  display: flex;
  align-items: center;
  flex-grow: 1;
  margin: 0 20px;
}

.create-btn {
  padding: 8px 16px;
  font-weight: 500;
}

.search-box {
  display: flex;
  flex-direction: column;
}

.search-input {
  width: 250px;
}

.refresh-btn {
  color: #4c75a3;
  background-color: rgba(76, 117, 163, 0.05);
  border-color: #4c75a3;
  padding: 8px 16px;
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 500;
  transition: all 0.3s;
}

.refresh-btn:hover {
  background-color: rgba(76, 117, 163, 0.15);
  transform: translateY(-2px);
  box-shadow: 0 3px 8px rgba(76, 117, 163, 0.2);
}

.refresh-icon {
  font-size: 16px;
  transition: transform 0.6s ease;
}

/* 添加点击动画效果 */
.refresh-btn:active .refresh-icon {
  transform: rotate(360deg);
}

/* 加载中的动画效果 */
.refresh-icon.is-loading {
  animation: spin 1.2s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.table-container {
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  margin-bottom: 25px;
}

.image-table {
  width: 100%;
}

/* 表格行悬停效果 */
:deep(.el-table__row) {
  transition: all 0.2s;
}

:deep(.el-table__row:hover) {
  background-color: #f0f8ff !important;
  transform: translateY(-2px);
  box-shadow: 0 5px 10px rgba(0, 0, 0, 0.03);
}

.action-buttons {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
}

.action-btn {
  padding: 6px 12px;
  font-size: 13px;
}

.action-dropdown {
  margin: 0 8px;
}

.el-dropdown-link {
  cursor: pointer;
  color: var(--el-color-primary);
  display: flex;
  align-items: center;
}

.version-table {
  border-radius: 4px;
  overflow: hidden;
}

/* 拥有者单元格样式 */
.owner-cell {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
}

/* 上传进度对话框样式 */
.upload-progress-container {
  display: flex;
  align-items: center;
  padding: 20px;
}

.progress-chart {
  flex: 0 0 auto;
}

.progress-message {
  flex: 1;
  margin-left: 20px;
  white-space: pre-line;
  line-height: 1.5;
  max-height: 150px;
  overflow-y: auto;
}

.percentage-value {
  display: block;
  margin-top: 10px;
  font-size: 28px;
  font-weight: bold;
}

.percentage-label {
  display: block;
  margin-top: 10px;
  font-size: 12px;
  color: #606266;
}

/* 删除确认对话框 */
.confirm-header {
  display: flex;
  align-items: center;
  gap: 10px;
}

.confirm-title {
  font-size: 18px;
  color: #ff4949;
  font-weight: bold;
}

.confirm-content {
  margin: 20px 10px;
  text-align: center;
  font-size: 16px;
}

/* 对话框样式统一 */
.image-dialog, .upload-dialog, .uploading-dialog, .confirm-dialog {
  border-radius: 8px;
  overflow: hidden;
}

:deep(.el-dialog__header) {
  background-color: #f5f7fa;
  margin-right: 0;
  border-bottom: 1px solid #e4e7ed;
  padding: 15px 20px;
}

:deep(.el-dialog__body) {
  padding: 20px;
}

:deep(.el-dialog__footer) {
  padding: 10px 20px 20px;
  border-top: 1px solid #f0f0f0;
}

:deep(.el-tag) {
  padding: 4px 12px;
  border-radius: 12px;
  font-weight: 500;
}

/* 上传组件样式 */
:deep(.el-upload-dragger) {
  border: 2px dashed #4c75a3;
  transition: all 0.3s;
}

:deep(.el-upload-dragger:hover) {
  border-color: #409EFF;
  background-color: rgba(64, 158, 255, 0.05);
}

:deep(.el-icon--upload) {
  font-size: 48px;
  color: #4c75a3;
  margin-bottom: 10px;
}

:deep(.el-upload__text) {
  color: #606266;
  font-size: 14px;
  margin-top: 10px;
}

:deep(.el-upload__text em) {
  color: #4c75a3;
  font-style: normal;
  font-weight: 600;
}
/* 修改镜像创建按钮样式，与DataScreen保持一致 */
.create-btn {
  background: linear-gradient(to right, #1a2942, #2a476e);
  border: none;
  border-radius: 6px;
  transition: all 0.3s;
  padding: 8px 16px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 6px;
}

.create-btn:hover {
  background: linear-gradient(to right, #2a476e, #1a2942);
  transform: translateY(-1px);
  box-shadow: 0 5px 15px rgba(26, 41, 66, 0.2);
}

.create-btn .el-icon {
  font-size: 16px;
  margin-right: 4px;
}

/* 确保按钮文字为白色 */
:deep(.create-btn span) {
  color: #ffffff;
}
/* 弹窗样式统一优化 */
:deep(.el-dialog) {
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
}

:deep(.el-dialog__header) {
  position: relative;
  background: linear-gradient(to right, #1a2942, #4c75a3);
  padding: 16px 20px;
  margin-right: 0;
  border-bottom: 1px solid #eaeaea;
  display: flex;
  align-items: center;
}

:deep(.el-dialog__title) {
  color: white;
  font-size: 18px;
  font-weight: 600;
}

:deep(.el-dialog__headerbtn) {
  position: absolute;
  top: 50%;
  right: 20px;
  transform: translateY(-50%);
  width: 28px;
  height: 28px;
  background: rgba(255, 255, 255, 0.2);
  border: 2px solid rgba(255, 255, 255, 0.5);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  transition: all 0.3s;
  z-index: 10;
}

:deep(.el-dialog__headerbtn .el-dialog__close) {
  color: white;
  font-size: 16px;
  font-weight: bold;
}

:deep(.el-dialog__headerbtn:hover) {
  background: rgba(255, 255, 255, 0.35);
  border-color: white;
  transform: translateY(-50%) scale(1.1);
  box-shadow: 0 0 10px rgba(255, 255, 255, 0.5);
}

:deep(.el-dialog__headerbtn:hover .el-dialog__close) {
  color: white;
}

:deep(.el-dialog__body) {
  padding: 24px 30px;
  background-color: #ffffff;
}

:deep(.el-dialog__footer) {
  padding: 12px 30px 20px;
  border-top: 1px solid #f0f0f0;
  background-color: #fbfbfb;
}

/* 表单项样式优化 */
:deep(.el-form-item__label) {
  font-weight: 500;
  color: #1a2942;
}

:deep(.el-input__inner) {
  border-radius: 4px;
  transition: all 0.3s;
}

:deep(.el-input__inner:hover) {
  border-color: #4c75a3;
}

:deep(.el-input__inner:focus) {
  border-color: #1a2942;
  box-shadow: 0 0 0 2px rgba(26, 41, 66, 0.2);
}

:deep(.el-textarea__inner) {
  border-radius: 4px;
  transition: all 0.3s;
}

:deep(.el-textarea__inner:hover) {
  border-color: #4c75a3;
}

:deep(.el-textarea__inner:focus) {
  border-color: #1a2942;
  box-shadow: 0 0 0 2px rgba(26, 41, 66, 0.2);
}

/* 镜像修改对话框 */
.image-dialog {
  min-width: 400px;
}

/* 上传文件对话框 */
.upload-dialog :deep(.el-upload-dragger) {
  border: 2px dashed #4c75a3;
  background-color: #f8fafc;
  border-radius: 8px;
  transition: all 0.3s;
}

.upload-dialog :deep(.el-upload-dragger:hover) {
  border-color: #1a2942;
  background-color: #f0f7ff;
  transform: translateY(-2px);
}

.upload-dialog :deep(.el-upload__text) {
  color: #606266;
  margin-top: 12px;
}

.upload-dialog :deep(.el-upload__text em) {
  color: #4c75a3;
  font-style: normal;
  font-weight: 600;
}

.upload-dialog :deep(.el-upload__tip) {
  color: #909399;
  font-size: 13px;
  margin-top: 10px;
}

/* 上传进度对话框 */
.uploading-dialog .upload-progress-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 20px 10px;
}

.uploading-dialog .progress-chart {
  margin-bottom: 20px;
}

.uploading-dialog .progress-message {
  padding: 15px;
  background-color: #f8fafc;
  border-radius: 8px;
  border: 1px solid #e0e7ee;
  width: 100%;
  min-height: 100px;
  max-height: 150px;
  overflow-y: auto;
  font-family: monospace;
  white-space: pre-line;
  line-height: 1.6;
  color: #303133;
}

/* 确认删除对话框 */
.confirm-dialog .confirm-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 0;
}

.confirm-dialog .confirm-title {
  font-size: 18px;
  font-weight: 600;
  color: #f56c6c;
}

.confirm-dialog .confirm-content {
  padding: 20px;
  text-align: center;
  font-size: 15px;
  line-height: 1.8;
  color: #606266;
  background-color: rgba(245, 108, 108, 0.05);
  border-radius: 6px;
  margin: 10px 0 20px;
}

.confirm-dialog .confirm-content b {
  color: #f56c6c;
  padding: 0 3px;
  font-size: 17px;
}

/* 服务列表对话框 */
.image-service-dialog .service-table {
  border-radius: 4px;
  overflow: hidden;
}

/* 按钮样式优化 */
:deep(.el-dialog__footer .el-button--default) {
  border-color: #d9d9d9;
  background: white;
  font-weight: 500;
  transition: all 0.3s;
}

:deep(.el-dialog__footer .el-button--default:hover) {
  border-color: #c0c4cc;
  background-color: #f5f7fa;
  transform: translateY(-1px);
}

:deep(.el-dialog__footer .el-button--primary) {
  background: linear-gradient(to right, #1a2942, #4c75a3);
  border: none;
  font-weight: 500;
  transition: all 0.3s;
}

:deep(.el-dialog__footer .el-button--primary:hover) {
  opacity: 0.9;
  transform: translateY(-1px);
  box-shadow: 0 3px 8px rgba(26, 41, 66, 0.2);
}
</style>
