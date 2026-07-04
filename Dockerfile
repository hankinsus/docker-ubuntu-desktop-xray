FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# 1. 基础环境安装
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    xvfb xterm vim net-tools curl wget unzip dbus-x11 \
    locales fonts-wqy-zenhei software-properties-common gnupg \
    openssl ca-certificates supervisor \
    && rm -rf /var/lib/apt/lists/*

# 2. 中文环境与 Firefox
RUN echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen zh_CN.UTF-8
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    apt update -y && apt install -y firefox

# 3. 安装 Xray
RUN wget -qO Xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -q Xray.zip -d /usr/local/bin/ && rm Xray.zip && chmod +x /usr/local/bin/xray
RUN mkdir -p /etc/xray && echo '{"inbounds":[{"port":8080,"protocol":"vless","settings":{"clients":[{"id":"9b191c56-d0fd-6889-ac99-3016ba36a189"}],"decryption":"none"},"streamSettings":{"network":"ws","wsSettings":{"path":"/"}}}],"outbounds":[{"protocol":"freedom"}]}' > /etc/xray/config.json

# 4. 创建启动脚本 (不再依赖 vncpasswd，直接绕过密码验证)
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/bash\n\
# 启动虚拟屏幕\n\
Xvfb :1 -screen 0 1280x720x24 &\n\
sleep 2\n\
# 启动窗口管理器\n\
xfwm4 &\n\
# 启动 VNC 服务 (强制禁用密码验证，防止 127 错误)\n\
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE &\n\
# 启动 Xray\n\
/usr/local/bin/xray run -c /etc/xray/config.json &\n\
# 启动 Firefox\n\
export DISPLAY=:1\n\
firefox --no-sandbox http://www.google.com &\n\
# 启动 noVNC\n\
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080\n\
# 保持容器运行\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

EXPOSE 6080 8080

ENTRYPOINT ["/start.sh"]
