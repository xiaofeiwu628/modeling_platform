export function getStoredToken(): string {
  return localStorage.getItem('Token') || localStorage.getItem('token') || ''
}

/**
 * 兼容历史：同时写入 Token / token 两个 key。
 * - SpringBoot 微服务读取 header: Token
 * - FastAPI(/algo) 读取 header: token
 */
export function setStoredToken(token: string): void {
  localStorage.setItem('Token', token)
  localStorage.setItem('token', token)
}

export function clearStoredToken(): void {
  localStorage.removeItem('Token')
  localStorage.removeItem('token')
}

