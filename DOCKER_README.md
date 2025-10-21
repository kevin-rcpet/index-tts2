# IndexTTS2 Docker 使用指南

本文档说明如何使用 Docker 容器运行 IndexTTS2 项目。

## 📋 前置要求

1. **Docker 和 Docker Compose V2**
   - 安装 [Docker](https://docs.docker.com/get-docker/)
   - Docker Compose V2 已内置在 Docker Desktop 中

2. **NVIDIA GPU 支持**（推荐）
   - 安装 [NVIDIA 驱动](https://www.nvidia.com/download/index.aspx)
   - 安装 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
   
   验证 GPU 支持：
   ```bash
   docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
   ```

3. **模型文件**
   确保 `checkpoints` 目录包含所有必需的模型文件：
   - `bpe.model`
   - `gpt.pth`
   - `config.yaml`
   - `s2mel.pth`
   - `wav2vec2bert_stats.pt`

## 🚀 快速开始

### 方法一：使用 Docker Compose（推荐）

1. **构建镜像**
   ```bash
   docker compose build
   ```

2. **启动容器**
   ```bash
   docker compose up -d
   ```

3. **查看日志**
   ```bash
   docker compose logs -f
   ```

4. **访问 Web UI**
   打开浏览器访问：`http://localhost:7860`

5. **停止容器**
   ```bash
   docker compose down
   ```

### 方法二：使用 Docker 命令

1. **构建镜像**
   ```bash
   docker build -t indextts2:latest .
   ```

2. **运行容器**
   ```bash
   docker run -d \
     --name indextts2 \
     --gpus all \
     -p 7860:7860 \
     -v ./checkpoints:/app/checkpoints \
     -v ./outputs:/app/outputs \
     -v ./prompts:/app/prompts \
     indextts2:latest
   ```

3. **查看日志**
   ```bash
   docker logs -f indextts2
   ```

4. **停止容器**
   ```bash
   docker stop indextts2
   docker rm indextts2
   ```

## ⚙️ 自定义配置

### 修改端口

编辑 `compose.yaml` 文件，修改端口映射：
```yaml
ports:
  - "8080:7860"  # 将主机端口改为 8080
```

或在运行时指定：
```bash
docker run -p 8080:7860 ... indextts2:latest
```

### 启用 FP16 推理

编辑 `compose.yaml`，修改 command：
```yaml
command: ["uv", "run", "webui.py", "--host", "0.0.0.0", "--port", "7860", "--fp16"]
```

### 启用 DeepSpeed

```yaml
command: ["uv", "run", "webui.py", "--host", "0.0.0.0", "--port", "7860", "--deepspeed"]
```

### 使用 HuggingFace 镜像

取消 `compose.yaml` 中的环境变量注释：
```yaml
environment:
  - HF_ENDPOINT=https://hf-mirror.com
```

## 📂 目录结构

容器内的目录映射：

```
主机                    容器
./checkpoints     →    /app/checkpoints  (模型文件)
./outputs         →    /app/outputs      (生成的音频)
./prompts         →    /app/prompts      (音色参考音频)
```

## 🔧 常见问题

### GPU 未被识别

确保已安装 NVIDIA Container Toolkit：
```bash
# Ubuntu/Debian
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### 模型文件缺失

下载模型文件到 `checkpoints` 目录：
```bash
# 使用 uv tool 下载
uv tool install "huggingface-hub[cli,hf_xet]"
hf download IndexTeam/IndexTTS-2 --local-dir=checkpoints
```

### 内存不足

增加 Docker 的内存限制，或在 `compose.yaml` 中添加资源限制：
```yaml
deploy:
  resources:
    limits:
      memory: 16G
```

### 端口已被占用

修改主机端口或停止占用 7860 端口的进程：
```bash
# 查找占用端口的进程
lsof -i :7860

# 或使用其他端口
docker compose down
# 修改 compose.yaml 中的端口配置
docker compose up -d
```

## 📊 性能优化

### 使用 FP16 降低显存占用
```bash
docker compose run indextts2 uv run webui.py --host 0.0.0.0 --fp16
```

### 使用 CUDA 内核加速
```bash
docker compose run indextts2 uv run webui.py --host 0.0.0.0 --cuda_kernel
```

## 🛠️ 开发模式

如需在容器中进行开发，可以挂载源代码：

```yaml
volumes:
  - ./checkpoints:/app/checkpoints
  - ./outputs:/app/outputs
  - ./prompts:/app/prompts
  - ./indextts:/app/indextts  # 挂载源代码
  - ./webui.py:/app/webui.py
```

## 📝 其他命令参数

查看所有可用参数：
```bash
docker compose run indextts2 uv run webui.py -h
```

常用参数：
- `--verbose`: 启用详细日志
- `--port`: 指定端口（默认 7860）
- `--host`: 指定主机（默认 0.0.0.0）
- `--model_dir`: 模型目录（默认 ./checkpoints）
- `--fp16`: 使用 FP16 推理
- `--deepspeed`: 使用 DeepSpeed 加速
- `--cuda_kernel`: 使用 CUDA 内核

## 🔗 相关链接

- [IndexTTS2 项目主页](https://github.com/index-tts/index-tts)
- [Docker 文档](https://docs.docker.com/)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)
