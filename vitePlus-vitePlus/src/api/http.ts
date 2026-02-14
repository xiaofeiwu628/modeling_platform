import axios, { AxiosHeaders, type AxiosRequestConfig, type InternalAxiosRequestConfig } from "axios";
import request from "@/utils/request";
import { getStoredToken } from "@/utils/token";
import type { Result } from "@/api/types";

/**
 * SpringBoot 微服务（经 Gateway）统一客户端：baseURL 默认 /api
 * - header Token/token 由 utils/request.ts 根据 url 自动处理
 */
export const spring = request;

type SpringClient = {
  get<T>(url: string, config?: AxiosRequestConfig): Promise<Result<T>>;
  post<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<Result<T>>;
  put<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<Result<T>>;
  delete<T>(url: string, config?: AxiosRequestConfig): Promise<Result<T>>;
};

const springClient = spring as unknown as SpringClient;

// 下面这些 helpers 让 api 层能写出 “强类型返回”：
export function springGet<T>(url: string, config?: AxiosRequestConfig): Promise<Result<T>> {
  // utils/request.ts 会在响应拦截器里直接 return response.data（即 Result<T>）
  return springClient.get<T>(url, config);
}

export function springPost<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<Result<T>> {
  return springClient.post<T>(url, data, config);
}

export function springPut<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<Result<T>> {
  return springClient.put<T>(url, data, config);
}

export function springDelete<T>(url: string, config?: AxiosRequestConfig): Promise<Result<T>> {
  return springClient.delete<T>(url, config);
}

/**
 * FastAPI 主节点（经 Gateway /algo）客户端：baseURL 默认 /api/algo
 * - header token 必须是小写 token
 */
export const algo = axios.create({
  baseURL: import.meta.env.VITE_BEFORE_URL || "/api/algo",
  timeout: 300000,
  headers: {
    "Content-Type": "application/json;charset=utf-8",
  },
});

algo.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    if (!config.headers) config.headers = new AxiosHeaders();
    if (config.headers instanceof AxiosHeaders) {
      config.headers.set("token", getStoredToken());
    } else {
      (config.headers as Record<string, unknown>)["token"] = getStoredToken();
    }
    return config;
  },
  (error) => Promise.reject(error)
);

/**
 * python-data-service（8086）客户端：开发环境通过 Vite proxy /pyanalysis
 */
export const pyanalysis = axios.create({
  baseURL: import.meta.env.VITE_PYANALYSIS_URL || "/pyanalysis",
  timeout: 300000,
});

