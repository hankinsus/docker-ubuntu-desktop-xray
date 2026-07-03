#!/bin/bash
# 清理锁
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1

# 启动 VNC
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE

# 启动 websockify
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &

# 启动 monitor
/usr/local/bin/monitor.sh &

# 启动 Xray
/usr/local/bin/xray run -c /etc/xray/config.json &

wait
