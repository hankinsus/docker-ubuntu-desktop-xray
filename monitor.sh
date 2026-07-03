#!/bin/bash
CONFIG_FILE="/etc/xray/config.json"

while true; do
    # 检测 8080 是否响应
    if ! curl -s --socks5 127.0.0.1:8080 http://www.google.com > /dev/null; then
        echo "Xray connection failed, switching node..."
        
        # --- 逻辑实现区 ---
        # 1. 调用 VPNGate API 并解析 (这里应放入你的获取逻辑)
        # 2. 进行 ippure 检测，筛选最优 IP
        # 3. 使用 jq 动态写入配置:
        # jq '.outbounds[0].settings.vnext[0].address = "新IP"' $CONFIG_FILE > temp.json && mv temp.json $CONFIG_FILE
        
        # 重启服务以生效
        pkill xray
        /usr/local/bin/xray run -c $CONFIG_FILE &
    fi
    sleep 60
done
