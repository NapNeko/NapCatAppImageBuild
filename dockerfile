FROM alpine:latest AS downloader
ARG TARGETARCH
RUN apk add --no-cache wget ca-certificates
WORKDIR /download
RUN ARCH_SUFFIX=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64") && \
    APPIMAGE_URL=$(wget -qO- https://api.github.com/repos/NapNeko/NapCatAppImageBuild/releases/latest | grep -oP "\"browser_download_url\": \"\\K[^\"]*NapCat.*${ARCH_SUFFIX}\\.AppImage(?=\")" | head -n 1) && \
    wget -O /download/napcat.AppImage "$APPIMAGE_URL" && \
    chmod +x /download/napcat.AppImage
FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    libfuse2 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -u 1000 -s /bin/bash napcat
WORKDIR /app
COPY --from=downloader /download/napcat.AppImage /app/napcat.AppImage
RUN chown -R napcat:napcat /app
USER napcat
CMD exec /app/napcat.AppImage --appimage-extract-and-run
