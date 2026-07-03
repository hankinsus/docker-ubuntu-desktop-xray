#!/bin/bash
# 环境修复
mkdir -p /root/.vnc
echo "password" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd
touch /root/.Xauthority

# 启动环境
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &

# 初始化配置
cp /etc/xray/config.json.template /etc/xray/config.json
/usr/local/bin/monitor.sh &
/usr/local/bin/xray run -c /etc/xray/config.json &

tail -f /dev/null
