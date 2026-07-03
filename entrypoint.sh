#!/bin/bash
mkdir -p /root/.vnc && echo "password" | vncpasswd -f > /root/.vnc/passwd && chmod 600 /root/.vnc/passwd
touch /root/.Xauthority

vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &

# 1. 执行初始化
/usr/local/bin/vpn_init.sh

# 2. 等待 tun0 出现后才启动 dante
while ! ip addr show tun0 > /dev/null 2>&1; do
    echo "等待 VPN 网卡创建..."
    sleep 5
done

danted -D -f /etc/danted.conf &
/usr/local/bin/xray run -c /etc/xray/config.json &

tail -f /dev/null
