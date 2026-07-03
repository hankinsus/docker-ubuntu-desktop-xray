#!/bin/bash
CONFIG_FILE="/etc/xray/config.json"
TEMPLATE="/etc/xray/config.json.template"
SUB_URL="https://api.v1.mk/sub?target=v2ray&url=https://raw.githubusercontent.com/freefq/free/master/v2"

update_node() {
    TEMP_SUB=$(mktemp)
    if curl -s -L "$SUB_URL" > "$TEMP_SUB"; then
        NEW_OUTBOUND=$(jq '.outbounds[0]' "$TEMP_SUB" 2>/dev/null)
        if [[ -n "$NEW_OUTBOUND" && "$NEW_OUTBOUND" != "null" ]]; then
            jq --argjson out "$NEW_OUTBOUND" '.outbounds = [$out]' "$TEMPLATE" > "$CONFIG_FILE"
            rm "$TEMP_SUB"
            return 0
        fi
    fi
    rm "$TEMP_SUB"
    return 1
}

# 循环检测 Xray 是否工作
while true; do
    # 测试 google 连通性，若不通则强制更新
    if ! curl -s --socks5 127.0.0.1:8080 http://www.google.com --connect-timeout 5 > /dev/null; then
        if update_node; then
            pkill xray
            sleep 2
            /usr/local/bin/xray run -c "$CONFIG_FILE" > /dev/null 2>&1 &
        fi
    fi
    sleep 60
done
