FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装核心组件
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    locales fonts-wqy-zenhei software-properties-common \
    gnupg ca-certificates unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. 中文环境与 Firefox
RUN echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen zh_CN.UTF-8
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    apt update -y && apt install -y firefox

# 3. 安装 Xray
RUN wget -qO Xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -q Xray.zip -d /usr/local/bin/ && rm Xray.zip && chmod +x /usr/local/bin/xray
RUN mkdir -p /etc/xray && echo '{"inbounds":[{"port":8080,"protocol":"vless","settings":{"clients":[{"id":"9b191c56-d0fd-6889-ac99-3016ba36a189"}],"decryption":"none"},"streamSettings":{"network":"ws","wsSettings":{"path":"/"}}}],"outbounds":[{"protocol":"freedom"}]}' > /etc/xray/config.json

# 4. 准备 VNC 启动环境
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/sh\nstartxfce4' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# 5. 启动脚本 (直接运行，不通过 supervisor)
RUN echo '#!/bin/bash\n\
# 清理锁文件\n\
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X\n\
# 启动 VNC 并指定不启动桌面压缩，避免 255 错误\n\
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720\n\
# 启动其他服务\n\
websockify -D --web=/usr/share/novnc/ 6080 localhost:5901\n\
/usr/local/bin/xray run -c /etc/xray/config.json &\n\
# 等待并启动 Firefox\n\
sleep 15 && export DISPLAY=:1 && firefox --no-sandbox http://www.google.com &\n\
# 保持容器运行\n\
tail -f /root/.vnc/*.log' > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 5901 6080 8080
CMD ["/bin/bash", "/entrypoint.sh"]
