FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装核心组件
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

# 4. 关键补全：配置 xstartup 以支持 startxfce4
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/sh\nstartxfce4' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# 5. 配置 VNC 启动脚本 (清理锁文件并启动)
RUN echo '#!/bin/sh\n\
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1\n\
vncserver -kill :1 >/dev/null 2>&1\n\
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720\n\
sleep 3\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-ac -n -t int -s 0\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -n -t int -s 0\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -n -t bool -s false\n\
tail -f /root/.vnc/*.log' > /usr/local/bin/start_vnc.sh && chmod +x /usr/local/bin/start_vnc.sh

# 6. 配置 Supervisor
RUN echo '[supervisord]\nnodaemon=true\nuser=root\n\n\
[program:xray]\ncommand=/usr/local/bin/xray run -c /etc/xray/config.json\n\n\
[program:vnc]\ncommand=/usr/local/bin/start_vnc.sh\nautorestart=true\n\n\
[program:websockify]\ncommand=websockify --web=/usr/share/novnc/ 6080 localhost:5901\n\n\
[program:firefox]\ncommand=bash -c "sleep 20 && export DISPLAY=:1 && firefox --no-sandbox http://www.google.com"\nautorestart=true\n' > /etc/supervisor/conf.d/supervisord.conf

EXPOSE 5901 6080 8080
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
