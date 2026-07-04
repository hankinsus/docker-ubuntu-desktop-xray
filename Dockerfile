FROM --platform=linux/amd64 ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 1. 基础环境与工具安装 (加入 dbus 用于支持桌面程序)
RUN apt update && apt install -y \
    xfce4 xfce4-goodies xfce4-terminal \
    tigervnc-standalone-server novnc \
    python3-pip curl unzip wget procps net-tools iputils-ping \
    fonts-wqy-microhei fonts-wqy-zenhei language-pack-zh-hans \
    firefox firefox-locale-zh-hans dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 websockify
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

# 6. 处理电源管理与 Firefox 启动配置
# 创建启动脚本，将逻辑封装以便于管理
RUN echo '#!/bin/bash\n\
# 禁用 Xfce 电源管理以防锁屏/休眠\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-ac -s 0\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0\n\
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false\n\
# 启动 VNC\n\
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720\n\
# 启动 websockify\n\
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &\n\
# 启动 Xray\n\
/usr/local/bin/xray run -c /etc/xray/config.json &\n\
# 启动桌面环境\n\
startxfce4 &\n\
tail -f /dev/null' > /entrypoint.sh && chmod +x /entrypoint.sh

# Firefox 作为 root 启动需添加 --no-sandbox
# 建议在 VNC 桌面内通过菜单启动，若需自启可添加到 entrypoint
CMD ["/entrypoint.sh"]
