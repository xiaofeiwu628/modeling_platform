import { springPost, springGet } from "@/api/http";
import { clearStoredToken, setStoredToken } from "@/utils/token";
import type { LoginParams, LoginResult, RegisterParams, Result } from "@/api/types";

export async function login(params: LoginParams): Promise<LoginResult> {
  const res = await springPost<LoginResult["data"]>("/auth/UserLogin/Login", null, { params });
  if (res.code === "0" && res.data?.Token) setStoredToken(res.data.Token);
  return res;
}

export async function register(params: RegisterParams): Promise<Result<null>> {
  return await springPost<null>("/auth/UserLogin/Register", null, { params });
}

export async function checkLogin(token: string): Promise<Result<unknown>> {
  return await springGet<unknown>("/auth/UserLogin/CheckLogin", { params: { Token: token } });
}

export async function logout(token: string): Promise<Result<unknown>> {
  const res = await springPost<unknown>("/auth/UserLogin/Logout", null, { params: { Token: token } });
  if (res.code === "0") clearStoredToken();
  return res;
}

export async function logoff(params: { Username: string; Password: string; Token: string }): Promise<Result<unknown>> {
  const res = await springPost<unknown>("/auth/UserLogin/Logoff", null, { params });
  if (res.code === "0") clearStoredToken();
  return res;
}

