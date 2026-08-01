# Docker Hub Build

多项目 Docker 镜像的构建与发布仓库，通过 GitHub Actions 自动构建并推送到 Docker Hub。

## 目录结构

```
.
├── <项目名>/
│   ├── Dockerfile      # 该项目镜像构建文件
│   └── version.sh      # 输出该项目当前版本号（供 CI 作为版本 tag）
├── docs/
│   └── 部署使用.md     # 部署与使用文档
└── .github/
    └── workflows/
        └── docker-hub.yml  # 构建发布工作流
```

## 项目列表

| 项目 | 镜像 | 端口 | 部署文档 |
|------|------|------|----------|
| opencode | `<账号>/opencode` | 4096 | [docs/部署使用.md#opencode](docs/部署使用.md#opencode) |

> `<账号>` 为 Docker Hub 用户名，在 Actions Secrets `DOCKERHUB_USERNAME` 中配置。

## CI 工作流说明

- **触发方式**：定时（每天 UTC 02:00）+ 手动 `workflow_dispatch`，push 不触发
- **自动发现**：扫描所有含 `Dockerfile` 的目录，逐个构建
- **多架构**：`linux/amd64` + `linux/arm64`（buildx + QEMU）
- **版本检测**：每个项目运行自身 `version.sh` 取版本号；定时任务时若该版本 tag 已在 Docker Hub 存在则跳过
- **镜像 tag**：`<账号>/<项目>:latest` + `<账号>/<项目>:<版本号>`
- **构建参数**：`OPENCODE_VERSION=<版本号>` 统一传给所有项目（不需要的项目可忽略该 arg）

## 新增项目

1. 新建 `<项目名>/Dockerfile`
2. 新建 `<项目名>/version.sh`，输出版本号，例如：
   ```bash
   #!/usr/bin/env bash
   echo "1.2.3"
   ```
3. 在本文件项目列表补一行，并在 [docs/部署使用.md](docs/部署使用.md) 末尾追加该项目的部署小节

无需改动 workflow。提交推送后手动触发或等待定时任务即可。

## 首次配置

在 GitHub 仓库 `Settings → Secrets and variables → Actions` 配置：

- `DOCKERHUB_USERNAME`：Docker Hub 用户名
- `DOCKERHUB_TOKEN`：Docker Hub Access Token

## 相关文档

- 部署与使用：[docs/部署使用.md](docs/部署使用.md)
