FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. 基础组件与中文环境安装
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm init systemd vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    locales fonts-wqy-zenhei software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# 2. 生成中文语言包
RUN echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen zh_CN.UTF-8
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

# 3. Firefox PPA 安装
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001' > /etc/apt/preferences.d/mozilla-firefox && \
    apt update -y && apt install -y firefox xubuntu-icon-theme

# 4. 安装 Xray Core
RUN wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip Xray-linux-64.zip -d /usr/local/bin/ && rm Xray-linux-64.zip && \
    chmod +x /usr/local/bin/xray
RUN mkdir -p /etc/xray
RUN echo '{"inbounds":[{"port":8080,"protocol":"vless","settings":{"clients":[{"id":"9b191c56-d0fd-6889-ac99-3016ba36a189"}],"decryption":"none"},"streamSettings":{"network":"ws","wsSettings":{"path":"/"}}}],"outbounds":[{"protocol":"freedom"}]}' > /etc/xray/config.json

# 5. 配置电源管理与自动启动脚本
# 这里禁用了电源管理器以防止 VNC 锁屏，并确保 Firefox 和 Xray 同时运行
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/sh\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-ac -s 0\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false\n\
startxfce4 &' > /root/.vnc/xstartup && chmod +x /root/.vnc/xstartup

# 6. 统一启动入口
# 包含了 VNC, websockify, Xray 以及自动启动 Firefox
EXPOSE 5901 6080 8080
CMD bash -c "touch /root/.Xauthority && \
    vncserver -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE && \
    openssl req -new -subj \"/C=JP\" -x509 -days 365 -nodes -out self.pem -keyout self.pem && \
    websockify -D --web=/usr/share/novnc/ --cert=self.pem 6080 localhost:5901 && \
    /usr/local/bin/xray run -c /etc/xray/config.json & \
    sleep 5 && DISPLAY=:1 firefox --no-sandbox & \
    tail -f /dev/null"
