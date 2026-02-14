# 自动建模平台微服务版本部署文档

**文档摘要**：本文档提供自动建模平台微服务架构的详细部署指南。系统分为 **"常驻服务"**（Web API / 调度器）和 **"动态任务镜像"**（训练 / 预测 worker）两部分。部署时需先构建基础镜像并推送到 Harbor，再启动常驻服务。

---

## 1. 基础环境准备

### 1.1 部署环境

①主节点：
系统：Ubuntu 22.04.4 LTS
CPU：Intel(R) Xeon(R) Gold 6130 CPU @ 2.10GHz（8核）
磁盘：128G
内存：16G

②副节点x2（可以主副节点在同一服务器，需要适量增加主节点磁盘与内存空间）
系统：Ubuntu 18.04 LTS
CPU：Intel(R) Xeon(R) CPU E7-8860 v3 @ 2.20GHz（8核）
磁盘：256G
内存：8G

### 1.2 服务器依赖

| **依赖**       | **版本**             | 端口（若有） |
| -------------- | -------------------- | ------------ |
| **anaconda**   | Anaconda3-5.3.1      | -            |
| **docker**     | 20.10.21             | -            |
| **harbor**     | v2.6.2               | 8930         |
| **postgreSQL** | tag:17.2             | 5432         |
| **redis**      | tag:7.4.2            | 6379         |
| **rabbitmq**   | tag:4.0.5-management | 5672/15672   |
| **portainer**  | tag:2.31.0           | 9000         |
| **nginx**      | tag:1.27.3           | -            |
| **JDK**        | 17                   | -            |
| **springboot** | 3.2.4                | -            |
| **nacos**      | 2.0+                 | 8848         |
| **nodejs**     | v20.9.0              | -            |
| **npm**        | 10.1.0               | -            |

---

## 2. 主节点部署

主节点需要运行**前端vue项目**、**后端springboot微服务项目**、**后端python-data项目**、**主节点后端fastapi项目（主控、调度中心）**以及**动态任务镜像构建**。

### 2.1 依赖配置

#### Anaconda安装

下载Anaconda3-5.3.1-Linux-x86_64.sh到服务器，执行命令：

```bash
bash Anaconda3-5.3.1-Linux-x86_64.sh
```

等待安装结束后，使用命令`source ~/.bashrc`加载配置。
使用命令`conda --version`查看是否安装成功。

安装成功后，对conda进行换源：

```bash
vim ~/.condarc
channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/msys2/
show_channel_urls: true
```

给pip换源：

```bash
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

使用命令从原服务器导出anaconda环境进行迁移，已有配置文件environment.yml可跳过导出步骤：

```bash
conda env export > environment.yml
```

在新服务器中导入环境：

```bash
conda env create -f environment.yml
```

如果无法正常导入环境，请根据environment.yml文件内容手动创建环境，安装所有依赖。环境名为**astro_plantform**（注意拼写，非platform）。

#### Docker安装

先更新ubuntu系统的apt:

```bash
apt update
apt upgrade
```

查找并安装、配置指定版本docker:

```bash
apt-cache madison docker.io
# 安装指定版本
apt-get install docker.io=20.10.21-0ubuntu1~18.04.3
# 启动
systemctl start docker
# 开机自启
systemctl enable docker
```

创建daemon.json文件

```bash
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false,
  "registry-mirrors": [
    "https://2a6bf1988cb6428c877f723ec7530dbc.mirror.swr.myhuaweicloud.com",
    "https://docker.m.daocloud.io",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://your_preferred_mirror",
    "https://dockerhub.icu",
    "https://docker.registry.cyou",
    "https://docker-cf.registry.cyou",
    "https://dockercf.jsdelivr.fyi",
    "https://docker.jsdelivr.fyi",
    "https://dockertest.jsdelivr.fyi",
    "https://mirror.aliyuncs.com",
    "https://dockerproxy.com",
    "https://mirror.baidubce.com",
    "https://docker.m.daocloud.io",
    "https://docker.nju.edu.cn",
    "https://docker.mirrors.sjtug.sjtu.edu.cn",
    "https://docker.mirrors.ustc.edu.cn",
    "https://mirror.iscas.ac.cn",
    "https://docker.rainbond.cc",
    "https://docker.m.daocloud.io",
    "https://docker.1panel.live",
    "https://hub.rat.dev"
  ]
}
EOF
```

创建后重启docker并验证是否安装成功：

```bash
systemctl daemon-reload
systemctl restart docker
docker run hello-world
```

修改`/lib/systemd/system/docker.service`，如果没有此目录，请使用`systemctl status docker.service`命令查看本地docker.service目录。将其中的ExecStart按如下格式修改：

```
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock -H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock --insecure-registry 172.18.129.239:8930
```

重新载入服务信息，重启docker服务，查看端口2375是否开启：

```bash
systemctl daemon-reload
systemctl restart docker.service
netstat -nlpt
```

继续安装Docker Compose:

```bash
pip install --upgrade pip --no-cache-dir
pip install docker-compose==1.26.0
```

#### Harbor仓库安装

下载harbor仓库离线压缩包，解压：

```bash
tar xvf harbor-offline-installer-v2.6.2.tgz
cd harbor
vim harbor.yml
```

参考配置文件harbor.yml内容进行修改。注意修改hostname的IP，修改http端口为8930，注释https，修改data_volume路径，修改密码。

配置好文件后，安装Harbor:

```bash
./prepare
./install.sh
```

安装完成后，可以利用docker-compose启动harbor:

```bash
docker-compose down
docker-compose up -d
```

Harbor仓库配置完成，可以在浏览器中通过设置的IP与端口8930访问Harbor。Username:admin，Password:your_password

#### postgreSQL安装

使用docker pull拉取并运行镜像，注意设置的密码：

```bash
docker run -d \
  -p 5432:5432 \
  --name mypostgres \
  -e POSTGRES_PASSWORD=niweijian123 \
  -v $(pwd)/postgres/init:/docker-entrypoint-initdb.d \
  postgres:17.2
```

注意根据需要修改密码，牢记设置的密码，后面会用到。

**说明**：

1. 请在项目的根目录下（即包含postgres的目录）执行此命令。
2. 容器启动时会自动执行挂载目录下的所有 SQL 脚本。
3. 00-create-databases.sql 会自动创建 auth_db、data_db等业务数据库。
4. 后续的脚本（如 02-auth_db.sql）内部包含了\connect auth_db指令，会自动切换到对应数据库创建表结构，无需人工干预。

#### Redis配置

直接使用命令`docker pull redis:7.4.2`拉取镜像，创建`/redis/config/redis.conf`文件，内容参考下方示例，修改redis.conf中的requirepass密码，创建空的`/redis/data`文件夹。

![image-20260131202002883](/Users/xx/Library/Application Support/typora-user-images/image-20260131202002883.png)

```
# bind 127.0.0.1 //允许远程连接
protected-mode no
appendonly yes
requirepass niweijian123
```

之后可以创建、启动redis容器，并绑定配置共享文件夹：

```bash
docker run --restart=always -p 6379:6379 --name myredis -v /实际路径/redis/config/redis.conf:/etc/redis/redis.conf -v /实际路径/redis/data:/data -d redis:7.4.2 redis-server /etc/redis/redis.conf --appendonly yes
```

请根据配置路径修改对应命令。

#### RabbitMQ安装

拉取镜像启动即可：

```bash
docker pull rabbitmq:4.0.5-management
docker run -d --name myrabbitmq -p 5672:5672 -p 15672:15672 -e RABBITMQ_DEFAULT_USER=admin -e RABBITMQ_DEFAULT_PASS=niweijian123 rabbitmq:4.0.5-management
```

注意修改并牢记对应的密码。
成功启动后，可以通过浏览器访问15672端口查看rabbitMQ是否正常运行。

#### Nacos安装

微服务架构需要Nacos做服务发现，拉取镜像启动即可：

```bash
docker run -d --name nacos -p 8848:8848 -p 9848:9848 -e MODE=standalone -e SPRING_DATASOURCE_PLATFORM=embedded nacos/nacos-server:v2.2.0
```

默认账号密码为nacos/nacos。

#### Portainer安装

拉取镜像启动即可：

```bash
docker pull portainer/portainer-ce:2.31.0
docker run -d -p 9000:9000 --name myportainer -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer-ce:2.31.0
```

成功启动后可以通过浏览器访问9000端口查看Portainer WEB端，填写配置信息（LOCAL模式）。

#### Neo4j安装

```bash
docker run -d --name neo4j -p 7474:7474 -p 7687:7687 -e NEO4J_AUTH=neo4j/niweijian123 neo4j:4.4.36-community
```

### 2.2 Spring Boot微服务部署

本项目的微服务包括：

- `gateway` (8080)
- `auth-service` (8081)
- `data-service` (8082)
- `model-service` (8083)
- `task-service` (8084)
- `graph-service` (8085)

#### 2.2.1 配置文件修改

所有微服务均读取 `modeling-platform-springboot-backend/docker.env` 文件中的环境变量。在部署前，请确保该文件已根据您的服务器环境进行了正确配置。

#### 2.2.2 构建与运行

使用 Docker 容器化部署。请在 `modeling-platform-springboot-backend` 目录下执行以下命令。

我们为每个服务提供了统一的构建和运行模式。以 `data-service` 为例：

```bash
# 清理并重新打包所有模块
mvn clean package -DskipTests

# 清理旧容器 (如果存在)
docker rm -f data-service 2>/dev/null || true

# 构建镜像 (指定 Dockerfile)
docker build --no-cache -t mp-data:latest -f data-service/Dockerfile .

# 运行容器
# 注意：使用 --network host 以便容器能直接访问宿主机服务 (如 Nacos)
# 使用 --env-file 加载环境变量配置
docker run -d --name data-service \
  --network host \
  --restart unless-stopped \
  --env-file $(pwd)/docker.env \
  mp-data:latest
```

请参考上述模式，只需修改服务名称和镜像标签即可：

**Auth Service**

```bash
docker rm -f auth-service 2>/dev/null || true
docker build --no-cache -t mp-auth:latest -f auth-service/Dockerfile .
docker run -d --name auth-service --network host --restart unless-stopped --env-file $(pwd)/docker.env mp-auth:latest
```

**Gateway**

```bash
docker rm -f gateway 2>/dev/null || true
docker build --no-cache -t mp-gateway:latest -f gateway/Dockerfile .
docker run -d --name gateway --network host --restart unless-stopped --env-file $(pwd)/docker.env mp-gateway:latest
```

**Model Service**

```bash
docker rm -f model-service 2>/dev/null || true
docker build --no-cache -t mp-model:latest -f model-service/Dockerfile .
docker run -d --name model-service --network host --restart unless-stopped --env-file $(pwd)/docker.env mp-model:latest
```

**Task Service**

```bash
docker rm -f task-service 2>/dev/null || true
docker build --no-cache -t mp-task:latest -f task-service/Dockerfile .
docker run -d --name task-service --network host --restart unless-stopped --env-file $(pwd)/docker.env mp-task:latest
```

**Graph Service**

```bash
docker rm -f graph-service 2>/dev/null || true
docker build --no-cache -t mp-graph:latest -f graph-service/Dockerfile .
docker run -d --name graph-service --network host --restart unless-stopped --env-file $(pwd)/docker.env mp-graph:latest
```

#### 2.2.3 一次性重新构建脚本

我们提供了一个一次性重建并启动所有微服务的脚本：

```bash
bash rebuild-all-services.sh
```

脚本路径：`modeling-platform-springboot-backend/rebuild-all-services.sh`

部署完成后，可以通过以下方式验证：

1. 访问 Nacos 控制台，确认所有服务均已注册且状态健康。
2. 查看容器日志检查启动状态：`docker logs -f data-service`

### 2.3 python-data项目

提供数据管理相关的 API。

*   **目录**: `modeling-platform-python-data-backend`
*   **配置文件**: `app/config.yml` 
*   **部署方式**: 使用自带脚本构建并启动容器。

修改python_data项目中的config.yml，主要修改postgres、rabbitmq、redis的IP、用户名和密码。

使用项目目录下的脚本CreatePythonData.sh启动python_data项目。

**启动命令**:

```bash
cd modeling-platform-python-data-backend
# 运行脚本 (会自动 build 并 run)
bash CreatePythonData.sh
```

### 2.4 动态任务镜像构建

以下模块不作为常驻服务运行，而是被主系统动态调度。**必须先构建为 Docker 镜像**并推送到 Harbor。

#### 2.4.1 镜像列表

| 模块目录                                   | 配置中的镜像名（示例）                     | 用途               |
| :----------------------------------------- | :----------------------------------------- | :----------------- |
| `modeling-platform-model-data-pre-backend` | **主节点IP**:8930/library/data-pre:0.8.4   | 数据预处理执行器   |
| `modeling-platform-model-train-backend`    | **主节点IP**:8930/library/model/lstm:0.6.4 | 模型训练任务执行器 |
| `modeling-platform-model-predict-backend`  | **主节点IP**:8930/library/predict:0.4.5    | 模型预测任务执行器 |

#### 2.4.2 模型文件处理

将数据预处理、模型训练、模型预测三部分代码上传到服务器，注意修改各模块config配置文件（修改服务器IP和密码，并且检查debug_setting是否是服务器运行模式，subtask_dict需与fastapi主控config.yml中保持一致）。模型训练项目如需要，按readme在指定目录放置预训练模型（如bert-base-chinese）。

#### 2.4.3 构建步骤

依次进入数据预处理、模型训练、模型预测三部分目录下（Dockerfile那层），进行打包，根据fastapi项目config.yml中subtask_dict的镜像版本修改以下信息。

```bash
# 1. 构建数据预处理镜像
cd modeling-platform-model-data-pre-backend
docker build -t data-pre:0.8.4 .
docker tag data-pre:0.8.4 172.18.129.239:8930/library/data-pre:0.8.4
docker push 172.18.129.239:8930/library/data-pre:0.8.4

# 2. 构建训练镜像
cd ../modeling-platform-model-train-backend
docker build -t model:0.6.4 .
docker tag model:0.6.4 172.18.129.239:8930/library/model/lstm:0.6.4
docker push 172.18.129.239:8930/library/model/lstm:0.6.4

# 3. 构建预测镜像
cd ../modeling-platform-model-predict-backend
docker build -t predict:0.4.5 .
docker tag predict:0.4.5 172.18.129.239:8930/library/predict:0.4.5
docker push 172.18.129.239:8930/library/predict:0.4.5
```

注意，这里的IP与端口需要修改，并且tag需要与配置文件中保持完全一致。

如果遇到push报错，请先使用docker登录harbor：

```bash
docker login 172.18.129.239:8930 -u admin -p your_password
```

> **注意**: 构建完成后，config.yml中subtask_dict的image_name必须与推送的镜像名完全一致；执行任务的副节点需能访问Harbor并已docker login。

### 2.5 主控/调度中心

核心服务，包含 Web API、任务调度器 (Scheduler) 和资源管理器。

*   **目录**: `modeling-platform-fastapi-backend`
*   **配置文件**: `app/astrotool/config.yml` (需配置 Postgres/Redis/RabbitMQ/Server IP)
*   **启动脚本**:
    *   `manager.sh`: 启动后台调度进程 (Scheduler + Resource Manager)
    *   `run.sh`: 启动 Web API 服务器

创建docker_data和docker_log文件夹。

修改启动脚本manager.sh与run.sh。脚本内容如下：

```bash
# manager.sh
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate astro_plantform
export PYTHONPATH=/项目路径/modeling-platform-fastapi-backend
nohup python -u /项目路径/modeling-platform-fastapi-backend/app/scheduler_main.py > /项目路径/modeling-platform-fastapi-backend/app/log/scheduler.log 2>&1 &
nohup python -u /项目路径/modeling-platform-fastapi-backend/app/managers/resource_manager.py > /项目路径/modeling-platform-fastapi-backend/app/log/resource_manager.log 2>&1 &

# run.sh
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate astro_plantform
export PYTHONPATH=/项目路径/modeling-platform-fastapi-backend:/项目路径/modeling-platform-fastapi-backend/app
export NACOS_ENABLED=true
export NACOS_SERVER_ADDR=主节点IP:8848
export SERVICE_NAME=fastapi-main-api
export SERVICE_IP=主节点IP
export SERVER_PORT=8090
nohup uvicorn app.main:app --host 0.0.0.0 --port 8090 > /项目路径/modeling-platform-fastapi-backend/app/log/api.log 2>&1 &
```

修改脚本中的路径与fastapi项目当前文件路径一致。

根据2.1中安装的配置信息，修改fastapi项目中的config.yml，主要修改服务器IP、用户名和密码、以及相应路径。镜像名称部分也需要修改IP，其他保持不变。
配置文件路径：`modeling-platform-fastapi-backend/app/astrotool/config.yml`

如果无副节点，需要将对应的两个副节点地址全改为主节点（开发节点），即开发节点所在服务器同时也是副节点。

**启动命令**:

```bash
cd modeling-platform-fastapi-backend

# 启动后台管理进程 (调度与资源监控)
bash manager.sh
# 检查日志: tail -f app/log/scheduler.log
# 检查日志: tail -f app/log/resource_manager.log

# 启动 API 服务
bash run.sh
# 检查日志: tail -f app/log/api.log
# 默认端口: 8090 (见 run.sh)
```

注意：必须先启动副节点node_manager，再启动主节点manager.sh与run.sh，否则任务会一直处于"等待"状态。

### 2.6 前端Vue项目

npm版本：10.1.0
nodejs版本：v20.9.0

前端Vue项目部署采用的方式是在本地生成dist文件夹，然后直接将dist文件夹复制到主节点服务器上，配置好nginx/default.conf文件，使用docker打包镜像拉起容器。具体部署细节如下：

新建文件夹存放前端vue项目相关文件，目录结构保持不变。

```
vue_deploy/
├── dist/
├── nginx/
│   └── default.conf
├── Dockerfile
└── CreateVue.sh
```

其中，dist为使用命令将本地项目打包后的文件夹，复制过来即可。Dockerfile、CreateVue.sh与default.conf如下所示：

```nginx
server {
  listen 80;
  server_name localhost;
  client_max_body_size 5G;
  access_log /var/log/nginx/host.access.log main;
  error_log /var/log/nginx/error.log error;
  location / {
    root /usr/share/nginx/html;
    index index.html index.htm;
    try_files $uri $uri/ /index.html;
  }
  location /api/ {
    rewrite /api/(.*) /$1 break;
    proxy_pass http://**192.168.109.198**:8080;
  }
  location /pyanalysis/ {
    rewrite /pyanalysis/(.*) /$1 break;
    proxy_pass http://**192.168.109.198**:8086;
  }
  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
    root /usr/share/nginx/html;
  }
}
```

default.conf

注意：微服务版本中`/api`必须代理到Gateway的**8080**端口，不能代理到8081。`/pyanalysis`代理到python-data服务的**8086**端口。

```dockerfile
FROM nginx:1.27.3
WORKDIR /usr/share/nginx/html
USER root
COPY ./dist/ .
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf
CMD ["nginx", "-g", "daemon off;"]
```

Dockerfile

```bash
#!/bin/bash
sudo docker rm -f mymodeling_platform_front
sudo docker rmi -f modeling_platform_front
docker build -t modeling_platform_front .
docker run -p 9877:80 -d --name mymodeling_platform_front modeling_platform_front
```

CreateVue.sh

注意，default.conf中部分端口需要根据服务器端口进行改动。

获取vue项目到本地后，可以使用`npm i`命令安装依赖，同时注意需要将项目中配置文件以及其他写死在代码中的IP信息换成服务器IP。微服务版本需将`.env.production`中`VITE_API_TARGET`指向Gateway的**8080**，`VITE_PYANALYSIS_TARGET`指向**8086**。之后使用`npm run build`生成dist文件夹。

以上所有文件都准备好后，在服务器执行`docker pull nginx:1.27.3`，之后执行shell脚本CreateVue.sh拉起容器即可。

---

## 3. 从节点部署

副节点部署步骤与主节点部署步骤基本相同：

### 3.1 fastapi-subnode项目

①配置依赖

Anaconda安装、Docker安装、Portainer安装：与主节点相同。若副节点与主节点共用同一服务器，部分依赖在主节点配置已配置过，可以跳过。

Docker的`--insecure-registry`需配置为主节点Harbor地址。

②调整代码

修改fastapi-subnode项目代码config.yml配置文件，同时，修改启动脚本manager.sh。脚本内容如下：

```bash
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate astro_plantform
export PYTHONPATH=/项目路径/modeling-platform-fastapi-subnode1-backend
nohup python -u /项目路径/modeling-platform-fastapi-subnode1-backend/app/managers/node_manager.py > /项目路径/modeling-platform-fastapi-subnode1-backend/app/log/node_manager.log 2>&1 &
```

manager.sh

修改脚本中的路径与fastapi-subnode项目文件路径一致。

config.yml主要修改服务器IP、用户名和密码、以及相应路径。镜像名称部分也需要修改IP，其他保持不变。

如果副节点与主节点共用同一服务器，上述步骤不变，不过部分依赖在主节点配置已配置过（如anaconda、docker、portainer依赖），可以跳过。

部署到此基本结束，可以开始尝试启动自动建模平台了：

先执行`bash manager.sh`启动fastapi-subnode项目，再进入主节点依次执行`bash manager.sh`与`bash run.sh`即可。

注意：必须**先启动副节点**再启动主节点，否则任务会一直处于"等待"状态。
