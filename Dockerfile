FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8

# 1. 安装基础环境 + 必要的桌面组件
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies xfdesktop thunar tigervnc-standalone-server novnc websockify \
    xterm vim net-tools curl wget unzip dbus-x11 locales fonts-wqy-zenhei \
    language-pack-zh-hans software-properties-common gnupg openssl ca-certificates xauth \
    && locale-gen zh_CN.UTF-8 && update-locale LANG=zh_CN.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 Firefox (PPA)
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001' > /etc/apt/preferences.d/mozilla-firefox && \
    apt update -y && apt install -y firefox

# 3. 安装 Xray
RUN wget -qO Xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -q Xray.zip -d /usr/local/bin/ && rm Xray.zip && chmod +x /usr/local/bin/xray
RUN mkdir -p /etc/xray && echo '{"inbounds":[{"port":8080,"protocol":"vless","settings":{"clients":[{"id":"9b191c56-d0fd-6889-ac99-3016ba36a189"}],"decryption":"none"},"streamSettings":{"network":"ws","wsSettings":{"path":"/"}}}],"outbounds":[{"protocol":"freedom"}]}' > /etc/xray/config.json

# 4. 优化脚本 (添加 xfdesktop，彻底禁用沙箱)
RUN echo '#!/bin/bash\n\
export LANG=zh_CN.UTF-8\n\
export LC_ALL=zh_CN.UTF-8\n\
touch /root/.Xauthority\n\
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1\n\
# 启动 VNC\n\
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 -depth 24 --I-KNOW-THIS-IS-INSECURE\n\
sleep 2\n\
# 启动桌面管理器 + 图标显示 + 窗口管理器\n\
DISPLAY=:1 xfdesktop &\n\
DISPLAY=:1 xfwm4 --compositor=off &\n\
# 启动 Xray\n\
/usr/local/bin/xray run -c /etc/xray/config.json &\n\
# 启动 Firefox，强制关闭所有沙箱特性，防止 EACCES 崩溃\n\
DISPLAY=:1 firefox --no-sandbox --disable-sandbox --disable-gpu http://www.google.com &\n\
# 启动 novnc\n\
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

EXPOSE 6080 8080
ENTRYPOINT ["/start.sh"]
