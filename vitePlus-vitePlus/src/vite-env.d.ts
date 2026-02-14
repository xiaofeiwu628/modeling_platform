/// <reference types="vite/client" />
/// <reference types="vite-plugin-svg-icons/client" />

// 增强环境变量的类型定义
interface ImportMetaEnv {
  readonly VITE_APP_TITLE: string
  readonly VITE_API_BASE_URL: string
  readonly VITE_PYANALYSIS_URL: string
  readonly VITE_BEFORE_URL: string
  readonly VITE_BASE_URL: string
  readonly VITE_DEBUG: string
  readonly VITE_API_TARGET: string
  readonly VITE_PYANALYSIS_TARGET: string
  readonly MODE: string
  readonly DEV: boolean
  readonly PROD: boolean
  readonly SSR: boolean
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
}