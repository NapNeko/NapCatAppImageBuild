FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive

# 创建用户并安装必要的包，然后进行彻底清理
RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        xserver-xorg-core \
        xserver-xorg-video-dummy && \
    apt-get clean && \
    apt-get autoremove -y --purge && \
    rm -rf /var/lib/apt/lists/* \
           /var/cache/apt/* \
           /tmp/* \
           /var/tmp/* \
           /var/log/* && \
    rm -rf /usr/share/doc/* \
           /usr/share/man/* \
           /usr/share/info/* \
           /usr/share/locale/* \
           /usr/share/lintian/* \
           /usr/share/linda/* \
           /var/cache/debconf/* && \
    rm -rf /usr/share/fonts/* \
           /usr/share/icons/* \
           /usr/share/pixmaps/* \
           /usr/share/sounds/* && \
    find /usr/lib -name '*.a' -delete 2>/dev/null || true && \
    find /usr/lib -name '*.la' -delete 2>/dev/null || true && \
    find /usr/share -name '*.py[co]' -delete 2>/dev/null || true && \
    find /usr -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true && \
    useradd -m -u 1000 -s /bin/bash napcat

WORKDIR /app

# 先设置正确的所有权，然后复制文件，避免 chown 操作创建新层
USER napcat
COPY --chown=napcat:napcat ./download/napcat.AppImage /app/napcat.AppImage
COPY --chown=napcat:napcat xvfb-run.sh /usr/local/bin/xvfb-run

# 设置执行权限
USER root
RUN chmod +x /app/napcat.AppImage && \
    chmod +x /usr/local/bin/xvfb-run && \
    chmod 755 /usr/local/bin/xvfb-run

USER napcat

USER napcat

CMD ["/bin/bash", "-c", "/app/napcat.AppImage --appimage-extract-and-run"]