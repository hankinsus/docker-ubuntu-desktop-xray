#!/bin/bash
# 清理残留
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1

# 1. 启动 VNC (添加了强制安全忽略参数)
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE

# 2. 启动 websockify
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &

# 3. 启动 Xray
/usr/local/bin/xray run -c /etc/xray/config.json &

# 4. 启动监控脚本
/usr/local/bin/monitor.sh &

tail -f /dev/null
