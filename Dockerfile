FROM --platform=linux/amd64 ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 1. 基础环境与工具安装
RUN apt update && apt install -y \
    xfce4 xfce4-goodies xfce4-terminal \
    tigervnc-standalone-server novnc \
    python3-pip curl unzip wget procps net-tools iputils-ping \
    fonts-wqy-microhei fonts-wqy-zenhei language-pack-zh-hans \
    firefox firefox-locale-zh-hans jq \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 websockify
RUN pip3 install websockify

# 3. 安装 Xray Core
RUN wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip Xray-linux-64.zip -d /usr/local/bin/ && rm Xray-linux-64.zip && \
    chmod +x /usr/local/bin/xray

# 4. 创建配置目录
RUN mkdir -p /etc/xray

# 5. 设置环境
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

# 6. 复制启动脚本和模板
COPY entrypoint.sh /entrypoint.sh
COPY config.json.template /etc/xray/config.json.template
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
