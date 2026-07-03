FROM --platform=linux/amd64 ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc \
    python3-pip curl unzip wget procps jq \
    fonts-wqy-microhei && rm -rf /var/lib/apt/lists/*

RUN pip3 install websockify
RUN wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip Xray-linux-64.zip -d /usr/local/bin/ && rm Xray-linux-64.zip && chmod +x /usr/local/bin/xray

RUN mkdir -p /etc/xray
COPY config.json.template /etc/xray/config.json.template
COPY monitor.sh /usr/local/bin/monitor.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /usr/local/bin/monitor.sh /entrypoint.sh && \
    cp /etc/xray/config.json.template /etc/xray/config.json

CMD ["/entrypoint.sh"]
