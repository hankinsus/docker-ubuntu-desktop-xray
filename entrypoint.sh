#!/bin/bash
# 修复 VNC 权限
mkdir -p /root/.vnc
echo "password" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd
touch /root/.Xauthority

# 启动环境
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &

# 自动处理配置：如果不存在 config.json，则复制模板
if [ ! -f /etc/xray/config.json ]; then
    cp /etc/xray/config.json.template /etc/xray/config.json
fi

# 启动 Xray
/usr/local/bin/xray run -c /etc/xray/config.json &

tail -f /dev/null
