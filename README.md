# NapCatAppImageBuild

将 NapCat 打包为 AppImage，并提供可在 Docker 无头环境中运行的镜像与使用说明。

支持架构：Linux (amd64, arm64)

—— 高效开始、少走弯路。下文按“Docker 部署（推荐）/ 本地 AppImage”两条路径分别说明，并提供 Docker Hub 与 GHCR 两种镜像源的选择指南。

## 目录

- 快速选择镜像源（Docker Hub vs GHCR）
- 快速开始（Docker，含 Linux/macOS 与 Windows PowerShell 示例）
- docker-compose 与持久化
- Web UI 与默认 Token
- 本地运行 AppImage（非 Docker）
- 常用运维与升级
- 故障排查
- 参考与致谢

---

## 快速选择镜像源（Docker Hub vs GHCR）

可从两个官方镜像源获取相同镜像：

- Docker Hub：`mlikiowa/napcat-appimage:latest`
- GitHub Container Registry (GHCR)：`ghcr.io/napneko/napcatappimagebuild:latest`

如何选择：

- 若所在网络访问 Docker Hub 更稳定，优先使用 Docker Hub；反之可选 GHCR。
- 两者镜像内容一致，可任意切换；遇到拉取失败可直接更换镜像源重试。

示例（拉取镜像）：

```bash
docker pull mlikiowa/napcat-appimage:latest
# 或者
docker pull ghcr.io/napneko/napcatappimagebuild:latest
```

---

## 快速开始（Docker，推荐）

以下示例统一暴露端口：

- 6099：Web UI 与 NapCat 接口
- 3001、6199：按需开放的其他服务端口

容器名称：`napcat`，自动重启：`--restart=always`

### Linux/macOS（bash/zsh）

使用 Docker Hub 镜像：

```bash
docker run -d \
  -p 6099:6099 \
  -p 3001:3001 \
  -p 6199:6199 \
  --name napcat \
  --restart=always \
  -v $(pwd)/data/QQ:/app/.config/QQ \
  -v $(pwd)/data/napcat:/app/napcat/config \
  mlikiowa/napcat-appimage:latest
```

或使用 GHCR 镜像：

```bash
docker run -d \
  -p 6099:6099 \
  -p 3001:3001 \
  -p 6199:6199 \
  --name napcat \
  --restart=always \
  -v $(pwd)/data/QQ:/app/.config/QQ \
  -v $(pwd)/data/napcat:/app/napcat/config \
  ghcr.io/napneko/napcatappimagebuild:latest
```

### Windows（PowerShell / pwsh）

使用 Docker Hub 镜像：

```powershell
docker run -d `
  -p 6099:6099 `
  -p 3001:3001 `
  -p 6199:6199 `
  --name napcat `
  --restart=always `
  -v ${PWD}/data/QQ:/app/.config/QQ `
  -v ${PWD}/data/napcat:/app/napcat/config `
  mlikiowa/napcat-appimage:latest
```

或使用 GHCR 镜像：

```powershell
docker run -d `
  -p 6099:6099 `
  -p 3001:3001 `
  -p 6199:6199 `
  --name napcat `
  --restart=always `
  -v ${PWD}/data/QQ:/app/.config/QQ `
  -v ${PWD}/data/napcat:/app/napcat/config `
  ghcr.io/napneko/napcatappimagebuild:latest
```

启动后查看日志与默认 Token：

```bash
docker logs -f napcat
```

---

## docker-compose 与持久化

推荐使用 docker-compose 管理运行与持久化。以下示例会在当前目录创建 `./data/QQ` 与 `./data/napcat` 用于持久化 QQ 与 NapCat 配置。

`docker-compose.yml`：

```yaml
services:
  napcat:
    image: mlikiowa/napcat-appimage:latest # 或 ghcr.io/napneko/napcatappimagebuild:latest
    container_name: napcat
    restart: always
    ports:
      - "6099:6099"
      - "3001:3001"
      - "6199:6199"
    volumes:
      - ./data/QQ:/app/.config/QQ
      - ./data/napcat:/app/napcat/config
```

常用命令：

```bash
docker compose up -d
docker compose logs -f napcat
docker compose pull && docker compose up -d
```

数据说明：

- `./data/QQ` -> 容器内 `/app/.config/QQ`：保存 QQ 客户端数据
- `./data/napcat` -> 容器内 `/app/napcat/config`：保存 NapCat 配置

---

## Web UI 与默认 Token

访问地址：`http://<宿主机IP>:6099/webui`

默认 Token：`napcat`（以容器日志为准，可在首次启动日志中看到）

---

## 本地运行 AppImage（非 Docker）

若你需要在本地 Linux 直接运行 QQ AppImage，可按以下方式：

前置条件：系统支持 FUSE 或使用 `--appimage-extract-and-run`（无需 FUSE，但需 Xvfb 支持）。

常规运行（需 FUSE/xvfb）：

```bash
chmod +x QQ-*.AppImage
./QQ-*.AppImage
```

无需 FUSE（仅使用 Xvfb）：

```bash
./QQ-*.AppImage --appimage-extract-and-run
```

提示：不同发行版对 FUSE 包名可能不同（如 `fuse3` 或 `libfuse2`）。若遇到挂载失败，请改用 `--appimage-extract-and-run`。

---

## 常用运维与升级

- 查看实时日志：

  ```bash
  docker logs -f napcat
  ```

- 更新到最新镜像并重启：

  ```bash
  # Docker Hub
  docker pull mlikiowa/napcat-appimage:latest
  docker stop napcat && docker rm napcat
  # 重新运行（参考上文 run 命令或 compose）
  
  # GHCR（可替换为 ghcr.io/...）
  docker pull ghcr.io/napneko/napcatappimagebuild:latest
  ```

- 优雅停止与删除容器：

  ```bash
  docker stop napcat
  docker rm napcat
  ```

---

## 故障排查（FAQ）

- 端口占用：若 `6099/3001/6199` 被占用，请修改宿主机映射端口，例如 `-p 16099:6099`，并据此访问 `http://<IP>:16099/webui`。

- 卷权限问题：Windows 与 Linux 文件权限差异可能导致容器内读写异常。建议将数据目录创建在当前用户有完全权限的路径下；如必要可为宿主路径放宽权限后重试。

- GHCR 拉取失败：GHCR 公有镜像通常可匿名拉取；若仓库策略调整需登录，可执行：

  ```bash
  echo <GITHUB_TOKEN> | docker login ghcr.io -u <GITHUB_USERNAME> --password-stdin
  ```

  登录后再执行 `docker pull ghcr.io/napneko/napcatappimagebuild:latest`。仍失败时可切换至 Docker Hub 源。

- FUSE 不可用（本地 AppImage）：改用 `--appimage-extract-and-run`；或安装发行版提供的 FUSE 组件（如 `fuse3`、`libfuse2`）。

---

## 参考与致谢

参考了 AppImage、Xvfb 与 Xorg dummy 等开源方案以实现无头运行与跨发行版分发。感谢相关社区与贡献者。