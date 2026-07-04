FROM --platform=linux/amd64 ubuntu:22.04

# 基础环境设置，防止构建中途弹出交互窗口
ENV DEBIAN_FRONTEND=noninteractive

# 1. 一次性安装所有核心组件
# 包含图形界面、VNC、浏览器、网络工具、以及构建所需的 GPG 验证工具
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    locales fonts-wqy-zenhei software-properties-common gnupg \
    openssl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 2. 生成中文环境
RUN echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen zh_CN.UTF-8
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

# 3. 安装 Firefox (使用官方 PPA)
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001' > /etc/apt/preferences.d/mozilla-firefox && \
    apt update -y && apt install -y firefox xubuntu-icon-theme

# 4. 安装 Xray Core
RUN wget -qO Xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -q Xray.zip -d /usr/local/bin/ && rm Xray.zip && \
    chmod +x /usr/local/bin/xray
RUN mkdir -p /etc/xray
RUN echo '{"inbounds":[{"port":8080,"protocol":"vless","settings":{"clients":[{"id":"9b191c56-d0fd-6889-ac99-3016ba36a189"}],"decryption":"none"},"streamSettings":{"network":"ws","wsSettings":{"path":"/"}}}],"outbounds":[{"protocol":"freedom"}]}' > /etc/xray/config.json

# 5. 配置 Xfce 电源管理 (关闭自动锁屏与休眠)
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/sh\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-ac -s 0\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false\n\
startxfce4 &' > /root/.vnc/xstartup && chmod +x /root/.vnc/xstartup

# 6. 暴露端口与统一启动命令
EXPOSE 5901 6080 8080
CMD bash -c "touch /root/.Xauthority && \
    vncserver -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE && \
    openssl req -new -subj \"/C=JP\" -x509 -days 365 -nodes -out self.pem -keyout self.pem && \
    websockify -D --web=/usr/share/novnc/ --cert=self.pem 6080 localhost:5901 && \
    /usr/local/bin/xray run -c /etc/xray/config.json & \
    sleep 5 && DISPLAY=:1 firefox --no-sandbox & \
    tail -f /dev/null"
