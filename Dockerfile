FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# 1. 安装核心组件 (修复 snap 报错，直接使用 chromium)
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server tigervnc-common novnc websockify \
    chromium-browser xterm vim net-tools curl wget unzip dbus-x11 \
    locales fonts-wqy-zenhei software-properties-common gnupg \
    openssl ca-certificates supervisor \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 Xray
RUN wget -qO Xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -q Xray.zip -d /usr/local/bin/ && rm Xray.zip && chmod +x /usr/local/bin/xray
RUN mkdir -p /etc/xray && echo '{"inbounds":[{"port":8080,"protocol":"vless","settings":{"clients":[{"id":"9b191c56-d0fd-6889-ac99-3016ba36a189"}],"decryption":"none"},"streamSettings":{"network":"ws","wsSettings":{"path":"/"}}}],"outbounds":[{"protocol":"freedom"}]}' > /etc/xray/config.json

# 3. 创建启动脚本 (核心：按顺序启动 vncserver -> xfce -> xray -> novnc)
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/bash\n\
# 清理残留\n\
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1\n\
# 启动 VNC 服务 (5901端口)\n\
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 -depth 24 --I-KNOW-THIS-IS-INSECURE\n\
# 启动窗口管理器\n\
DISPLAY=:1 xfwm4 &\n\
# 启动 Xray\n\
/usr/local/bin/xray run -c /etc/xray/config.json &\n\
# 启动 Chromium\n\
DISPLAY=:1 chromium-browser --no-sandbox --disable-gpu http://www.google.com &\n\
# 启动 noVNC 代理 (监听 6080 映射到 5901)\n\
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080\n\
# 保持进程\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

# 4. 暴露端口
EXPOSE 6080 8080

# 5. 启动
ENTRYPOINT ["/start.sh"]
