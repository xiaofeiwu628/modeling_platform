# 建模平台嵌入接入说明

本文档用于说明第三方平台如何嵌入本建模平台页面，以及如何调用登录接口获取访问 Token。

## 1. 部署访问地址

以下示例假设建模平台部署在：

```text
http://服务器IP/modeling/
```

如果实际部署地址不同，请将示例中的 `http://服务器IP/modeling` 替换为真实地址。

例如：

```text
http://服务器IP/modeling/dataAnnotation
```

## 2. 登录与 Token 获取

第三方平台用户登录时，可由第三方平台后端或前端同步调用建模平台登录接口，使用约定好的专用账号登录。

### 2.1 URL 参数自动登录

第三方平台也可以直接在嵌入页面 URL 中携带建模平台专用账号密码。建模平台前端会在页面加载时读取参数，调用本平台登录接口，登录成功后保存用户信息和 Token，然后自动移除 URL 中的账号密码参数。

支持的参数名：

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `username` / `Username` / `userName` | string | 是 | 建模平台专用账号 |
| `password` / `Password` | string | 是 | 建模平台专用账号密码 |

示例：

```text
http://服务器IP/modeling/dataAnnotation?username=embed_user_1&password=your_password
```

或：

```text
http://服务器IP:9877/dataAnnotation?username=embed_user_1&password=your_password
```

iframe 示例：

```html
<iframe
  src="http://服务器IP/modeling/dataAnnotation?username=embed_user_1&password=your_password"
  style="width: 100%; height: 100vh; border: 0;"
></iframe>
```

登录成功后，前端会保存：

```js
localStorage.setItem('Username', username)
localStorage.setItem('Token', token)
localStorage.setItem('token', token)
```

如果后端返回 `user_id`，也会保存：

```js
localStorage.setItem('user_id', userId)
localStorage.setItem('UserId', userId)
```

随后 URL 会从：

```text
/dataAnnotation?username=embed_user_1&password=your_password
```

自动清理为：

```text
/dataAnnotation
```

> **非常重要：第三方仅需在“首次嵌入访问”或“跨域切换外层菜单”时拼接一次账号密码即可！**
> 1. **首次登录**：iframe 首次加载带有参数的 URL，建模平台自动完成后台登录，将 Token 存入浏览器的 Local Storage，并自动刷新剔除明文密码。
> 2. **内部点击**：用户在 iframe 内部点击任何其他菜单、按钮，系统会自动携带已存储的 Token，**完全不需要**第三方再次提供账号密码。
> 3. **外部菜单切换**：若第三方系统从外部自身菜单强制切换 iframe 的 src (例如从 `/taskView` 切换为 `/dataAnnotation`)，由于同源 Local Storage 共享机制，平台依然保持登录状态。为了稳妥，第三方在切换外层菜单时，可以依然拼接参数（系统会自动校验重登）或者不拼接直接跳入。

> 注意：URL 中携带密码会被浏览器历史、服务器访问日志、代理日志记录。当前方案按第三方平台约定实现，建议仅使用专用低权限账号。

### 2.2 登录页面路由

如果需要人工登录，可访问：

```text
/login
```

完整地址示例：

```text
http://服务器IP/modeling/login
```

### 2.3 登录接口

前端当前使用的登录接口为：

```text
POST /api/auth/UserLogin/Login
```

如果直接访问后端 Gateway，则接口路径通常为：

```text
POST http://服务器IP:8080/auth/UserLogin/Login
```

如果通过前端 Nginx 代理访问，则接口路径通常为：

```text
POST http://服务器IP/modeling/api/auth/UserLogin/Login
```

实际以部署时的 Nginx `/api` 代理配置为准。

### 2.4 请求参数

当前登录接口使用 query 参数传递账号密码：

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `Username` | string | 是 | 建模平台专用账号 |
| `Password` | string | 是 | 建模平台专用账号密码 |

请求示例：

```bash
curl -X POST "http://服务器IP/modeling/api/auth/UserLogin/Login?Username=embed_user_1&Password=your_password"
```

### 2.5 返回格式

成功返回示例：

```json
{
  "code": "0",
  "msg": "登录成功",
  "data": {
    "Username": "embed_user_1",
    "Token": "xxxxxxxxxxxxxxxx"
  }
}
```

失败返回示例：

```json
{
  "code": "500",
  "msg": "用户名或密码错误",
  "data": null
}
```

第三方平台需要从：

```text
data.Token
```

中获取建模平台 Token。

### 2.6 Token 使用方式

建模平台前端当前会从浏览器 `localStorage` 中读取 Token：

```text
Token
token
```

为了兼容 SpringBoot 与 FastAPI 服务，建议同时写入两个 key：

```js
localStorage.setItem('Token', token)
localStorage.setItem('token', token)
```

如果两个平台部署在同源地址下，例如：

```text
http://服务器IP/platform/
http://服务器IP/modeling/
```

第三方平台写入同源 `localStorage` 后，iframe 中的建模平台页面可以直接读取。

如果两个平台不是同源，例如端口不同：

```text
http://服务器IP:8088/platform/
http://服务器IP:9877/modeling/
```

则 `localStorage` 不共享，Token 传递方式需要双方另行约定，例如 URL 参数、`postMessage`、Cookie 或后端统一网关。

## 3. 页面嵌入方式

第三方平台可通过 iframe 嵌入建模平台页面。

示例：

```html
<iframe
  src="http://服务器IP/modeling/dataAnnotation"
  style="width: 100%; height: 100vh; border: 0;"
></iframe>
```

## 4. 页面路由清单

| 功能模块 | 页面名称 | 路由 | 参数说明 |
|---|---|---|---|
| 登录 | 登录页 | `/login` | 人工登录入口 |
| 注册 | 注册页 | `/register` | 注册入口，如嵌入场景不开放可不提供 |
| 首页 | 平台首页 | `/home` | 无 |
| 数据集管理 | 数据集列表 | `/datascreen` | 无 |
| 数据标注 | 数据标注工作台 | `/dataAnnotation` | 无 |
| 数据集管理 | 数据表概览 | `/dataView` | `tableId`、`datasetId` |
| 数据集管理 | 数据表详情 | `/dataView/detail` | `tableId`、`setId` |
| 数据集管理 | 多字段可视化 | `/MultiVisualization` | `setId`、`tableId`、`choseColumns`、`timeColumns` |
| 数据集管理 | 实体视图 | `/entityView` | 依赖业务跳转参数 |
| 数据集管理 | 实体详情 | `/entityView/detail` | 依赖业务跳转参数 |
| 数据集管理 | 实体可视化 | `/entityVisualization` | 依赖业务跳转参数 |
| 自动建模 | 任务列表 | `/taskView` | 无 |
| 自动建模 | 创建训练任务 | `/taskCreate` | 无 |
| 自动建模 | 任务详情 | `/taskDetails` | 通常依赖任务 ID 等查询参数 |
| 自动建模 | 修改任务 | `/taskModify` | 通常依赖任务 ID 等查询参数 |
| 模型仓库 | 模型列表 | `/modelList` | 无 |
| 镜像仓库 | 镜像列表 | `/imageList` | 无 |
| 在线服务 | 服务列表 | `/onlineServiceList` | 无 |
| 在线服务 | 服务部署 | `/onlineServiceDeploy` | 可能依赖模型或镜像参数 |
| 在线服务 | 服务详情 (含API测试) | `/onlineServiceDetails` | 通常依赖服务 ID 等查询参数 |
| 在线服务 | 服务日志 | `/onlineServiceLog` | 通常依赖服务 ID 等查询参数 |
| 在线服务 | 日志可视化 | `/onlineServiceLogVisualization` | 通常依赖服务 ID 等查询参数 |
| 图谱服务 | 图谱列表 | `/graphList` | 无 |
| 图谱服务 | 图谱详情 | `/graph/:lastPos?` | `lastPos` 为可选路径参数 |

## 5. 常用嵌入地址示例

### 5.1 数据标注

```text
http://服务器IP/modeling/dataAnnotation
```

```html
<iframe
  src="http://服务器IP/modeling/dataAnnotation"
  style="width: 100%; height: 100vh; border: 0;"
></iframe>
```

### 5.2 数据集管理

```text
http://服务器IP/modeling/datascreen
```

```html
<iframe
  src="http://服务器IP/modeling/datascreen"
  style="width: 100%; height: 100vh; border: 0;"
></iframe>
```

### 5.3 指定数据表概览

```text
http://服务器IP/modeling/dataView?tableId=1&datasetId=1
```

```html
<iframe
  src="http://服务器IP/modeling/dataView?tableId=1&datasetId=1"
  style="width: 100%; height: 100vh; border: 0;"
></iframe>
```

### 5.4 指定数据表详情

```text
http://服务器IP/modeling/dataView/detail?tableId=1&setId=1
```

```html
<iframe
  src="http://服务器IP/modeling/dataView/detail?tableId=1&setId=1"
  style="width: 100%; height: 100vh; border: 0;"
></iframe>
```

### 5.5 自动建模任务列表

```text
http://服务器IP/modeling/taskView
```

```html
<iframe
  src="http://服务器IP/modeling/taskView"
  style="width: 100%; height: 100vh; border: 0;"
></iframe>
```

### 5.6 在线服务列表

```text
http://服务器IP/modeling/onlineServiceList
```

```html
<iframe
  src="http://服务器IP/modeling/onlineServiceList"
  style="width: 100%; height: 100vh; border: 0;"
></iframe>
```

### 5.7 图谱服务列表

```text
http://服务器IP/modeling/graphList
```

```html
<iframe
  src="http://服务器IP/modeling/graphList"
  style="width: 100%; height: 100vh; border: 0;"
></iframe>
```

## 6. Nginx 部署要求

如果建模平台部署在 `/modeling/` 子路径下，需要确保前端 history 路由可以回退到入口 HTML。

示例：

```nginx
location /modeling/ {
  alias /usr/share/nginx/html/;
  index index.html;
  try_files $uri $uri/ /modeling/index.html;
}
```

如果 `/api` 也由同一个 Nginx 代理，需要配置到 SpringBoot Gateway (默认为 8080 端口)：

```nginx
location /modeling/api/ {
  rewrite ^/modeling/api/(.*)$ /$1 break;
  proxy_pass http://后端网关IP:8080;
}
```

Python 数据分析服务代理配置 (默认为 8086 端口)：

```nginx
location /modeling/pyanalysis/ {
  rewrite ^/modeling/pyanalysis/(.*)$ /$1 break;
  proxy_pass http://Python服务IP:8086;
}
```

自动建模任务调度代理配置 (通常指向网关下的 `/algo`，根据实际情况配置)：

```nginx
location /modeling/before/ {
  rewrite ^/modeling/before/(.*)$ /algo/$1 break;
  proxy_pass http://后端网关IP:8080;
}
```

在线服务 API 测试代理配置 (默认为 8002 端口)：

```nginx
location /modeling/online-api/ {
  rewrite ^/modeling/online-api/(.*)$ /$1 break;
  proxy_pass http://在线服务网关IP:8002;
}
```

> **说明**：前端在线服务详情页的「API测试」功能会优先把匹配 `VITE_ONLINE_SERVICE_TARGET` 的服务地址转换为 `/online-api/...`，通过同源代理发送请求，从而避免浏览器跨域限制。生产环境请保证 `.env.production` 中的 `VITE_ONLINE_SERVICE_TARGET` 配置项与 Nginx `proxy_pass` 的真实目标地址保持一致。

实际路径以部署目录、Nginx root/alias 配置和后端地址为准。

## 7. 注意事项

1. 嵌入页面需要先完成建模平台登录并让页面能够读取 Token。
2. Token 失效后，建模平台前端会跳转到 `/login`。
3. 如果 iframe 页面刷新后 404，优先检查 Nginx `try_files` 配置。
4. 如果接口 401 或提示未登录，优先检查 `localStorage` 中是否存在 `Token` 和 `token`。
5. 如果部署在子路径 `/modeling/`，构建时需要确保前端 base 与路由 base 使用同一个前缀。
