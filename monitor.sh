#!/bin/bash
CONFIG_FILE="/etc/xray/config.json"
TEMPLATE="/etc/xray/config.json.template"

update_node_logic() {
    echo "正在从源直接解析节点..."
    
    # 1. 下载原始订阅
    RAW_DATA=$(curl -s "https://raw.githubusercontent.com/freefq/free/master/v2" | base64 -d 2>/dev/null)
    
    # 2. 尝试解析第一行 ss:// 节点
    # 格式: ss://method:password@host:port
    FIRST_NODE=$(echo "$RAW_DATA" | grep "ss://" | head -n 1)
    
    if [[ -n "$FIRST_NODE" ]]; then
        # 提取参数
        STR=$(echo "$FIRST_NODE" | sed 's/ss:\/\///')
        METHOD=$(echo "$STR" | cut -d: -f1)
        PASSWORD=$(echo "$STR" | cut -d: -f2 | cut -d@ -f1)
        HOST=$(echo "$STR" | cut -d@ -f2 | cut -d: -f1)
        PORT=$(echo "$STR" | cut -d@ -f2 | cut -d: -f2)

        # 注入配置
        jq --arg h "$HOST" --arg p "$PORT" --arg m "$METHOD" --arg ps "$PASSWORD" \
          '.outbounds[0] = {protocol: "shadowsocks", settings: {servers: [{address: $h, port: ($p|tonumber), method: $m, password: $ps}]}}' \
          "$TEMPLATE" > "$CONFIG_FILE"
        return 0
    fi
    return 1
}

while true; do
    # 这里的端口测试必须通过 xray 代理进行
    if ! curl -s --socks5 127.0.0.1:8080 http://www.google.com --connect-timeout 5 > /dev/null; then
        echo "检测到连接失败，正在尝试手动切换..."
        if update_node_logic; then
            pkill xray
            sleep 2
            /usr/local/bin/xray run -c "$CONFIG_FILE" > /dev/null 2>&1 &
        fi
    fi
    sleep 300
done
