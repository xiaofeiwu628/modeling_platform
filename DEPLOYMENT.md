# 智能建模平台 - 服务器部署指南

本文档说明如何将项目部署到服务器上，覆盖前端、SpringBoot 微服务、FastAPI 任务调度、Python 数据分析服务及基础设施。

---

## 一、架构概览

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────────────────────────────┐
│  前端 Vue   │────▶│ Spring Gateway   │────▶│ auth / data / model / task (SpringBoot)  │
│  :9877      │     │  :8080           │     │ FastAPI 主节点 / python-data-service     │
└─────────────┘     └────────┬─────────┘     └─────────────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
   ┌──────────┐        ┌──────────┐        ┌──────────┐
   │  Nacos   │        │ RabbitMQ │        │  Redis   │
   │  :8848   │        │ :5672    │        │  :6379   │
   └──────────┘        └──────────┘        └──────────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             ▼
                      ┌──────────────┐
                      │  PostgreSQL  │
                      │  :5432       │
                      └──────────────┘
```

**端口占用：**

| 服务 | 端口 | 说明 |
|------|------|------|
| Gateway | 8080 | API 统一入口 |
| auth-service | 8081 | 认证 |
| data-service | 8082 | 数据 |
| model-service | 8083 | 模型 |
| task-service | 8084 | 任务 |
| python-data-service | 8086 | 数据分析（直连或通过 Gateway） |
| FastAPI 主节点 | 8090 | 任务调度 API（/algo） |
| Nacos | 8848, 9848 | 服务发现 |
| RabbitMQ | 5672, 15672 | 消息队列 |
| Redis | 6379 | 缓存/Token |
| PostgreSQL | 5432 | 数据库 |
| Harbor | 8930 | 镜像仓库 |
| 前端 | 9877 | 开发模式 |

---

## 二、前置依赖

- **Docker**：用于运行 Nacos、PostgreSQL、Redis、RabbitMQ、Harbor 等
- **Conda**（或 Python 3.7+）：用于 FastAPI、python-data 等 Python 服务
- **Node.js ≥ 16**：用于前端构建
- **Maven**：用于 SpringBoot 打包（若使用 jar 方式部署）
- **JDK 8**：若本地运行 SpringBoot 服务

---

## 三、基础设施部署

### 3.1 PostgreSQL

需要以下数据库与 Schema：

- `springboot`：业务元数据
- `user_data`：用户数据，并包含 `upload_data` schema
- `auth_db`、`data_db`、`model_db`、`task_db`：各微服务数据库

**初始化脚本：** 见 `model-backend/modeling-platform-springboot-backend/docker/postgres/init/`

```bash
# 若用 Docker 启动 Postgres，可挂载 init 目录
# 或手动执行 00-create-databases.sql 等
```

默认账号：`postgres / niweijian123`（与 RUN_LOCAL.md、config.yml 保持一致）

### 3.2 Redis

- 端口：6379
- 需设置密码：`niweijian123`（与 SpringBoot、FastAPI config 一致）
- 建议 `db=1` 用于 FastAPI 节点/资源，`db=2` 用于 SpringBoot Token

### 3.3 RabbitMQ

- 端口：5672（AMQP）、15672（管理控制台）
- 账号：`admin / niweijian123`
- 队列：`sys_task_queue`（任务）、`sys_node_heartbeat`（节点心跳）

### 3.4 Nacos

- 端口：8848（HTTP）、9848（gRPC）
- 用于 SpringBoot 微服务及 FastAPI 主节点、python-data-service 的服务注册
- Gateway 通过 Nacos 发现 `auth-service`、`data-service`、`fastapi-main-api`、`python-data-service` 等

### 3.5 Harbor 镜像仓库

- 端口：8930
- 用于存放 `data-pre`、`train`、`predict` 等训练/推理镜像
- 配置见 `model-backend/modeling-platform-fastapi-backend/app/astrotool/config.yml` 中 `harbor` 与 `subtask_dict`

> 若仓库中无 `docker-compose.yml` 统一启动基础设施，需自行用 Docker 或 docker-compose 分别启动以上服务，并保证 IP、端口、账号密码与各配置文件一致。

---

## 四、SpringBoot 微服务部署

### 方式 A：Docker Compose（若存在 compose 文件）

```bash
cd model-backend/modeling-platform-springboot-backend
docker compose up -d --build
```

### 方式 B：单独构建并运行各服务

1. **打包：**

```bash
cd model-backend/modeling-platform-springboot-backend
mvn clean package -DskipTests
```

2. **环境变量：** 使用 `docker.env` 或 `.env`：

- `NACOS_ADDR`、`SPRING_CLOUD_NACOS_*`
- `SPRING_DATA_REDIS_*`（含 `SPRING_DATA_REDIS_PASSWORD=niweijian123`）
- `POSTGRES_*`（含 `POSTGRES_PASSWORD=niweijian123`）

3. **Docker 运行示例（以 auth-service 为例）：**

```bash
cd auth-service
docker build -t auth-service:latest .
docker run -d --name auth-service -p 8081:8081 --env-file ../docker.env auth-service:latest
```

对 gateway、data-service、model-service、task-service 同理，按端口映射与 `docker.env` 配置。

---

## 五、FastAPI 主节点与任务调度

### 5.1 Conda 环境

```bash
conda env create -f environment.yml
conda activate astro_plantform
```

### 5.2 修改配置

编辑 `model-backend/modeling-platform-fastapi-backend/app/astrotool/config.yml`：

- `server.main_server`、`sub_server1`、`sub_server2`：改为服务器 IP
- `server.project`、`docker_log`、`docker_data`：改为实际路径
- `postgres`、`postgres_springboot`、`rabbitmq`、`redis`、`harbor`：IP、端口、用户名、密码
- `subtask_dict` 中各镜像名：确保与 Harbor 中一致

### 5.3 启动顺序（重要）

1. **先启动副节点 node_manager**（每个执行节点一台）：

```bash
cd model-backend/modeling-platform-fastapi-subnode1-backend
./manager.sh
```

多节点时，对 subnode2 等也执行对应 `manager.sh`。

2. **再启动主节点 resource_manager 与 scheduler：**

```bash
cd model-backend/modeling-platform-fastapi-backend
./manager.sh
```

3. **最后启动 FastAPI API：**

```bash
cd model-backend/modeling-platform-fastapi-backend
./run.sh
```

### 5.4 环境变量（run.sh）

- `NACOS_SERVER_ADDR`：Nacos 地址
- `SERVICE_NAME=fastapi-main-api`：与 Gateway 路由 `lb://fastapi-main-api` 对应
- `SERVICE_IP`、`SERVER_PORT`：注册到 Nacos 的地址与端口

---

## 六、Python 数据分析服务（python-data-service）

### 6.1 修改配置

编辑 `model-backend/modeling-platform-python-data-backend/app/config.yml`：

- PostgreSQL、RabbitMQ、Redis 的 host、port、username、password

### 6.2 Docker 部署

```bash
cd model-backend/modeling-platform-python-data-backend
./CreatePythonData.sh
```

或手动构建并运行（端口 8086）：

```bash
docker build -t python-data:0.1.2 .
docker run -d --name python-data -p 8086:80 \
  -e NACOS_ENABLED=true -e NACOS_SERVER_ADDR=<服务器IP>:8848 \
  -e SERVICE_NAME=python-data-service -e SERVICE_IP=<服务器IP> -e SERVICE_PORT=8086 \
  python-data:0.1.2
```

Gateway 通过 `lb://python-data-service` 转发 `/pyanalysis/**`。

---

## 七、训练/推理镜像（Harbor）

建模任务依赖以下 Docker 镜像，需构建并推送到 Harbor：

| 镜像 | 用途 |
|------|------|
| `data-pre` | 数据预处理 |
| `model/lstm`、`model/mlp` 等 | 模型训练 |
| `predict` | 模型推理 |

构建并推送示例：

```bash
# 以 data-pre 为例
cd model-backend/modeling-platform-model-data-pre-backend
docker build -t 172.18.129.239:8930/library/data-pre:0.8.4 .
docker login 172.18.129.239:8930
docker push 172.18.129.239:8930/library/data-pre:0.8.4
```

镜像名、版本需与 `config.yml` 中 `subtask_dict` 一致。

---

## 八、前端部署

### 8.1 生产构建

```bash
cd vitePlus-vitePlus
npm install
npm run build
```

### 8.2 环境变量（.env.production）

| 变量 | 含义 | 示例 |
|------|------|------|
| VITE_API_TARGET | Gateway 地址 | http://192.168.109.198:8080 |
| VITE_PYANALYSIS_TARGET | Python 数据分析服务 | http://192.168.109.198:8086 |
| VITE_BEFORE_TARGET | FastAPI 主节点（若直连） | http://192.168.109.198:8090 |

**注意：** 生产环境 API 请求应发往 **Gateway:8080**，不要指向 auth-service:8081。

### 8.3 部署构建产物

将 `dist/` 目录部署到 Nginx 或其他静态服务器：

```nginx
server {
    listen 80;
    root /path/to/vitePlus-vitePlus/dist;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
    location /api {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location /pyanalysis {
        proxy_pass http://127.0.0.1:8086;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 8.4 开发模式

```bash
cd vitePlus-vitePlus
# 确保 .env.development 中 VITE_API_TARGET 指向 Gateway:8080
npm run dev
```

访问 `http://<服务器IP>:9877`。

---

## 九、部署检查清单

- [ ] PostgreSQL 已启动，`springboot`、`user_data` 及 `upload_data` schema 已创建
- [ ] Redis 已启动，密码与各服务配置一致
- [ ] RabbitMQ 已启动，管理台可访问
- [ ] Nacos 已启动，Gateway 及各微服务可注册
- [ ] SpringBoot 微服务（Gateway、auth、data、model、task）已启动
- [ ] 副节点 `node_manager` 已先于主节点启动
- [ ] 主节点 `manager.sh`（scheduler + resource_manager）已启动
- [ ] FastAPI API（run.sh）已启动，并注册到 Nacos 为 `fastapi-main-api`
- [ ] python-data-service 已启动，注册为 `python-data-service`
- [ ] Harbor 中已存在 data-pre、train、predict 等镜像
- [ ] 前端 `.env.production` 中 API 目标指向 Gateway:8080
- [ ] 各 `config.yml` 中 IP、端口、密码已改为实际服务器配置

---

## 十、常见问题

### 10.1 任务一直处于“等待”状态

- 确认副节点 `node_manager` 先启动，且 Redis 中有 `node_list` 等节点信息
- 检查 `resource_manager`、`scheduler_main` 是否正常运行
- 参考 `model-backend/TROUBLESHOOTING.md`（若存在）

### 10.2 前端提示“访问时参数要携带 Token”

- 确认 `VITE_API_TARGET` 指向 **Gateway:8080**，而非 auth-service:8081
- 生产环境构建时确保使用了正确的 `.env.production`

### 10.3 时区导致时间显示异常

- PostgreSQL 建议 `ALTER SYSTEM SET TimeZone TO 'Asia/Shanghai';`
- SpringBoot 中 `SimpleDateFormat` 需显式设置 `TimeZone.getTimeZone("Asia/Shanghai")`
- 容器内可设置 `TZ=Asia/Shanghai`

### 10.4 训练镜像拉取失败

- 检查 Harbor 是否可访问，`config.yml` 中 harbor 配置是否正确
- 确认 `subtask_dict` 中的镜像名与 Harbor 中一致
- 执行节点需能访问 Harbor 并已 `docker login`

---

## 十一、目录结构速查

```
HuangXX/
├── vitePlus-vitePlus/           # 前端
├── model-backend/
│   ├── modeling-platform-springboot-backend/   # Gateway + 4 个微服务
│   ├── modeling-platform-fastapi-backend/      # 主节点（API + 调度）
│   ├── modeling-platform-fastapi-subnode1-backend/  # 副节点 1
│   ├── modeling-platform-fastapi-subnode2-backend/  # 副节点 2
│   ├── modeling-platform-python-data-backend/  # 数据分析服务
│   ├── modeling-platform-model-data-pre-backend/    # 数据预处理镜像
│   ├── modeling-platform-model-train-backend/       # 训练镜像
│   └── modeling-platform-model-predict-backend/     # 推理镜像
├── harbor/                      # Harbor 私有仓库
├── docker_data/                 # 任务数据挂载（FastAPI config 中配置）
├── docker_log/                  # 任务日志（FastAPI config 中配置）
└── environment.yml              # Conda 环境
```
