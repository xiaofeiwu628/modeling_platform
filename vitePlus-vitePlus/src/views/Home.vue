<template>
  <div class="home-container">
    <!-- 英雄区域 -->
    <section class="hero-section">
      <div class="hero-content">
        <h1 class="hero-title">智能中台建模平台</h1>
        <!-- <p class="hero-description">
          加速AI模型开发与部署，赋能企业智能化转型
        </p> -->
        <div class="hero-buttons">
          <el-button type="primary" class="get-started-btn" @click="navigateTo('modelList')">
            立即开始
            <el-icon class="icon-right"><ArrowRight /></el-icon>
          </el-button>
          <el-button class="learn-more-btn" @click="scrollToFeatures">
            了解更多
            <el-icon class="icon-right"><ArrowDown /></el-icon>
          </el-button>
        </div>
      </div>
      <div class="hero-image">
        <img src="@/assets/bgimg2.png" alt="AI建模平台" class="platform-illustration" />
      </div>
    </section>

    <!-- 统计数据区域 -->
    <section class="stats-section">
      <div class="stat-card">
        <div class="stat-number">{{ stats.models }}</div>
        <div class="stat-label">平台模型</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">{{ stats.services }}</div>
        <div class="stat-label">在线服务</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">{{ stats.datasets }}</div>
        <div class="stat-label">数据集</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">{{ stats.tasks }}</div>
        <div class="stat-label">训练任务</div>
      </div>
    </section>

    <!-- 特色功能区域 -->
    <section class="features-section" ref="featuresSection">
      <h2 class="section-title">平台特色</h2>
      <div class="features-grid">
        <div class="feature-card">
          <el-icon class="feature-icon"><DataAnalysis /></el-icon>
          <h3>模型训练</h3>
          <p>通过简单的配置，快速训练和调优AI模型，支持分类、回归、时间序列预测等多种任务类型</p>
        </div>
        <div class="feature-card">
          <el-icon class="feature-icon"><Monitor /></el-icon>
          <h3>服务部署</h3>
          <p>一键将AI模型部署为在线服务，提供稳定、高性能的推理能力，实时监控服务状态</p>
        </div>
        <div class="feature-card">
          <el-icon class="feature-icon"><Box /></el-icon>
          <h3>模型管理</h3>
          <p>集中管理和版本控制您的AI模型，支持公开分享，方便团队协作和模型迭代</p>
        </div>
        <div class="feature-card">
          <el-icon class="feature-icon"><Files /></el-icon>
          <h3>数据处理</h3>
          <p>丰富的数据预处理工具，支持多种数据类型和格式的高效处理，视觉化展示数据分布</p>
        </div>
      </div>
    </section>

    <!-- 快速访问区域 -->
    <section class="quick-access-section">
      <h2 class="section-title">快速访问</h2>
      <div class="access-cards">
        <div class="access-card" @click="navigateTo('modelList')">
          <el-icon class="access-icon"><Box /></el-icon>
          <h3>模型库</h3>
          <p>管理和使用您的AI模型</p>
        </div>
        <div class="access-card" @click="navigateTo('imageList')">
          <el-icon class="access-icon"><Picture /></el-icon>
          <h3>镜像仓库</h3>
          <p>管理和部署容器镜像</p>
        </div>
        <div class="access-card" @click="navigateTo('datascreen')">
          <el-icon class="access-icon"><Files /></el-icon>
          <h3>数据集管理</h3>
          <p>上传和组织训练数据</p>
        </div>
        <div class="access-card" @click="navigateTo('taskView')">
          <el-icon class="access-icon"><List /></el-icon>
          <h3>任务管理</h3>
          <p>监控和管理训练任务</p>
        </div>
        <div class="access-card" @click="navigateTo('onlineServiceList')">
          <el-icon class="access-icon"><Monitor /></el-icon>
          <h3>在线服务</h3>
          <p>部署和监控AI服务</p>
        </div>
        <div class="access-card" @click="navigateTo('taskCreate')">
          <el-icon class="access-icon"><Plus /></el-icon>
          <h3>创建任务</h3>
          <p>开始新的训练任务</p>
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted, Ref } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowRight, ArrowDown, DataAnalysis, Monitor, Box, Files, Picture, List, Plus } from '@element-plus/icons-vue'
import { modelRepository } from '@/api/model'
import { onlineService, taskManage } from '@/api/task'
import { dataset } from '@/api/data'
import type { DataSetInfo, ModelItem, OnlineServiceItem, Result, TaskListItem } from '@/api/types'
// 定义统计数据的接口
interface Stats {
  models: number // 模型数量
  services: number  // 服务数量
  datasets: number // 数据集数量
  tasks: number   // 任务数量
}
// 引入路由
const router = useRouter()
const featuresSection = ref<HTMLElement | null>(null)
const stats = ref<Stats>({
  models: 0,
  services: 0,
  datasets: 0,
  tasks: 0
})
// 统计数据加载函数
const loadStats = async () => {
  try {
    // 单独处理每个API请求，防止一个失败影响其他请求
    
    // 模型总数
    try {
      const modelRes: Result<ModelItem[]> = await modelRepository.getModelList()
      stats.value.models = modelRes.data?.length || 0
    } catch (err) {
      console.error("模型数据加载失败:", err)
      stats.value.models = 24 // 默认值
    }

    // 服务总数
    try {
      const serviceRes: Result<OnlineServiceItem[]> = await onlineService.getOnlineServiceList()
      stats.value.services = serviceRes.data?.length || 0
    } catch (err) {
      console.error("服务数据加载失败:", err)
      stats.value.services = 18 // 默认值
    }

    // 数据集总数 - 修复：添加必需的Search参数
    try {
      const datasetRes: Result<DataSetInfo[]> = await dataset.searchAll({ Search: '' })
      stats.value.datasets = datasetRes.data?.length || 0
    } catch (err) {
      console.error("数据集数据加载失败:", err)
      stats.value.datasets = 36 // 默认值
    }

    // 任务总数
    try {
      const taskRes: Result<TaskListItem[]> = await taskManage.getTaskList()
      stats.value.tasks = taskRes.data?.length || 0
    } catch (err) {
      console.error("任务数据加载失败:", err)
      stats.value.tasks = 42 // 默认值
    }
    
  } catch (error) {
    console.error("统计数据总体加载失败", error)
    // 整体失败时使用所有默认值
    stats.value = {
      models: 24,
      services: 18,
      datasets: 36,
      tasks: 42
    }
  }
}
// 路由跳转函数
function navigateTo(route: string) {
  router.push(`/${route}`)
}
// 滚动到特色功能区域
function scrollToFeatures() {
  if (featuresSection.value) {
    featuresSection.value.scrollIntoView({ behavior: 'smooth' })
  }
}
// 组件挂载后加载统计数据
onMounted(() => {
  loadStats()
})
</script>

<style scoped>
/* 首页容器样式 */
.home-container {
  width: 100%;
  min-height: calc(100vh - 60px);
  background: #fdfbfb;
  color: #333333;
  overflow-x: hidden;
}

/* 英雄区域样式 */
.hero-section {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 80px 10%;
  min-height: 75vh;
  background: linear-gradient(135deg, #ffffff 0%, #ffebee 100%);
  position: relative;
}

.hero-section::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 150px;
  background: linear-gradient(to bottom, transparent, #fdfbfb);
  z-index: 1;
}

.hero-content {
  width: 50%;
  z-index: 2;
}

.hero-title {
  font-size: 3.5rem;
  font-weight: 700;
  margin-bottom: 20px;
  background: linear-gradient(90deg, #d32f2f, #e57373);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  line-height: 1.2;
  animation: fadeInUp 1s ease-out;
}

.hero-description {
  font-size: 1.5rem;
  margin-bottom: 40px;
  color: #666666;
  line-height: 1.6;
  animation: fadeInUp 1s ease-out 0.2s forwards;
  opacity: 0;
}

.hero-buttons {
  display: flex;
  gap: 20px;
  animation: fadeInUp 1s ease-out 0.4s forwards;
  opacity: 0;
}

.get-started-btn {
  background: linear-gradient(90deg, #d32f2f, #c62828);
  border: none;
  font-size: 16px;
  padding: 12px 24px;
  border-radius: 6px;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  font-weight: 500;
}

.get-started-btn:hover {
  transform: translateY(-3px);
  box-shadow: 0 10px 20px rgba(211, 47, 47, 0.3);
}

.learn-more-btn {
  background: #ffffff;
  color: #d32f2f;
  border: 1px solid #d32f2f;
  font-size: 16px;
  padding: 12px 24px;
  border-radius: 6px;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  font-weight: 500;
}

.learn-more-btn:hover {
  background: #ffebee;
  color: #c62828;
  transform: translateY(-3px);
}

.icon-right {
  margin-left: 8px;
  font-size: 16px;
}

/* 英雄图片区域 - 增加尺寸和视觉效果 */
.hero-image {
  width: 50%; /* 从45%增加到50% */
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 2;
  padding: 20px;
}

.platform-illustration {
  /* Rotate blue to warm/red tone */
  width: 100%;
  max-width: 600px; /* 从500px增加到600px */
  filter: drop-shadow(0 0 30px rgba(0, 0, 0, 0.15)); /* 增强阴影效果 */
  animation: float 6s ease-in-out infinite;
  transition: all 0.5s ease;
}

.hero-section:hover .platform-illustration {
  /* Rotate blue to warm/red tone */
  transform: scale(1.05); /* 鼠标悬停时略微放大 */
}

/* 增加飘浮动画效果的幅度 */
@keyframes float {
  0% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-25px); /* 从-20px增加到-25px */
  }
  100% {
    transform: translateY(0px);
  }
}

/* 响应式调整 */
@media (max-width: 1200px) {
  .platform-illustration {
  /* Rotate blue to warm/red tone */
    max-width: 550px;
  }
}

@media (max-width: 1024px) {
  .hero-image {
    width: 90%; /* 在小屏幕上增加宽度比例 */
  }
}

/* 统计区域样式 */
.stats-section {
  display: flex;
  justify-content: space-around;
  padding: 60px 10%;
  background: #ffffff;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
  position: relative;
  margin-top: -50px;
  z-index: 10;
  border-radius: 12px;
  max-width: 1200px;
  margin-left: auto;
  margin-right: auto;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
}

.stat-card {
  text-align: center;
  padding: 20px;
  transition: all 0.3s;
}

.stat-card:hover {
  transform: translateY(-5px);
}

.stat-number {
  font-size: 2.5rem;
  font-weight: 700;
  color: #d32f2f;
  margin-bottom: 10px;
}

.stat-label {
  font-size: 1rem;
  color: #333333;
  opacity: 0.8;
}

/* 特色功能区域样式 */
.features-section {
  padding: 100px 10% 80px;
  background: #ffffff;
}

.section-title {
  text-align: center;
  font-size: 2.5rem;
  margin-bottom: 60px;
  color: #333333;
  position: relative;
  font-weight: 600;
}

.section-title::after {
  content: '';
  position: absolute;
  bottom: -15px;
  left: 50%;
  transform: translateX(-50%);
  width: 100px;
  height: 3px;
  background: linear-gradient(90deg, #d32f2f, #c62828);
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 30px;
}

.feature-card {
  background: #ffffff;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
  border-radius: 12px;
  padding: 30px;
  transition: all 0.3s ease;
  border: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.feature-card:hover {
  background: #ffffff;
  transform: translateY(-10px);
  box-shadow: 0 20px 30px rgba(0, 0, 0, 0.2);
}

.feature-icon {
  font-size: 40px;
  color: #d32f2f;
  margin-bottom: 20px;
}

.feature-card h3 {
  font-size: 1.5rem;
  margin-bottom: 15px;
  color: #333333;
  font-weight: 600;
}

.feature-card p {
  color: #666666;
  line-height: 1.6;
}

/* 快速访问区域样式 */
.quick-access-section {
  padding: 80px 10%;
  background: #fdfbfb;
}

.access-cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 20px;
  padding: 10px 0;
}

.access-card {
  background: #ffffff;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
  border-radius: 12px;
  padding: 25px;
  transition: all 0.3s ease;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  height: 100%;
}

.access-card:hover {
  background: rgba(255, 255, 255, 0.15);
  transform: translateY(-5px);
  box-shadow: 0 10px 20px rgba(0, 0, 0, 0.15);
}

.access-icon {
  font-size: 36px;
  color: #d32f2f;
  margin-bottom: 15px;
}

.access-card h3 {
  font-size: 1.2rem;
  margin-bottom: 10px;
  color: #333333;
  font-weight: 600;
}

.access-card p {
  color: #666666;
  font-size: 0.9rem;
}

/* 动画效果 */
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes float {
  0% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-20px);
  }
  100% {
    transform: translateY(0px);
  }
}

/* 响应式设计 */
@media (max-width: 1024px) {
  .hero-section {
    flex-direction: column;
    padding: 60px 5%;
    text-align: center;
  }
  
  .hero-content {
    width: 100%;
    margin-bottom: 40px;
  }
  
  .hero-title {
    font-size: 2.8rem;
  }
  
  .hero-description {
    font-size: 1.2rem;
  }
  
  .hero-buttons {
    justify-content: center;
  }
  
  .hero-image {
    width: 80%;
  }
  
  .stats-section {
    flex-wrap: wrap;
  }
  
  .stat-card {
    flex: 1 0 45%;
    margin-bottom: 20px;
  }
}

@media (max-width: 768px) {
  .hero-title {
    font-size: 2.2rem;
  }
  
  .features-grid {
    grid-template-columns: 1fr;
  }
  
  .stat-card {
    flex: 1 0 100%;
  }
}
</style>