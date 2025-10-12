#!/bin/bash
# xvfb-run: minimal virtual X server for headless apps
# Usage: xvfb-run [-a] [DISPLAY_NUM] command...

# 如果第一个参数是 -a，就吞掉
if [[ "$1" == "-a" ]]; then
    shift
fi

# 默认 DISPLAY
DISPLAY_NUM=${1:-99}

# 如果第一个参数是数字，使用它作为 DISPLAY
if [[ $DISPLAY_NUM =~ ^[0-9]+$ ]]; then
    shift
else
    DISPLAY_NUM=99
fi

# 检查依赖
for cmd in Xorg; do
    if ! command -v $cmd &>/dev/null; then
        echo "Error: $cmd not found. Please install xserver-xorg-core and xserver-xorg-video-dummy."
        exit 1
    fi
done

# 临时 xorg.conf（1x1虚拟屏幕）
XORG_CONF=$(mktemp)
cat <<EOC > "$XORG_CONF"
Section "Device"
  Identifier "DummyDevice"
  Driver     "dummy"
EndSection

Section "Monitor"
  Identifier "DummyMonitor"
EndSection

Section "Screen"
  Identifier "DummyScreen"
  Device "DummyDevice"
  Monitor "DummyMonitor"
  DefaultDepth 24
  SubSection "Display"
      Depth 24
      Modes "1x1"
  EndSubSection
EndSection
EOC

# 启动 Xorg + Dummy driver
Xorg -noreset -config "$XORG_CONF" :$DISPLAY_NUM &
XORG_PID=$!

sleep 1
export DISPLAY=:$DISPLAY_NUM

# 执行用户命令
"$@"

# 清理
kill $XORG_PID
rm "$XORG_CONF"