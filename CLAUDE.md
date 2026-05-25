# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

智能中台建模平台前端项目。仓库根目录只包含前端代码（`vitePlus-vitePlus/`）和 PostgreSQL 初始化脚本（`postgres/init/`）。后端微服务（SpringBoot + FastAPI + Python）在另一仓库 `model-backend/` 中，本机未检出。

## 常用命令

所有命令需在 `vitePlus-vitePlus/` 目录下执行：

```bash
cd vitePlus-vitePlus
npm run dev          # 启动开发服务器，端口 9877
npm run build        # 生产构建，输出到 dist/
npm run preview      # 预览生产构建
npm run type-check   # TypeScript 类型检查
```

## 技术栈

Vue 3（组合式 API）+ TypeScript + Vite 6 + Pinia + Element Plus 2 + ECharts 5

## 架构要点

### 三个后端端点

前端通过 Vite 代理访问三个独立的后端，对应 `src/api/http.ts` 中三个 Axios 实例：

| 实例 | 代理前缀 | 目标 | 用途 |
|------|---------|------|------|
| `spring` | `/api` | Gateway:8080 | SpringBoot 微服务（auth、data、model、task、graph） |
| `algo` | `/api/algo` | FastAPI:8090 | 建模任务调度 |
| `pyanalysis` | `/pyanalysis` | Python:8086 | 数据分析 |

### 路由认证守卫（`src/router/index.ts`）

- 设置 `VITE_SKIP_AUTH=true`（`.env.development`）可跳过认证校验，无需后端即可预览前端页面
- 联调后端时改为 `false`

### 样式主题

已从蓝色系全面切换为红色系。Element Plus 主色在 `global.css` 通过 `:root` CSS 变量覆盖：

```css
--el-color-primary: #d32f2f;
--el-color-primary-dark-2: #a82525;
```

各业务页面的表格表头、按钮、链接等也分别替换了硬编码色值（`#1a2942` → `#a82525`，`#4c75a3` → `#d32f2f`）。后续修改样式时继续使用红色系保持一致性。

### API 层约定

- `src/api/` 下每个文件对应一个后端服务模块
- 请求通过 `src/utils/request.ts` 中的 Axios 实例，拦截器自动携带 Token（从 localStorage 读取双 key：`Token` 和 `token`）
- 后端返回统一格式 `Result<T>`（`{ code: string, data: T, msg: string }`），`code === '0'` 表示成功
- 401 时自动清除 token 并跳转登录页
