FROM --platform=linux/amd64 ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    xfce4 xfce4-goodies xfce4-terminal \
    tigervnc-standalone-server novnc \
    python3-pip curl unzip wget procps \
    openvpn dante-server iproute2 iptables \
    fonts-wqy-microhei && rm -rf /var/lib/apt/lists/*

RUN pip3 install websockify
RUN wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip Xray-linux-64.zip -d /usr/local/bin/ && rm Xray-linux-64.zip && chmod +x /usr/local/bin/xray

COPY entrypoint.sh /entrypoint.sh
COPY danted.conf /etc/danted.conf
COPY config.json /etc/xray/config.json
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
