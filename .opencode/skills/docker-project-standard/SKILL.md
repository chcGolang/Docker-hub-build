---
name: docker-project-standard
description: 在本多项目镜像仓库中新增项目、Dockerfile、Docker Hub 镜像、GitHub Actions 构建或部署文档时使用，并严格遵循仓库规范。
---

# Docker 项目规范

本仓库用于构建多个 Docker 镜像并发布到 Docker Hub。新增或修改任何镜像项目时，都必须遵循本规范。

## 仓库规则

- 每个项目放在仓库根目录下的独立目录：`<项目名>/`。
- 每个项目必须包含 `<项目名>/Dockerfile`。
- 每个项目根目录**只能有一个** `Dockerfile`，子目录中不得再放置 Dockerfile，否则会被 `find . -name Dockerfile` 误判为独立项目，导致 workflow 的版本解析失败。
- 每个项目必须包含可执行的 `<项目名>/version.sh`，且与 Dockerfile 位于同一目录。
- 除非现有 workflow 无法满足需求，否则不要新增项目专用 workflow。
- 现有 workflow 会自动发现所有包含 `Dockerfile` 的目录。
- workflow 只允许定时任务和手动 `workflow_dispatch` 触发，未经明确同意不得添加 `push` 触发。
- 文档中的 Docker Hub 命名空间为 `chcgolang`，workflow 仍使用 `secrets.DOCKERHUB_USERNAME`。

## 新增项目流程

新增项目时必须完成以下步骤：

1. 创建 `<项目名>/Dockerfile`。
2. 创建 `<项目名>/version.sh`。
3. 将 `version.sh` 设置为可执行。
4. 确保 `version.sh` 只输出一个可用的 Docker tag 版本号，失败时返回非零状态。
5. 在 `README.md` 的项目列表中增加一行。
6. 在 `docs/部署使用.md` 末尾追加项目部署章节。
7. 检查 Dockerfile、版本脚本、文档和 workflow 的兼容性。
8. 最终报告修改文件和验证结果。

## Dockerfile 要求

- 优先选择适合项目的精简且受维护的基础镜像。
- Debian 安装软件包时使用 `--no-install-recommends`，并在同一层清理 `/var/lib/apt/lists/*`。
- 上游安装器支持指定版本时，使用构建参数 `ARG` 固定构建版本。
- 优先使用项目官方安装方式和官方 release 来源。
- Debian 基础镜像在软件安装完成后，将 apt 源切换为国内镜像（清华 TUNA），并执行 `apt-get update`。
- 官方 API 或 release 地址可自动获取最新版时，不要在 Dockerfile 中手动维护 latest 版本号。
- 网络服务必须通过 `EXPOSE` 声明端口。
- 设置明确的 `WORKDIR`，根据项目实际用途决定，不要默认使用 `/workspace`。
- 使用 exec 形式的 `CMD` 或 `ENTRYPOINT`。
- 运行时配置使用环境变量，不要把密钥写入镜像。
- 如果项目需要配置、认证、状态或缓存数据，必须分别记录容器路径并提供持久化卷挂载。
- 除非用户明确要求，不要给 opencode 添加 `OPENCODE_DISABLE_AUTOUPDATE=true`；默认保持运行时自动更新。

## 版本脚本要求

`version.sh` 是 CI 获取 Docker 版本 tag 的唯一来源。

```bash
#!/usr/bin/env bash
set -euo pipefail

# 查询项目官方 release 来源，并且只输出版本号。
```

要求：

- 查询项目官方 release API 或官方 release 页面。
- 如果 Docker tag 不需要 `v` 前缀，则去掉开头的 `v`。
- stdout 只输出一个版本字符串。
- 诊断信息应输出到 stderr。
- 不得静默回退到虚假的或过期的版本号。
- 尽可能使用 `chmod +x <项目名>/version.sh` 并本地验证。

opencode 必须使用官方 `anomalyco/opencode` 最新 release API，与官方安装脚本使用的来源保持一致。

## 镜像 Tag 与 CI

标准镜像名称：

```text
chcgolang/<项目名>:latest
chcgolang/<项目名>:<版本号>
```

现有 `.github/workflows/docker-hub.yml` 提供：

- 自动发现所有包含 `Dockerfile` 的项目目录。
- 使用 Buildx 和 QEMU 构建 `linux/amd64`、`linux/arm64`。
- 使用 `DOCKERHUB_USERNAME`、`DOCKERHUB_TOKEN` 登录 Docker Hub。
- 通过每个项目的 `version.sh` 获取版本。
- 每天 UTC 02:00 定时检查更新。
- 定时构建时，如果版本 tag 已存在则跳过。
- 手动触发 workflow 时无条件重新构建。

新增项目不需要修改 workflow。只有当新项目需要现有项目约定无法表达的行为时，才允许修改 workflow，并且必须先询问用户。

当前 workflow 会向所有项目传入 `OPENCODE_VERSION=<版本号>` build-arg。不需要该参数的项目可以忽略它。修改或删除这个公共参数前，必须检查所有项目。

## 文档要求

更新 `README.md` 时必须包含：

- 项目名称。
- Docker Hub 镜像名称。
- 宿主机/容器端口；非网络服务使用 `-`。
- 指向项目部署章节的链接。

更新 `docs/部署使用.md` 时必须追加项目章节，并包含：

- 镜像名称和支持的 tag。
- 镜像用途说明。
- `docker pull` 命令。
- 完整的 `docker run` 示例。
- 适用时提供 Docker Compose 示例。
- 端口映射和工作目录挂载。
- 必需环境变量和鉴权说明。
- 配置、认证、state、cache 数据卷路径。
- 更新和回滚方式。
- 查看日志、重启、删除容器等常用命令。

opencode 的已知路径如下，除非上游发生变化，否则必须保持一致：

```text
/workspace
/root/.config/opencode
/root/.local/share/opencode
/root/.local/state/opencode
/root/.cache/opencode
```

`/root/.local/state/opencode` 存放会话和项目数据，容器重建前必须特别提醒用户保留对应的数据卷。

## 验证清单

完成项目后必须检查：

- `Dockerfile` 位于预期的顶层项目目录。
- `version.sh` 存在、可执行且只输出一个版本号。
- Dockerfile 正确使用版本 build-arg（如果项目需要）。
- 没有提交任何密钥。
- 文档中的镜像名、tag、端口、挂载和环境变量一致。
- 项目能够被 `find . -name Dockerfile` 自动发现。
- workflow 没有意外增加 `push` 触发。
- 修改 workflow 时验证 YAML 语法。
- 条件允许时执行本地 Docker build。
- 只有 workflow 结果明确成功时，才能声称镜像已发布到 Docker Hub。

## Git 安全规则

- 未经当前轮次用户明确同意，绝不执行 `git commit`、`git push` 或创建 Pull Request。
- 用户要求提交前，先检查 `git status`、`git diff` 和近期提交记录。
- 只暂存本次任务涉及的文件。
- 最终回复中明确说明仍未提交的修改。
