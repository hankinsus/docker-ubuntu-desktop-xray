#!/bin/bash
# 修复权限
mkdir -p /root/.vnc
echo "password" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd
touch /root/.Xauthority

# 1. 启动 VNC & noVNC
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &

# 2. 启动 OpenVPN 隧道
openvpn --config /client.ovpn --daemon
echo "等待 OpenVPN 建立隧道..."
sleep 15 

# 3. 启动 Dante-server (将 tun0 流量转换为 Socks5)
danted -D -f /etc/danted.conf &

# 4. 启动 Xray (连接本地 1080)
/usr/local/bin/xray run -c /etc/xray/config.json &

tail -f /dev/null
