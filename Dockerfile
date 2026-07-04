FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8

# 1. 核心安装
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies thunar tigervnc-standalone-server novnc websockify \
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

# 4. 终极启动逻辑
RUN echo '#!/bin/bash\n\
export LANG=zh_CN.UTF-8\n\
export LC_ALL=zh_CN.UTF-8\n\
touch /root/.Xauthority\n\
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1\n\
# 启动 VNC\n\
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 -depth 24 --I-KNOW-THIS-IS-INSECURE\n\
sleep 3\n\
# 使用 dbus-run-session 启动 Xfce，解决所有总线错误\n\
dbus-run-session -- xfce4-session --display=:1 &\n\
/usr/local/bin/xray run -c /etc/xray/config.json &\n\
# 彻底移除沙箱参数，防止内核级 EACCES 拒绝访问\n\
DISPLAY=:1 firefox --no-sandbox --disable-gpu --disable-dev-shm-usage --profile /tmp/firefox_profile http://www.google.com &\n\
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

EXPOSE 6080 8080
ENTRYPOINT ["/start.sh"]
