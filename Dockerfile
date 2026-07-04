FROM --platform=linux/amd64 ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 1. 基础环境与工具安装
RUN apt update && apt install -y \
    xfce4 xfce4-goodies xfce4-terminal \
    tigervnc-standalone-server novnc \
    python3-pip curl unzip wget procps net-tools iputils-ping \
    fonts-wqy-microhei fonts-wqy-zenhei language-pack-zh-hans \
    firefox firefox-locale-zh-hans dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 Python 依赖
RUN pip3 install websockify

# 3. 安装 Xray Core
RUN wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip Xray-linux-64.zip -d /usr/local/bin/ && rm Xray-linux-64.zip && \
    chmod +x /usr/local/bin/xray

# 4. 写入 Xray 配置文件
RUN mkdir -p /etc/xray
RUN echo '{"inbounds":[{"port":8080,"protocol":"vless","settings":{"clients":[{"id":"9b191c56-d0fd-6889-ac99-3016ba36a189"}],"decryption":"none"},"streamSettings":{"network":"ws","wsSettings":{"path":"/"}}}],"outbounds":[{"protocol":"freedom"}]}' > /etc/xray/config.json

# 5. 设置中文环境
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

# 6. 配置启动脚本 (包含电源管理禁用与 Firefox 启动优化)
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/sh\n\
# 启动电源管理相关设置\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-ac -s 0\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false\n\
# 启动 Xfce 桌面环境\n\
startxfce4 &' > /root/.vnc/xstartup && chmod +x /root/.vnc/xstartup

# 创建统一入口脚本
RUN echo '#!/bin/bash\n\
export DISPLAY=:1\n\
# 启动 VNC\n\
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720\n\
# 启动 websockify\n\
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &\n\
# 启动 Xray\n\
/usr/local/bin/xray run -c /etc/xray/config.json &\n\
# 启动 Firefox (必须带 --no-sandbox)\n\
sleep 5 && firefox --no-sandbox http://www.google.com &\n\
tail -f /dev/null' > /entrypoint.sh && chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
