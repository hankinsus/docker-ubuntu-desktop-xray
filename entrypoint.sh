#!/bin/bash
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1 /root/.Xauthority
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &
/usr/local/bin/monitor.sh &
/usr/local/bin/xray run -c /etc/xray/config.json &
tail -f /dev/null
