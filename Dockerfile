FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV LANG=zh_CN.UTF-8

# 1. 基础环境：移除所有可能产生 snap 依赖的包
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server tigervnc-common novnc websockify \
    xterm vim net-tools curl wget unzip dbus-x11 locales fonts-wqy-zenhei \
    software-properties-common gnupg openssl ca-certificates supervisor xauth \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 Firefox (从 PPA 安装，不是 snap)
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001' > /etc/apt/preferences.d/mozilla-firefox && \
    apt update -y && apt install -y firefox

# 3. 安装 Xray
RUN wget -qO Xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -q Xray.zip -d /usr/local/bin/ && rm Xray.zip && chmod +x /usr/local/bin/xray
RUN mkdir -p /etc/xray && echo '{"inbounds":[{"port":8080,"protocol":"vless","settings":{"clients":[{"id":"9b191c56-d0fd-6889-ac99-3016ba36a189"}],"decryption":"none"},"streamSettings":{"network":"ws","wsSettings":{"path":"/"}}}],"outbounds":[{"protocol":"freedom"}]}' > /etc/xray/config.json

# 4. 生成启动脚本 (修复 Xauthority 和窗口管理器)
RUN echo '#!/bin/bash\n\
# 授权 X11\n\
touch /root/.Xauthority\n\
xauth generate :1 . trusted\n\
\n\
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1\n\
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 -depth 24 --I-KNOW-THIS-IS-INSECURE\n\
\n\
# 等待 VNC 初始化\n\
sleep 3\n\
\n\
# 启动窗口管理器 (使用 --replace 强制替换，防止之前的冲突)\n\
DISPLAY=:1 xfwm4 --replace &\n\
\n\
/usr/local/bin/xray run -c /etc/xray/config.json &\n\
\n\
# 启动 Firefox (指定 --no-sandbox 且无需 snap)\n\
DISPLAY=:1 firefox --no-sandbox http://www.google.com &\n\
\n\
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

EXPOSE 6080 8080
ENTRYPOINT ["/start.sh"]
