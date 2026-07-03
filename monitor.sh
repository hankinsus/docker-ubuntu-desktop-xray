#!/bin/bash
CONFIG_FILE="/etc/xray/config.json"
TEMPLATE="/etc/xray/config.json.template"

update_node_logic() {
    # 抓取并提取包含 ss:// 的行
    RAW=$(curl -s "https://raw.githubusercontent.com/freefq/free/master/v2" | grep "ss://" | head -n 1 | sed 's/ss:\/\///' | base64 -d 2>/dev/null)
    
    # 提取格式：method:password@host:port
    METHOD=$(echo "$RAW" | cut -d: -f1)
    PASSWORD=$(echo "$RAW" | cut -d: -f2 | cut -d@ -f1)
    HOST=$(echo "$RAW" | cut -d@ -f2 | cut -d: -f1)
    PORT=$(echo "$RAW" | cut -d@ -f2 | cut -d: -f2)

    if [[ -n "$HOST" && -n "$PORT" ]]; then
        echo "注入节点: $HOST:$PORT"
        jq --arg h "$HOST" --arg p "$PORT" --arg m "$METHOD" --arg ps "$PASSWORD" \
          '.outbounds[0].settings.servers[0] = {address: $h, port: ($p|tonumber), method: $m, password: $ps}' \
          "$TEMPLATE" > "$CONFIG_FILE"
        return 0
    fi
    return 1
}

while true; do
    if ! curl -s --socks5 127.0.0.1:8080 http://www.google.com --connect-timeout 5 > /dev/null; then
        if update_node_logic; then
            pkill xray
            sleep 2
            /usr/local/bin/xray run -c "$CONFIG_FILE" > /dev/null 2>&1 &
        fi
    fi
    sleep 300
done
