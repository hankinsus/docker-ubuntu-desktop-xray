FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# 1. 基础环境安装
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server tigervnc-common novnc websockify \
    xvfb xterm vim net-tools curl wget unzip dbus-x11 \
    locales fonts-wqy-zenhei software-properties-common gnupg \
    openssl ca-certificates supervisor \
    && rm -rf /var/lib/apt/lists/*

# 2. 中文环境与 Firefox
RUN echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen zh_CN.UTF-8
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    apt update -y && apt install -y firefox

# 3. 集成 Xray 安装与配置 (完全在 Dockerfile 中定义)
RUN wget -qO Xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -q Xray.zip -d /usr/local/bin/ && rm Xray.zip && chmod +x /usr/local/bin/xray
RUN mkdir -p /etc/xray && echo '{"inbounds":[{"port":8080,"protocol":"vless","settings":{"clients":[{"id":"9b191c56-d0fd-6889-ac99-3016ba36a189"}],"decryption":"none"},"streamSettings":{"network":"ws","wsSettings":{"path":"/"}}}],"outbounds":[{"protocol":"freedom"}]}' > /etc/xray/config.json

# 4. 一次性生成启动逻辑 (无需外部脚本文件)
RUN mkdir -p /root/.vnc && echo "password" | vncpasswd -f > /root/.vnc/passwd && chmod 600 /root/.vnc/passwd
RUN echo '#!/bin/bash\n\
Xvfb :1 -screen 0 1280x720x24 &\n\
sleep 2\n\
xfwm4 &\n\
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE &\n\
/usr/local/bin/xray run -c /etc/xray/config.json &\n\
export DISPLAY=:1\n\
firefox --no-sandbox http://www.google.com &\n\
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

# 5. 暴露端口与执行启动
EXPOSE 6080 8080
ENTRYPOINT ["/start.sh"]
