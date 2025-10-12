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

FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        xserver-xorg-core \
        xserver-xorg-video-dummy && \
    apt-get clean && \
    apt-get autoremove -y --purge && \
    rm -rf /var/lib/apt/lists/* \
           /var/cache/apt/* \
           /tmp/* \
           /var/tmp/* && \
    rm -rf /usr/share/doc/* \
           /usr/share/man/* \
           /usr/share/info/* \
           /usr/share/locale/* \
           /var/cache/debconf/* && \
    rm -rf /usr/share/fonts/* \
    rm -rf /usr/share/icons/* \
    find /usr/lib -name '*.a' -delete 2>/dev/null || true && \
    find /usr/lib -name '*.la' -delete 2>/dev/null || true && \
    useradd -m -u 1000 -s /bin/bash napcat

WORKDIR /app
COPY --from=downloader /download/napcat.AppImage /app/napcat.AppImage
COPY xvfb-run.sh /usr/local/bin/xvfb-run

RUN chown -R napcat:napcat /app && \
    chmod +x /app/napcat.AppImage && \
    chmod +x /usr/local/bin/xvfb-run && \
    chmod 755 /usr/local/bin/xvfb-run && \
    rm -rf /tmp/* /var/tmp/*

USER napcat

CMD ["/bin/bash", "-c", "/app/napcat.AppImage --appimage-extract-and-run"]