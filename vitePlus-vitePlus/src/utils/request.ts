import axios, { AxiosHeaders, type AxiosResponse, type InternalAxiosRequestConfig } from "axios";
import router from "@/router";
import { clearStoredToken, getStoredToken } from "@/utils/token";

const request = axios.create({
  // 使用环境变量
  baseURL: import.meta.env.VITE_API_BASE_URL || "/api",
  timeout: 300000,
});

request.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    if (!config.headers) config.headers = new AxiosHeaders();
    const token = getStoredToken();
    const url = config.url || "";
    // Endpoints that do NOT require Token (login/register etc.)
    const tokenFreePrefixes = [
      "/auth/UserLogin/", // gateway-facing auth endpoints
    ];

    // If token is missing and endpoint is not token-free, redirect to login early.
    if (!token) {
      const isTokenFree = tokenFreePrefixes.some((p) => url.startsWith(p));
      if (!isTokenFree) {
        router.push({ path: "/login" });
        return Promise.reject(new Error("MISSING_TOKEN"));
      }
    }
    // FastAPI(/algo/**) 需要 header key 为小写 token；SpringBoot 微服务使用 Token
    if (url.startsWith("/algo") || url.startsWith("algo/")) {
      if (config.headers instanceof AxiosHeaders) {
        config.headers.set("token", token);
      } else {
        // 兼容 axios 允许 headers 为普通对象的情况
        (config.headers as Record<string, unknown>)["token"] = token;
      }
    } else {
      if (config.headers instanceof AxiosHeaders) {
        config.headers.set("Token", token);
      } else {
        (config.headers as Record<string, unknown>)["Token"] = token;
      }
    }
    return config;
  },
  (error) => Promise.reject(error)
);

request.interceptors.response.use(
  (response: AxiosResponse) => {
    let res = response.data;
    if (response.config.responseType === "blob") return res;
    if (typeof res === "string") res = res ? JSON.parse(res) : res;
    // 仅对明确的未登录/无权限清 token 并跳转登录（403 被 ResponseTimeAspect 用于业务异常，不当作鉴权失败）
    const authErrorCodes = [
      10010, "10010", 10011, "10011",
      401, "401",
      40100, "40100", 40101, "40101",  // 后端 NOT_LOGIN_ERROR / NO_AUTH_ERROR
    ];
    if (res && authErrorCodes.includes(res.code)) {
      clearStoredToken();
      router.push({ path: "/login" });
    }
    return res;
  },
  (error) => {
    console.log("err" + error);
    return Promise.reject(error);
  }
);

export default request;