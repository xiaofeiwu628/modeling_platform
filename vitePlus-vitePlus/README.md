# 智能中台建模平台

<div align="center">
  <img src="public/page-logo.png" alt="建模平台标志" width="120">
  <h3>基于Vue 3 + TypeScript + Vite + Pinia的智能建模平台前端</h3>
  <p>高性能 | 类型安全 | 组件化 | 易于维护</p>
</div>

## 📖 项目介绍

智能中台建模平台是一个面向数据科学家和工程师的综合性模型管理系统，用于创建、部署、监控和管理机器学习模型。平台提供了从数据处理到模型部署的全流程支持，具有直观的用户界面，强大的数据可视化能力和灵活的模型管理功能。

**核心功能:**
- 📊 模型开发与训练管理
- 🚀 一键模型部署与发布
- 📈 在线服务性能监控
- 🔄 模型版本控制与回滚
- 🧩 多种算法支持与组件化开发
- 📱 响应式设计适配多种设备
  
## 📦 构建优化

为确保生产部署的性能，项目采用了以下构建优化策略：

### 代码分割

- 将应用代码按功能模块分割为多个小块，减少首屏加载时间
- 第三方库（Vue、Element Plus、ECharts等）单独打包，利用浏览器缓存
- 路由组件懒加载，实现按需加载页面组件

### 资源优化

- 图片资源自动压缩并转换为最优格式
- 静态资源按类型分类存储，便于缓存管理
- 生产环境自动开启 GZIP 压缩

### 性能考量

- 移除生产环境的 console 和 debugger
- 源码地图(sourcemap)仅在开发环境生成
- Tree-shaking 移除未使用的代码

### 自定义构建配置

如需自定义构建配置，请修改 `vite.config.ts` 文件中的 `build.rollupOptions`。

## ⚡ 技术栈升级

### 从 Vue CLI 迁移到 Vite

项目已从 Vue CLI 迁移至 Vite，带来以下优势:

- ⚡ 极速的开发服务器启动和即时热更新
- 📦 优化的构建过程，更快的生产构建速度
- 🔧 更简洁直观的配置系统
- 🔄 原生 ESM 支持，无需打包即可开发
- 🛠️ 丰富的插件生态和扩展性
- 📝 更好的TypeScript集成和类型检查

### Vue 3 + TypeScript + 组合式API重构

重构内容包括:

- 🔄 将Vue 2 选项式API重构为Vue 3组合式API，提高代码可复用性和维护性
- 📝 全面采用TypeScript增强类型安全
- 🔄 Vuex替换为Pinia实现更加灵活的状态管理
- 🎨 UI组件库升级至Element Plus
- 🧩 采用更模块化的代码组织方式

## 🚀 运行与部署

### 前置要求

- Node.js >= 16.0.0
- npm >= 8.0.0

### 环境配置

项目使用环境变量进行配置，下表是环境变量清单:

| 环境变量名             | 类型   | 用途                 | 示例值                       |
| ---------------------- | ------ | -------------------- | ---------------------------- |
| VITE_APP_TITLE         | string | 应用标题             | 智能中台建模平台             |
| VITE_API_BASE_URL      | string | API请求基础路径      | /api                         |
| VITE_PYANALYSIS_URL    | string | Python分析服务路径   | /pyanalysis                  |
| VITE_BEFORE_URL        | string | FastAPI 主节点路径   | /api/algo                    |
| VITE_BASE_URL          | string | 路由基础路径         | /                            |
| VITE_DEBUG             | string | 是否开启调试         | true/false                   |
| VITE_API_TARGET        | string | API代理目标（应指向 Gateway） | http://172.18.129.239:8080  |
| VITE_PYANALYSIS_TARGET | string | Python分析服务代理目标 | http://172.18.129.239:8086 |

### 安装依赖

```bash
npm install
```

### 开发环境运行

```bash
npm run dev
```

### 生产环境构建

```bash
npm run build
```

### 预览构建结果

```bash
npm run preview
```

## 📁 项目结构

```
modeling-platform-frontend/
├── public/                 # 静态资源
│   ├── page-logo.png       # 应用图标
│   └── ...                 # 其他静态资源
├── src/                    # 源代码
│   ├── assets/             # 项目资源文件
│   │   ├── css/            # 全局CSS
│   │   └── images/         # 图片资源
│   ├── components/         # 全局通用组件
│   │   ├── Header/         # 页头组件
│   │   ├── Sidebar/        # 侧边栏组件
│   │   ├── MyChart/        # 图表组件
│   │   └── ...             # 其他组件
│   ├── hooks/              # 可复用的组合式API钩子
│   │   ├── useForm.ts      # 表单处理钩子
│   │   ├── useChart.ts     # 图表处理钩子
│   │   └── ...             # 其他钩子
│   ├── router/             # 路由配置
│   │   └── index.ts        # 路由定义
│   ├── store/              # Pinia状态管理
│   │   ├── modules/        # 按模块组织的状态
│   │   └── index.ts        # 状态存储入口文件
│   ├── utils/              # 工具函数
│   │   ├── request.ts      # API请求封装
│   │   ├── before.ts       # 前置处理工具
│   │   └── ...             # 其他工具
│   ├── views/              # 页面组件
│   │   ├── Login/          # 登录页面
│   │   ├── Dashboard/      # 仪表盘页面
│   │   ├── ImageRepository/# 镜像仓库页面
│   │   ├── OnlineService/  # 在线服务页面
│   │   └── ...             # 其他页面
│   ├── App.vue             # 根组件
│   ├── main.ts             # 应用入口
│   └── vite-env.d.ts       # Vite环境类型声明
├── .env                    # 基本环境变量
├── .env.development        # 开发环境变量
├── .env.production         # 生产环境变量
├── index.html              # HTML入口文件
├── tsconfig.json           # TypeScript配置
├── tsconfig.node.json      # Node.js TypeScript配置
├── vite.config.ts          # Vite配置文件
├── package.json            # 项目依赖和脚本
└── README.md               # 项目说明文档
```

## 📄 主要文件说明

### 配置文件
- **vite.config.ts**: Vite构建工具配置，包含插件、代理、环境变量设置等
- **tsconfig.json**: TypeScript编译配置，定义代码规范和编译选项
- **package.json**: 项目依赖和npm脚本定义

### 核心源码
- **main.ts**: 应用入口，初始化Vue实例、路由、状态管理等
- **App.vue**: 根组件，定义应用的基本布局和全局状态
- **index.ts**: 路由配置，定义应用的页面导航结构
- **request.ts**: API请求封装，基于Axios的HTTP客户端
- **index.ts**: Pinia状态管理入口，组织全局状态

### 业务模块
- **src/views/**: 包含所有页面组件，每个页面对应一个文件夹
- **src/components/**: 包含可复用的UI组件
- **src/hooks/**: 包含可复用的组合式API钩子函数

## 🛠️ 开发规范

### 代码风格
- 使用TypeScript强类型
- 组件使用Vue 3组合式API
- 文件命名采用PascalCase(组件)或camelCase(非组件)
- CSS使用scoped样式，避免全局污染

### 状态管理
- 使用Pinia进行状态管理
- 按模块组织状态，保持状态树结构清晰
- 避免过度使用全局状态，优先考虑组件内状态或props传递

### API请求
- 所有API请求通过utils/request.ts进行封装
- 使用环境变量控制API路径和基础URL
- 实现请求拦截器进行统一的错误处理和认证

## 📚 其他资源

- [Vue 3文档](https://cn.vuejs.org/)
- [Vite文档](https://cn.vitejs.dev/)
- [TypeScript文档](https://www.typescriptlang.org/zh/)
- [Pinia文档](https://pinia.vuejs.org/zh/)
- [Element Plus文档](https://element-plus.org/zh-CN/)

## 🙏 致谢

感谢所有为此项目做出贡献的开发者

