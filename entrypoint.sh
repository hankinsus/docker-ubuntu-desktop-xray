#!/bin/bash
mkdir -p /root/.vnc && echo "password" | vncpasswd -f > /root/.vnc/passwd && chmod 600 /root/.vnc/passwd
touch /root/.Xauthority

vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &

/usr/local/bin/vpn_init.sh
danted -D -f /etc/danted.conf &
/usr/local/bin/xray run -c /etc/xray/config.json &

tail -f /dev/null
