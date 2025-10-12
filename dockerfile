# 基于 glibc 的优化 Xvfb 构建
FROM debian:bookworm-slim AS downloader
ARG TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates sed && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /download
RUN ARCH_SUFFIX=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64") && \
    APPIMAGE_URL=$(wget -qO- https://api.github.com/repos/NapNeko/NapCatAppImageBuild/releases/latest | \
    sed -n 's/.*"browser_download_url": "\([^"]*NapCat[^"]*'"${ARCH_SUFFIX}"'\.AppImage\)".*/\1/p' | head -n 1) && \
    wget -O /download/napcat.AppImage "$APPIMAGE_URL" && \
    chmod +x /download/napcat.AppImage

# 从源码构建最小化的 Xvfb (基于 glibc)
FROM debian:bookworm-slim AS xvfb-builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    git \
    wget \
    flex \
    bison \
    libfontconfig1-dev \
    libfreetype6-dev \
    libx11-dev \
    libxext-dev \
    libxfont-dev \
    libxkbfile-dev \
    libxrandr-dev \
    libpixman-1-dev \
    xorg-dev \
    xtrans-dev \
    zlib1g-dev \
    libexpat1-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 下载 Xorg 服务器源码
RUN wget https://www.x.org/archive/individual/xserver/xorg-server-21.1.8.tar.xz && \
    tar -xf xorg-server-21.1.8.tar.xz

WORKDIR /build/xorg-server-21.1.8

# 配置编译选项 - 只构建 Xvfb，禁用所有不必要的功能
RUN ./configure \
    --prefix=/usr/local \
    --enable-xvfb \
    --disable-xorg \
    --disable-xnest \
    --disable-xquartz \
    --disable-xwin \
    --disable-xephyr \
    --disable-kdrive \
    --disable-dri \
    --disable-dri2 \
    --disable-dri3 \
    --disable-present \
    --disable-glamor \
    --disable-xf86vidmode \
    --disable-xace \
    --disable-xselinux \
    --disable-xcsecurity \
    --disable-tslib \
    --disable-dbe \
    --disable-xf86bigfont \
    --disable-dpms \
    --disable-screensaver \
    --disable-xdmcp \
    --disable-xdm-auth-1 \
    --disable-config-udev \
    --disable-config-hal \
    --disable-systemd-logind \
    --disable-suid-wrapper \
    --disable-install-setuid \
    --disable-unit-tests \
    --disable-docs \
    --disable-devel-docs \
    --without-dtrace \
    --without-doxygen \
    --without-xmlto \
    --without-fop \
    --with-builderstring="minimal-xvfb-glibc" \
    CFLAGS="-Os -ffunction-sections -fdata-sections" \
    LDFLAGS="-Wl,--gc-sections"

# 编译并安装，只编译 Xvfb
RUN make -j$(nproc) hw/vfb/Xvfb && \
    install -D -s hw/vfb/Xvfb /usr/local/bin/Xvfb

# 找出运行时依赖的最小库集合
RUN ldd /usr/local/bin/Xvfb | grep "=> /" | awk '{print $3}' | sort | uniq > /tmp/required-libs.txt

# 创建运行时镜像
FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive

# 只安装运行 Xvfb 所需的最小库
RUN apt-get update && apt-get install -y --no-install-recommends \
    libc6 \
    libfontconfig1 \
    libfreetype6 \
    libx11-6 \
    libxext6 \
    libxfont2 \
    libxkbfile1 \
    libpixman-1-0 \
    zlib1g \
    libexpat1 \
    libpng16-16 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && useradd -m -u 1000 -s /bin/bash napcat

# 从构建阶段复制优化的 Xvfb
COPY --from=xvfb-builder /usr/local/bin/Xvfb /usr/local/bin/Xvfb

# 创建最小的字体配置
RUN mkdir -p /usr/share/fonts/truetype && \
    mkdir -p /etc/fonts && \
    echo '<?xml version="1.0"?><fontconfig><dir>/usr/share/fonts</dir><cachedir>/tmp/fontconfig</cachedir></fontconfig>' > /etc/fonts/fonts.conf

WORKDIR /app
COPY --from=downloader /download/napcat.AppImage /app/napcat.AppImage
RUN chown -R napcat:napcat /app && chmod +x /app/napcat.AppImage

USER napcat

# 使用优化的启动参数
CMD ["/bin/bash", "-c", "/usr/local/bin/Xvfb :99 -screen 0 1024x768x16 -nolisten tcp -dpi 96 -ac & export DISPLAY=:99 && exec /app/napcat.AppImage --appimage-extract-and-run"]