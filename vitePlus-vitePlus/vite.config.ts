import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueJsx from '@vitejs/plugin-vue-jsx'
import { fileURLToPath, URL } from 'url'
import path from 'path'
import legacy from '@vitejs/plugin-legacy'
import { createSvgIconsPlugin } from 'vite-plugin-svg-icons'

// 获取当前环境模式
export default defineConfig(({ command, mode }) => {
  // 加载环境变量
  const env = loadEnv(mode, process.cwd())

  // 判断是否为生产环境
  const isProduction = mode === 'production'

  // env 缺失时提供默认值（当前仓库内没有 .env* 文件）
  /**
   * IMPORTANT:
   * - `/api` 代理目标应当是 **Gateway**（默认 8080），而不是某个具体微服务（如 auth-service:8081）。
   *   否则前端请求 `/auth/**` 不会被 StripPrefix，后端会进入 LoginInterceptor 并提示“访问时参数要携带Token”。
   */
  const rawApiTarget = env.VITE_API_TARGET || 'http://localhost:8080'
  const rawPyTarget = env.VITE_PYANALYSIS_TARGET || 'http://localhost:8086'
  const onlineServiceTarget = env.VITE_ONLINE_SERVICE_TARGET || 'http://localhost:8002'

  // Heuristic auto-fix for legacy docs that pointed API_TARGET to auth-service:8081
  const apiTarget = rawApiTarget.replace(/:8081(\/|$)/, ':8080$1')
  // Heuristic auto-fix for legacy docs that pointed python analysis to 8082
  const pyTarget = rawPyTarget.replace(/:8082(\/|$)/, ':8086$1')

  if (!isProduction) {
    // Helps debug “Token required on login/register” issues caused by proxy target misconfiguration
    console.log(`[vite] proxy /api target: ${apiTarget} (raw=${rawApiTarget})`)
    console.log(`[vite] proxy /pyanalysis target: ${pyTarget} (raw=${rawPyTarget})`)
    console.log(`[vite] proxy /online-api target: ${onlineServiceTarget}`)
  }

  return {
    plugins: [
      vue(),
      vueJsx(),
      createSvgIconsPlugin({
        iconDirs: [path.resolve(__dirname, 'src/assets/icons')],
        symbolId: 'icon-[name]',
      }),
      legacy({
        targets: ['> 1%', 'last 2 versions', 'not dead', 'not ie 11'],
      })
    ],
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url))
      }
    },
    server: {
      port: 9877, // 保持与原 Vue CLI 配置相同的端口
      proxy: {
        '/api': {
          target: apiTarget,
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/api/, '')
        },
        '/pyanalysis': {
          target: pyTarget,
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/pyanalysis/, '')
        },
        '/online-api': {
          target: onlineServiceTarget,
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/online-api/, '')
        },
        '/before': {
          target: 'http://172.18.129.239:8080/algo',
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/before/, '')
        }
      }
    },
    css: {
      preprocessorOptions: {
        scss: {
          additionalData: `@import "@/assets/css/global.css";`
        }
      }
    },
    build: {
      outDir: 'dist',
      sourcemap: !isProduction,
      chunkSizeWarningLimit: 2000,
      rollupOptions: {
        output: {
          manualChunks: (id) => {
            // 核心库分割
            if (id.includes('node_modules/vue/') ||
              id.includes('node_modules/vue-router/') ||
              id.includes('node_modules/@vue/')) {
              return 'vue-core';
            }

            // 状态管理
            if (id.includes('node_modules/pinia/')) {
              return 'store';
            }

            // UI组件库
            if (id.includes('node_modules/element-plus/')) {
              return 'element-plus';
            }

            // 图表库
            if (id.includes('node_modules/echarts/')) {
              return 'echarts';
            }

            // 工具库
            if (id.includes('node_modules/axios/') ||
              id.includes('node_modules/date-fns/')) {
              return 'utils-vendor';
            }

            // 项目工具方法
            if (id.includes('/src/utils/')) {
              return 'utils-app';
            }

            // 自动建模模块 - 分解大组件
            if (id.includes('/src/views/AutoModel/TaskCreate')) {
              return 'auto-model-create';
            }
            if (id.includes('/src/views/AutoModel/TaskModify')) {
              return 'auto-model-modify';
            }
            if (id.includes('/src/views/AutoModel/taskDetails')) {
              return 'auto-model-details';
            }
            if (id.includes('/src/views/AutoModel/TaskView')) {
              return 'auto-model-view';
            }
            if (id.includes('/src/views/AutoModel/') &&
              !id.includes('TaskCreate') &&
              !id.includes('TaskModify') &&
              !id.includes('taskDetails') &&
              !id.includes('TaskView')) {
              return 'auto-model-common';
            }

            // 数据集管理模块
            if (id.includes('/src/views/DatasetManagement/')) {
              return 'dataset-management';
            }

            // 镜像仓库模块
            if (id.includes('/src/views/ImageRepository/')) {
              return 'image-repository';
            }

            // 模型仓库模块
            if (id.includes('/src/views/ModelRepository/')) {
              return 'model-repository';
            }

            // 在线服务模块 - 分解大组件
            if (id.includes('/src/views/OnlineService/OnlineServiceLogVisualization')) {
              return 'online-service-visualization';
            }
            if (id.includes('/src/views/OnlineService/OnlineServiceDeploy')) {
              return 'online-service-deploy';
            }
            if (id.includes('/src/views/OnlineService/') &&
              !id.includes('OnlineServiceLogVisualization') &&
              !id.includes('OnlineServiceDeploy')) {
              return 'online-service-common';
            }

            // 共享组件
            if (id.includes('/src/components/')) {
              return 'shared-components';
            }

            // 路由和存储
            if (id.includes('/src/router/') || id.includes('/src/store/')) {
              return 'app-core';
            }
          }
        }
      }
    },
    // 为了兼容现有代码，但我们会逐步替换这些代码
    define: {
      'process.env': {
        NODE_ENV: JSON.stringify(mode),
        BASE_URL: JSON.stringify(env.VITE_BASE_URL || '/'),
        API_BASE_URL: JSON.stringify(env.VITE_API_BASE_URL || '/api'),
        APP_TITLE: JSON.stringify(env.VITE_APP_TITLE || '智能中台建模平台')
      }
    }
  }
})
