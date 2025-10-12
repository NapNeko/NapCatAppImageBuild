# NapCatAppImageBuild

将 NapCat 打包为 AppImage，并提供可在 Docker 无头环境中运行的镜像和使用说明。

支持架构：Linux (amd64, arm64)

## 快速开始

1) 以 Docker 运行（推荐）

```bash
docker run -d \
  -p 6099:6099 \
  -p 3001:3001 \
  -p 6199:6199 \
  --name napcat \
  --restart=always \
  mlikiowa/napcat-appimage:latest
```

拉取镜像（可选）：

```bash
docker pull mlikiowa/napcat-appimage:latest
# 或：ghcr.io/napneko/napcatappimagebuild:latest
```

查看容器日志与默认 Token：

```bash
docker logs napcat
```

2) 直接运行 AppImage（本地 Linux）

常规运行（需要 FUSE/xvfb 支持）：

```bash
chmod +x QQ-*.AppImage
./QQ-*.AppImage
```

无需 FUSE（仅使用 Xvfb）：

```bash
./QQ-*.AppImage --appimage-extract-and-run
```

## 持久化与配置路径

- QQ 数据：/app/.config/QQ
- NapCat 配置：/app/napcat/config

在 Docker 中请将这些路径映射为卷以保留数据，例如：

```yaml
volumes:
  - ./data/QQ:/app/.config/QQ
  - ./data/napcat:/app/napcat/config
```

## Web UI

访问： http://<宿主机IP>:6099/webui

默认 Token：napcat（见容器日志以确认）

## 参考与致谢

参考了 AppImage、Xvfb 与 Xorg dummy 等开源方案以实现无头运行和跨发行版分发。