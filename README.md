# NapCatAppImageBuild

将 QQ 和 NapCat 打包为 Linux AppImage，支持 amd64 / arm64。

## 使用

安装 `xvfb-run`、`xauth`，下载 [对应架构的 AppImage](https://github.com/NapNeko/NapCatAppImageBuild/releases/latest)，保存为 `NapCat.AppImage`：

```bash
chmod +x NapCat.AppImage
./NapCat.AppImage
```

没有 FUSE 时使用 `./NapCat.AppImage --appimage-extract-and-run`。快速登录添加 `-q 123456789`。

保持工作目录固定，以保留配置和插件；更新时只替换 AppImage 文件。

## 构建

在 Actions 中运行发布工作流，填写 NapCat 版本和 QQ 双架构下载地址。

[Docker 部署](https://napneko.github.io/guide/boot/Shell#docker)
