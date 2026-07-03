#!/bin/bash
# 1. 启动 VNC 并强制忽略安全告警
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1
vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE

# 2. 确保配置文件存在（如果不存在则从模板复制）
if [ ! -f /etc/xray/config.json ]; then
    cp /etc/xray/config.json.template /etc/xray/config.json
fi

# 3. 启动 Xray
/usr/local/bin/xray run -c /etc/xray/config.json &

# 4. 启动 websockify (增加延迟确保 VNC 已在 5901 启动)
sleep 2
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &

# 5. 启动监控脚本
/usr/local/bin/monitor.sh &

tail -f /dev/null
