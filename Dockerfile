FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装核心组件 (包含 supervisor)
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    locales fonts-wqy-zenhei software-properties-common gnupg \
    openssl ca-certificates unzip supervisor \
    && rm -rf /var/lib/apt/lists/*

# 2. 中文环境与 Firefox
RUN echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen zh_CN.UTF-8
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    apt update -y && apt install -y firefox xubuntu-icon-theme

# 3. 安装 Xray
RUN wget -qO Xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -q Xray.zip -d /usr/local/bin/ && rm Xray.zip && chmod +x /usr/local/bin/xray
RUN mkdir -p /etc/xray && echo '{"inbounds":[{"port":8080,"protocol":"vless","settings":{"clients":[{"id":"9b191c56-d0fd-6889-ac99-3016ba36a189"}],"decryption":"none"},"streamSettings":{"network":"ws","wsSettings":{"path":"/"}}}],"outbounds":[{"protocol":"freedom"}]}' > /etc/xray/config.json

# 4. 配置 Supervisor (统一管理所有进程)
RUN mkdir -p /etc/supervisor/conf.d
RUN echo '[supervisord]\nnodaemon=true\nuser=root\n\n\
[program:xray]\ncommand=/usr/local/bin/xray run -c /etc/xray/config.json\n\n\
[program:vnc]\ncommand=vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 -fg\n\n\
[program:websockify]\ncommand=websockify --web=/usr/share/novnc/ 6080 localhost:5901\n\n\
[program:firefox]\ncommand=bash -c "sleep 15 && export DISPLAY=:1 && firefox --no-sandbox"\n' > /etc/supervisor/conf.d/supervisord.conf

# 5. 配置 Xstartup
RUN mkdir -p /root/.vnc && echo '#!/bin/sh\nstartxfce4' > /root/.vnc/xstartup && chmod +x /root/.vnc/xstartup

EXPOSE 5901 6080 8080
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
