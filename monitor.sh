#!/bin/bash
CONFIG_FILE="/etc/xray/config.json"

# 使用一个稳定开源的订阅转换接口，直接获取通用配置
SUB_URL="https://api.v1.mk/sub?target=v2ray&url=https://raw.githubusercontent.com/freefq/free/master/v2"

while true; do
    # 检查出口连通性 (若失败，则从订阅池更新)
    if ! curl -s --socks5 127.0.0.1:8080 http://www.google.com --connect-timeout 5 > /dev/null; then
        echo "节点失效，正在同步订阅池..."
        
        # 使用临时文件防止配置损坏
        if curl -s -L "$SUB_URL" > "${CONFIG_FILE}.new"; then
            if jq empty "${CONFIG_FILE}.new" >/dev/null 2>&1; then
                mv "${CONFIG_FILE}.new" "$CONFIG_FILE"
                pkill xray
                /usr/local/bin/xray run -c "$CONFIG_FILE" > /dev/null 2>&1 &
                echo "节点已自动更新。"
            fi
        fi
    fi
    sleep 600 # 每10分钟检测一次
done
