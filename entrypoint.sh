#!/bin/bash
export DISPLAY=:1
# 清理锁文件防止重启失败
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1

vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &
/usr/local/bin/xray run -c /etc/xray/config.json &
/usr/local/bin/monitor.sh &

tail -f /dev/null
